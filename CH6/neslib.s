;***************************************************************
; neslib.s: NES function Library
;***************************************************************

; Define PPU Registers
PPU_CONTROL = $2000             ; ppu CONTROL REGISTER 1 (WRITE)
PPU_MASK = $2001                ; PPU control register 2 (write)
PPU_STATUS = $2002              ; PPU status register (read)
PPU_SPRRAM_ADDRESS = $2003      ; PPU SPR-RAM address register (write)
PPU_SPRRAM_IO = $2004           ; PPU SPR-RAM I/O register (write)
PPU_VRAM_ADDRESS1 = $2005        ; PPU VRAM address register 1 (Write)
PPU_VRAM_ADDRESS2 = $2006        ; PPU VRAM adress register 2 (write)
PPU_VRAM_IO = $2007             ; VRAM I/O register (read/write)
SPRITE_DMA = $4014              ; Sprite DMA   register

NT_2000 = $00                   ; Name table location
NT_2400 = $01
NT_2800 = $02
NT_2C00 = $03

VRAM_DOWN = $04                 ; Incrememnts the VRAM poitner by row

OBJ_0000 = $00
OBJ_1000 = $08
OBJ_8X16 = $20

BG_0000 = $00;
BG_1000 = $10

VBLANK_NMI = $80                ; Enables NMI

BG_OFF = $00                    ; Turns the background off
BG_CLIP = $08                   ; Clips the background 
BG_ON = $0A                     ; Turns the background on

OBJ_OFF = $00                   ; Turns the objects off
OBJ_CLIP = $10                  ; Clips the objects
OBJ_ON = $14                    ; Turns the objects on

APU_DM_CONTROL = $4010          ; APU delta modulation control register (write)
APU_CLOCK = $4015               ; APU sound/vertical clock signal register (read/write)

; Joystick/Controller values
JOYPAD1 = $4016                 ; Joypad 1 (read/write)
JOYPAD2 = $4017                 ; Joypad 2 (read/write)

; Gamepad Bit values
PAD_A       = $01
PAD_B       = $02
PAD_SELECT  = $04
PAD_START   = $08
PAD_U       = $10
PAD_D       = $20
PAD_L       = $40
PAD_R       = $80
; Useful PPU memory addresses
NAME_TABLE_0_ADDRESS        = $2000
ATTRIBUTE_TABLE_0_ADDRESS   = $23C0
NAME_TABLE_1_ADDRESS        = $2400
ATTRIBUTE_TABLE_1_ADDRESS   = $27C0

.segment "ZEROPAGE"

nmi_ready:          .res 1      ; Sets to 1 to push a PPU frame update, 
                                ; 2 to turn rendering off next NMI
ppu_ctl0:            .res 1      ; PPU control register 1 value
ppu_ctl1:            .res 1      ; PPU control register 2 value

.include "macros.s"

;*****************************************************************
; wait_frame: waits until the next NMI occurs
;*****************************************************************
.segment "CODE"

.proc wait_frame
    inc nmi_ready
@loop:
    lda nmi_ready
    bne @loop
    rts
.endproc

;*****************************************************************
; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
;*****************************************************************
.segment "CODE"
.proc ppu_update
    lda ppu_ctl0
    ora #VBLANK_NMI
    sta ppu_ctl0
    sta PPU_CONTROL
    lda ppu_ctl1
    ora #OBJ_ON|BG_ON
    sta ppu_ctl1
    jsr wait_frame
    rts
.endproc

;*****************************************************************
; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_VRAM_IO)
;*****************************************************************
.segment "CODE"
.proc ppu_off
    jsr wait_frame
    lda ppu_ctl0
    and #%01111111
    sta ppu_ctl0
    sta PPU_CONTROL
    lda ppu_ctl1
    and #%11100001
    sta ppu_ctl1
    sta PPU_MASK
    rts
.endproc

.segment "CODE"
.proc clear_nametable

    lda PPU_STATUS          ; Resets the address latch
    lda #$20                ; Sets the ppu address to $2000
    sta PPU_VRAM_ADDRESS2
    lda #$00
    sta PPU_VRAM_ADDRESS2


    lda #0                  ; Empties the name table
    ldy #30                 ; Clears  30 rows
    rowloop:
        ldx #32             ; 32 colummns 
        columnloop:
            sta PPU_VRAM_IO
            dex
            bne columnloop
        dey
        bne rowloop

                            ; Empties the attribute table
    ldx #64                 ; The attribute table is 64 bytes
    loop:
        sta PPU_VRAM_IO
        dex
        bne loop
    rts
.endproc

.segment "ZEROPAGE"

gamepad:        .res 1      ; Stores the current gamepad value

.segment "CODE"
.proc gamepad_poll          ; Strobes the gamepad to latch the current buttom state
    lda #1
    sta JOYPAD1
    lda#0
    sta JOYPAD1             ; reads 8 bytes from the interface at $4016
    ldx #8
loop:
    pha
    lda JOYPAD1             ; Combines low 2 bits and stores them in the carry bit
    and #%00000011
    cmp #%00000001
    pla                     ; Rotates the carry into the gamepad variable
    ror
    dex
    bne loop
    sta gamepad
    rts
.endproc

; ******************************************
; Writes text to screen
; ******************************************
.segment "ZEROPAGE"

text_address:       .res 2      ; Sets to the address of the text to write

.segment "CODE"
.proc write_text
    ldy #0
loop:
    lda (text_address),y        ; Gets the byte at the current source address
    beq exit                    ; Exists when we encounter a zero in the text
    sta PPU_VRAM_IO             ; Writes the byte to video memory
    iny
    jmp loop
exit:
    rts
.endproc