;*****************************************************************
; Define NES cartridge Header
;*****************************************************************

.segment "HEADER"
INES_MAPPER = 0                         ; 0 = NROM
INES_MIRROR = 0                         ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0                         ; 1 = battery-backed sram at $6000-7FFF

.byte 'N', 'E', 'S', $1A                ; ID
.byte $02                               ; 16k PRG bank count
.byte $01                               ; 8K CHR bank count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0    ; Padding

;*****************************************************************
; Import both the background and sprite character sets
;*****************************************************************

.segment "TILES"
.incbin "megablast.chr"

;*****************************************************************
; Define NES interrupt vectors
;*****************************************************************

.segment "VECTORS"
.word nmi
.word reset
.word irq

;*****************************************************************
; 6502 Zero Page Memory (256 bytes)
;*****************************************************************
.segment "ZEROPAGE"

;*****************************************************************
; Sprite OAM Data area - copied to VRAM in NMI routine
;*****************************************************************

.segment "OAM"
oam: .res 256           ; Sprite OAM data

;*****************************************************************
; Include NES Function Library
;*****************************************************************

.include "neslib.s"     ; Includes the contents of the neslib.s

;*****************************************************************
; Remainder of normal RAM area
;*****************************************************************

.segment "BSS"
palette: .res 32        ; Current palette buffer


; ***************************************************************
; Main application entry point for startup/reset
; ***************************************************************

.segment "CODE"
.proc reset
    sei                 ; Masks interrupts
    lda #0
    sta PPU_CONTROL     ; Disables NMI
    sta PPU_MASK        ; Disanles rendering
    sta APU_DM_CONTROL
    lda #$40
    sta JOYPAD2         ; Disables APU frame IRQ

    cld                 ; Disables decimal mode
    ldx #$FF
    txs                 ; Initializes the stack

    bit PPU_STATUS      ; Waitis for the first vBlank
wait_vblank:
    bit PPU_STATUS
    bpl wait_vblank

    lda #0              ; Clears RAM to 0
    ldx #0
clear_ram:
    sta $0000,x
    sta $0100,x
    sta $0200,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne clear_ram

    lda #255            ; Places all sprites offscreen at Y = 255
    ldx #0
clear_oam:
    sta oam,x
    inx
    inx
    inx
    inx
    bne clear_oam

wait_vblank2:           ; Waits for the second vBlank
    bit PPU_STATUS
    bpl wait_vblank2

                        ; NES is initialized and ready to begin
    
    lda #%10001000      ; Enables the NMI for graphical updates and jumps to our main program
    sta PPU_CONTROL
    jmp main
.endproc

.segment "CODE"
.proc nmi
    pha                 ; Saves registers
    txa
    pha
    tya
    pha

    bit PPU_STATUS
    lda #>oam           ; Transfers sprite OAM data using DMA
    sta SPRITE_DMA

    vram_set_address $3F00  ; Sets the PPU address to $3F00
    ldx #0
@loop:
    lda palette, x
    sta PPU_VRAM_IO
    inx
    cpx #32
    bcc @loop

    lda #0
    sta PPU_VRAM_ADDRESS1
    sta PPU_VRAM_ADDRESS1
    lda ppu_ctl0
    sta PPU_CONTROL
    lda ppu_ctl1
    sta PPU_MASK

    ; flag PPU update complete
    lda #0 
    stx nmi_ready

    pla                     ; Restores registers and returns
    tay
    pla
    tax
    pla
    rti
.endproc

;*****************************************************************
; IRQ Clock Interrupt Routine
;*****************************************************************

.segment "CODE"
irq:
    rti

;*****************************************************************
; Main application logic section includes the game loop
;*****************************************************************

.segment "CODE"
.proc main
        
    ldx #0      ; Initializes the palette table
paletteloop:
    lda default_palette, x
    sta palette, x
    inx
    cpx #32
    bcc paletteloop

    jsr display_title_screen            ; Adds the code to draw the screen

    lda #VBLANK_NMI|BG_0000|OBJ_1000    ; Sets game settings
    sta ppu_ctl0
    lda #BG_ON|OBJ_ON
    sta ppu_ctl1

    jsr ppu_update

titleloop:
    jsr gamepad_poll
    lda gamepad
    and #PAD_A|PAD_B|PAD_START|PAD_SELECT
    beq titleloop

    jsr display_game_screen

mainloop:
    jmp mainloop
.endproc

; ****************************************************************
; Dispaly title screen 
; ****************************************************************

.segment "ZEROPAGE"

paddr: .res 2                                               ; 16-bit address pointer

.segment "CODE"

title_text:
.byte "M E G A  B L A S T",0

press_play_text:
.byte "PRESS FIRE TO BEGIN",0

title_attributes:
.byte %00000101,%00000101,%00000101,%00000101
.byte %00000101,%00000101,%00000101,%00000101

.proc display_title_screen
    jsr ppu_off                                             ; Waits for the screen to be drawn and then turn off

    jsr clear_nametable                                     ; Clears the first name table

	; Write our title text
	vram_set_address (NAME_TABLE_0_ADDRESS + 4 * 32 + 6)
	assign_16i text_address, title_text
	jsr write_text

    vram_set_address (NAME_TABLE_0_ADDRESS + 20 * 32 + 6)   ; Writes our press play text
    assign_16i text_address, press_play_text
    jsr write_text

    vram_set_address (ATTRIBUTE_TABLE_0_ADDRESS + 8)        ; Sets the title to use the second palette table
    assign_16i paddr, title_attributes
    ldy #0
loop:
    lda (paddr),y
    sta PPU_VRAM_IO
    iny
    cpy #8
    bne loop

    jsr ppu_update                                          ; Waits until the screen has been drawn

    rts
.endproc

; ****************************************************************
; Display Main Game Screen
; ****************************************************************

.segment "RODATA"
; Put the data in our data segment of the ROM
game_screen_mountain:
.byte 001,002,003,004,001,002,003,004,001,002,003,004,001,002,003,004
.byte 001,002,003,004,001,002,003,004,001,002,003,004,001,002,003,004
game_screen_scoreline:
.byte "SCORE 0000000"

.segment "CODE"
.proc display_game_screen
    jsr ppu_off             ; Wait for the screen to be drawn and then turn off drawing

    jsr clear_nametable     ; Clear the 1st name table

    ; output mountian line
    vram_set_address (NAME_TABLE_0_ADDRESS + 22 * 32)
    assign_16i paddr, game_screen_mountain
    ldy #0
loop:
    lda (paddr),y
    sta PPU_VRAM_IO
    iny
    cpy #32
    bne loop

    ; draw a base line
    vram_set_address (NAME_TABLE_0_ADDRESS + 26 *32)
    ldy #0
    lda #9              ; tile number to repeat
loop2:
    sta PPU_VRAM_IO
    iny
    cpy #32
    bne loop2

    ;output the score section on the next line
    assign_16i paddr, game_screen_scoreline
    ldy #0
loop3:
    lda (paddr),y
    sta PPU_VRAM_IO
    iny 
    cpy #12
    bne loop3

    jsr ppu_update  ; wait until the screen has been drawn
    rts
.endproc


;*****************************************************************
; Our default palette table has 16 entries for tiles and 16 entries for sprites
;*****************************************************************

.segment "RODATA"
default_palette:
.byte $0F,$15,$26,$37 ; bg0 purple/pink
.byte $0F,$19,$29,$39 ; bg1 green
.byte $0F,$11,$21,$31 ; bg2 blue
.byte $0F,$00,$10,$30 ; bg3 greyscale
.byte $0F,$28,$21,$11 ; sp0 player
.byte $0F,$14,$24,$34 ; sp1 purple
.byte $0F,$1B,$2B,$3B ; sp2 teal
.byte $0F,$12,$22,$32 ; sp3 marine