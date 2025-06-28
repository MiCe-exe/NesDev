; CH05 - Programming Games for NES
; Base NES game shell demo

; *****************************************************
; Define NES control register values
; *****************************************************

; Define PPU Registers
PPU_CONTROL = $2000
PPU_MASK    = $2001
PPU_STATUS = $2002
PPU_SPRRAM_ADDRESS = $2003
PPU_SPRRAM_IO = $2004
PPU_VRAM_ADDRESS1 = $2005
PPU_VRAM_ADDRESS2 = $2006
PPU_VRAM_IO = $2007
SPRITE_DMA = $4014

; Define APU Registers
APU_DM_CONTROL = $4010
APU_CLOCK = $4015

; Joystick\Controller values
JOYPAD1 = $4016
JOYPAD2 = $4017

; Gamepad bit values
PAD_A = $01
PAD_B = $02
PAD_SELECT = $04
PAD_START = $08
PAD_U = $10
PAD_D = $20
PAD_L = $40
PAD_R = $80

;****************************************************************
; Define NES cartridge Header
;****************************************************************

.segment "HEADER"
INES_MAPPER = 0     ; 0 = NROM
INES_MIRROR = 0     ; 0 = Horizontal mirroring, 1 = vertical mirroring
INES_SRAM = 0       ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID
.byte $02   ; 16k PRG bank count
.byte $01   ; 8k CHR bank count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0    ; padding

;****************************************************************
; Import both the background and sprite character sets
;****************************************************************

.segment "TILES"
.incbin "example.chr"

;*****************************************************************
; Define NES interrupt vectors
;*****************************************************************

.segment "VECTORS"
.word nmi
.word reset
.word irq

;************************************
; 6502 Zero Page Memory (256 bytes)
;************************************

.segment "ZEROPAGE"

nmi_ready:      .res 1  ; Set to 1 to push a PPU frame update,
                            ; 2 to turn rendering off next NMI
gamepad:        .res 1  ; stores the current gamepad values

d_x:            .res 1  ; x velocity of ball
d_y:            .res 1  ; y velocity of ball

;***********************************
; Sprite OAM Data area - coped to VRAM in NMI routine
;***********************************

.segment "OAM"
oam: .res 256   ; sprite OAM data

;****************************************************************
; Remainder of normal RAM area
;****************************************************************

.segment "BSS"
palette: .res 32 ; current palette buffer

;****************************************************************
; Some useful functions
;****************************************************************

.segment "CODE"
; ppu_update:waits until next NMI and turns rendering on (if not already)
.proc ppu_update
    lda #1
    sta nmi_ready
    loop:
        lda nmi_ready
        bne loop
    rts
.endproc

; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_VRAM_IO) * missing
.proc ppu_off
    lda #2
    sta nmi_ready
    loop:
            lda nmi_ready
            bne loop
        rts
.endproc

;****************************************************************
; Main application entry point for startup/reset
;****************************************************************

.segment "CODE"
.proc reset
    sei                 ; mask interrupts
    lda #0                                      ; DEL: $0 -> #0
    sta PPU_CONTROL     ; disable NMI
    sta PPU_MASK        ; disable rendering
    sta APU_DM_CONTROL
    lda #$40
    sta JOYPAD2         ; disable APU frame IRQ

    cld                 ; disable decimal mode
    ldx #$FF
    txs                 ; initialise stack

    ; wait for first bBlank
    bit PPU_STATUS
wait_vblank:
    bit PPU_STATUS
    bpl wait_vblank

    ; Clear all ram to 0
    lda #0
    ldx #0
clear_ram:
    sta $0000,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne clear_ram

    ;Placing sprites offscreen
    lda #255
    ldx #0
clear_oam:
    sta oam,x
    inx
    inx
    inx
    inx
    bne clear_oam

; wait for second vBlank
wait_vblank2:
    bit PPU_STATUS
    bpl wait_vblank2

    ; NES is initialized and ready to begin
    ; - enable the NMI for graphical updates and jump to our maiin program
    lda #%10001000
    sta PPU_CONTROL
    jmp main
.endproc

;*****************************************************************
; NMI Routine - called every vBlank
;*****************************************************************

.segment "CODE"
.proc nmi
        ;save registers
        pha
        txa
        pha
        tya
        pha

        lda nmi_ready
        bne :+          ; nmi_ready == 0 not ready to update PPU
            jmp ppu_update_end
        :
        cmp #2                  ;nmi_ready == 2 turns rendering off
        bne cont_render
            lda #%00000000
            sta PPU_MASK
            ldx #0
            stx nmi_ready
            jmp ppu_update_end
        cont_render:

            ; transfer sprites OAM data using DMA
            ldx #0
            stx PPU_SPRRAM_ADDRESS
            lda #>oam
            sta SPRITE_DMA
            
            ; transfer current palette to PPU
            lda #%10001000          ; set horizontal nametable increment
            sta PPU_CONTROL
            lda PPU_STATUS
            lda #$3F                ; set PPU address to $3F00
            sta PPU_VRAM_ADDRESS2
            stx PPU_VRAM_ADDRESS2
            ldx #0                  ; tansfer the 32 bytes to VRAM
        loop:
            lda palette, x
            sta PPU_VRAM_IO
            inx
            cpx #32
            bcc loop

            ; enale rendering
            lda #%00011110
            sta PPU_MASK
            ; fkag PPU update complete
            ldx #0
            stx nmi_ready
        ppu_update_end:

            ; restore registers and return
            pla
            tay
            pla
            tax
            pla
            rti
.endproc

;****************************************************************
; IRQ Clock Interrupt Routine
;****************************************************************

.segment "CODE"
irq:
    rti

;*****************************************************************
; Main application logic section includes the game loop
;*****************************************************************
.segment "CODE"
.proc main
    ; main application - rendering is currently off

    ; initialize palette table
    ldx #0
paletteloop:
    lda default_palette, x
    sta palette, x
    inx
    cpx #32
    bcc paletteloop

    ; Clearing the name table
    jsr clear_nametable

    ; draw same text on the screen
    lda PPU_STATUS
    lda #$20
    sta PPU_VRAM_ADDRESS2
    lda #$8A
    sta PPU_VRAM_ADDRESS2

    ldx #0
textloop:
    lda welcome_txt, x
    sta PPU_VRAM_IO
    inx
    cmp #0
    beq :+
    jmp textloop
    :

    ; Placing bat sprite on screen
    lda #180
    sta oam     ; set Y
    lda #120
    sta oam + 3 ; set X
    lda #1
    sta oam + 1 ; set pattern
    lda #0
    sta oam + 2 ; set attributes
    ; Placing a ball sprite on the screen
    lda #124
    sta oam + (1 * 4)       ; Set Y
    sta oam + (1 * 4) + 3   ; set X
    lda #2
    sta oam + (1 * 4) + 1   ; set patter + (1 * 4)n
    lda #0
    sta oam + (1 * 4) + 2   ; set attributes
    ; Setting ball initial velocity
    lda #1
    sta d_x
    sta d_y

    ; Getting the screen to render
    jsr ppu_update

mainloop:
; skip reading CONTROLS if and change has not been drawn
    lda nmi_ready
    cmp #0
    bne mainloop
    ; Reading the gamepad and moving the bat
    jsr gamepad_poll
    ; now move the bat if left or right pressed
    lda gamepad
    and #PAD_L
    beq NOT_GAMEPAD_LEFT
        ; gamepad has been pressed left
        lda oam + 3     ;get current X
        cmp #0
        beq NOT_GAMEPAD_LEFT
        sec
        sbc #1
        sta oam + 3     ; change X to the left
    NOT_GAMEPAD_LEFT:
        lda gamepad
        and #PAD_R
        beq NOT_GAMEPAD_RIGHT
            ; gamepad has been pressed right
            lda oam + 3 ; get current X
            cmp #248
            beq NOT_GAMEPAD_RIGHT
            clc
            adc #1
            sta oam + 3 ; change X to the left
    NOT_GAMEPAD_RIGHT:
        ; moving our ball
        lda oam + (1 * 4) + 0       ; #2 Get the current Y
        clc
        adc d_y                     ; #3 Adds the Y velocity
        sta oam + (1 * 4) + 0       ; #4 Writes the change
        cmp #0                      ; #5 Have we hit the top border?
        bne NOT_HITTOP
            lda #1                  ; #6 Reverses direction
            sta d_y
    NOT_HITTOP:
        lda oam + (1 * 4) + 0
        cmp #210                ; #7 Have we hit the bottom border?
        bne NOT_HITBOTTOM
            lda #$FF            ; #8 Reverse direction (-1)
            sta d_y
    NOT_HITBOTTOM:
        lda oam + (1 * 4) + 3   ; #9 Gets the current X
        clc
        adc d_x                 ; #10 Adds the X velocity
        sta oam + (1 * 4) + 3
        cmp #0                  ; #11 Have we hit the left border?
        bne NOT_HITLEFT
            lda #1              ; #12 Reverse direction
            sta d_x
    NOT_HITLEFT:
        lda oam + (1 * 4) + 3
        cmp #248                ; #13 Have we hit the right border?
        bne NOT_HITRIGHT
            lda #$FF            ; #14 Reverses direction (-1)
            sta d_x
    NOT_HITRIGHT:

        ; ensure our chages are rendered
        lda #1
        sta nmi_ready
        jmp mainloop
.endproc

.segment "CODE"
.proc clear_nametable
    lda PPU_STATUS          ; reset address latch
    lda #$20                ; set PPU address to $2000
    sta PPU_VRAM_ADDRESS2
    lda #$00
    sta PPU_VRAM_ADDRESS2

    ; empty nametable
    lda #0
    ldy #30
    rowloop:
        ldx #32     ;32 columns
        columnloop:
            sta PPU_VRAM_IO
            dex
            bne columnloop
        dey
        bne rowloop

    ; empty attribute table
    ldx #64
    loop:
        sta PPU_VRAM_IO
        dex
        bne loop
    rts
.endproc

;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labeled 
; "gamepad".
; labeled "gamepad".
; ****************************************************************

.segment "CODE"
.proc gamepad_poll
    ; strobe the gamepad to latch current button state
    lda #1 
    sta JOYPAD1
    lda #0
    sta JOYPAD1
    ; read 8 bytes from the interface at $4016 
    ldx #8
loop:
    pha
    lda JOYPAD1
    ; combinw low two bits and store in carry hit
    and #%00000011
    cmp #%00000001
    pla
    ; roatte carry into gamepad variable
    ror
    dex
    bne loop
    sta gamepad
    rts
.endproc

;*****************************************************************
; Our default palette table has 16 entries for tiles and 16 entries for sprites
;*****************************************************************
 
.segment "RODATA"
default_palette:
.byte $0F,$15,$26,$37   ; bg0 purple\pink
.byte $0F,$09,$19,$29   ; bg1 green 
.byte $0F,$01,$11,$21   ; bg2 blue 
.byte $0F,$00,$10,$30   ; bg3 greyscale
.byte $0F,$18,$28,$38   ; sp0 yellow
.byte $0F,$14,$24,$34   ; sp1 purple
.byte $0F,$1B,$2B,$3B   ; sp2 teal
.byte $0F,$12,$22,$32   ; sp3 marine

welcome_txt:
.byte 'W','E','L','C', 'O', 'M', 'E', 0