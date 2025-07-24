.segment "HEADER"
.org $7ff0
.byte $4E,$45,$53,$1A,$02,@01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

.segment "CODE"
.org $8000

Reset:
; TODO:
; Load the A register with the literal hexdecimal value $82
lda #$82
; Load the X register with the literal decimal value 82
ldx #82
; Load the Y rgister with the value that is inside memory position $82
ldy $82

NMI:
    rti         ; Return from Interrupt

IRQ:
    rti         ; Return from Interrupt

.segment "VECTORS"
.org $FFFA
.word NMI       ; Address (2bytes) of the NMI handler
.word Reset     ; Address (2 bytes) of the Reset handler
.word IRQ       ; Adress (2 bytes) of the IRQ handler
