;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The iNES header (contains a total of 16 bytes with the flags at $7ff0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "HEADER"
;.org $7ff0
.byte $4E,$45,$53,$1A       ; 4 bytes with the characters 'N' 'E' 'S'
.byte $02                   ; How many 16KB we'll have  use (=32KB)
.byte $01                   ; How many 8KB of CHR-ROM we'll use (=8KB)
.byte %00000000             ; Horz mirroring, no battery, mapper 0
.byte %00000000             ; mapper 0, playchoice, NES 2.0 
.byte $00                   ; No PRG-RAM
.byte $00                   ; NTSC TV format
.byte $00                   ; NO PRG-FOrmat
.byte $00,$00,$00,$00,$00   ; unused padding to complete 16 bytes of header

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRG-ROm code located at $8000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CODE"
.org $8000
; Todo: add code of PRG-ROM

Reset:
    sei                     ; Disable all IRQ interrupts
    cld                     ; Clear the decimal mode (unsupported by the nes)
    ldx #$FF
    txs                     ; initialize the stack pointer at $01FF

    lda #$0                 ; A = 0
    ldx #$0                 ; X = 0
MemLoop:
    sta $0,x                ; Store the value of A (zero) into $0+x
    dex                     ; X--
    bne MemLoop             ; IF X is not zero, we loop back to the MemLoop label

NMI:
    rti
IRQ:
    rti


.segment "VECTORS"
.org $FFFA
.word NMI
.word RESET
.word IRQ