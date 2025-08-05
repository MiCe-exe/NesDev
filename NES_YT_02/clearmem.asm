.include "consts.inc"
.include "header.inc"
.include "reset.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRG-ROm code located at $8000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CODE"
; Todo: add code of PRG-ROM

Reset:

Main:
    ldx #$3f
    stx PPU_ADDR
    ldx #$00
    stx PPU_ADDR

    lda #$2A
    sta PPU_DATA

    lda #%00011110
    sta PPU_MASK

LoopForever:
    jmp LoopForever
NMI:
    rti
IRQ:
    rti

.segment "VECTORS"
.word NMI
.word Reset
.word IRQ