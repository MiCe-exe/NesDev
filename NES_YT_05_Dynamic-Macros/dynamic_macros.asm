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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Suboutine to load 255 tiles in the first nametable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadBackground
    ldy #0
LoopBackground:
    lda BackgroundData,y       ; Lookup byte in ROM
    sta PPU_DATA            ; Set calue ti sebd to PPU_DATA
    iny                     ; Y++
    cpy #255                 ; Is Y equal to 32
    bne LoopBackground         ; Not Yet, Keep looping
    rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to load 16 bytes of attributes for the first nametable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc LoadAttributes
    ldy #0                  ; Y = 0
:
    lda AttributeData,y     ; Lookup byte in ROM
    sta PPU_DATA            ; Set value to send to PPU_DATA
    iny                     ; Y++
    cpy #16                 ; Is Y equal to 16?
    bne :-                  ; Not yet, keep looping
    rts                     ; Return from subroutine
.endproc

Reset:
    INIT_NES

Main:
    bit PPU_STATUS
    ldx #$3f
    stx PPU_ADDR
    ldx #$00
    stx PPU_ADDR

    jsr LoadPalette         ; Jump to subroutine LoadPalette

    ;; TODO: Set PPU address to $2000 and load the tiles of the BG...
    bit PPU_STATUS
    ldx #$20
    stx PPU_ADDR
    ldx #$00
    stx PPU_ADDR
    jsr LoadBackground

    bit PPU_STATUS      ; Read PPU_STATUS to reset the PPU_ADDR latch
    ldx #$23            ;
    stx PPU_ADDR        ; Set Hi-byte of the PPU_ADDR to $23
    ldx #$C0            ;
    stx PPU_ADDR        ; Set lo-byte of PPU_ADDR to $C0
    jsr LoadAttributes  ; Jumo to subroutine LoadAttrubutes

EnablePPURendering:
    lda #%10010000          ; Enable NMI and set background to use the 2nd pattern table (at $1000)
    sta PPU_CTRL
    lda #%00011110
    sta PPU_MASK

LoopForever:
    jmp LoopForever     ;forever loop to keep the game going
NMI:
    rti
IRQ:
    rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Harcoded list of color values in ROM to be loaded by the PPU
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PaletteData:
;.byte $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A, $0F,$2A,$0C,$3A ; Background
;.byte $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26, $0F,$10,$00,$26 ; Sprites
.byte $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F    ; Background palette
.byte $22,$16,$27,$1B, $22,$1A,$30,$27, $22,$16,$30,$27, $22,$0F,$36,$17    ; Sprite Palette

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Background data that must be copied to the nametable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BackgroundData:
.byte $24,$24,$24,$24,$24,$24,$24,$24,$24,$36,$37,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
.byte $24,$24,$24,$24,$24,$24,$24,$24,$35,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$60,$61,$62,$63,$24,$24,$24,$24
.byte $24,$36,$37,$24,$24,$24,$24,$24,$39,$3a,$3b,$3c,$24,$24,$24,$24,$53,$54,$24,$24,$24,$24,$24,$24,$64,$65,$66,$67,$24,$24,$24,$24
.byte $35,$25,$25,$38,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24,$24,$24,$24,$24,$68,$69,$26,$6a,$24,$24,$24,$24
.byte $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
.byte $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
.byte $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Attribute data that is used for 4x4 sections of the background
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AttributeData:
.byte %00000000, %00000000, %10101010, %00000000, %11110000, %00000000, %00000000, %00000000
.byte %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Here we have added the CHR-ROM data, included from an 
;; external .CHR file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "CHARS"
.incbin "mario.chr"

.segment "VECTORS"
.word NMI
.word Reset
.word IRQ