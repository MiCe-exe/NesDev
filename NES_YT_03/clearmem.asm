.include "consts.inc"
.include "header.inc"
.include "reset.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRG-ROm code located at $8000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CODE"

.proc LoadPalette
    ldy #0
LoopPalette:
    lda PaletteData,y       ; Lookup byte in ROM
    sta PPU_DATA            ; Set calue ti sebd to PPU_DATA
    iny                     ; Y++
    cpy #32                 ; Is Y equal to 32
    bne LoopPalette         ; Not Yet, Keep looping
    rts
.endproc

Reset:

Main:
    bit PPU_STATUS
    ldx #$3f
    stx PPU_ADDR
    ldx #$00
    stx PPU_ADDR

    jsr LoadPalette         ; Jump to subroutine LoadPalette

    lda #%00011110
    sta PPU_MASK

LoopForever:
    jmp LoopForever     ;forever loop to keep the game going
NMI:
    rti
IRQ:
    rti

PaletteData:
.byte $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A ; Background
.byte $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26 ; Sprites

.segment "VECTORS"
.word NMI
.word Reset
.word IRQ