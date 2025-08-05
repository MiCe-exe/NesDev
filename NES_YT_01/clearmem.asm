;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constants for PPU register mapped from addresses $200 to $2007
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PPU_CTRL        = $2000
PPU_MASK        = $2001
PPU_STATUS      = $2002
OAM_ADDR        = $2003
OAM_DATA        = $2004
PPU_SCROLL      = $2005
PPU_ADDR        = $2006
PPU_DATA        = $2007
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The iNES header (contains a total of 16 bytes with the flags at $7ff0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.segment "HEADER"
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
; Todo: add code of PRG-ROM

Reset:
    sei                     ; Disable all IRQ interrupts
    cld                     ; Clear the decimal mode (unsupported by the nes)
    ldx #$FF
    txs                     ; initialize the stack pointer at $01FF

    inx                     ; Increment X, causing a rolloff from $FF to $00
    ldx #$0
    stx PPU_CTRL            ; DIsable NMI
    stx PPU_MASK            ; Disable rendering (masking background and sprites)
    stx $4010               ; disable DMC IRQs

    lda #$40
    sta $4017               ; Disabele APU frame IRQ

Wait1stVBlank:              ; Wait for the first VBlank from PPU
    bit PPU_STATUS          ; Perform a bit-wise check with the PPU_STATUS port
    bpl Wait1stVBlank       ; Loop until bit-7 (sign bit) is 1 (inside VBlank)

    txa
ClearRAM:
    sta $0000,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne ClearRAM

Wait2ndVBlank:              ; Wait for the first VBlank from PPU
    bit PPU_STATUS          ; Perform a bit-wise check with the PPU_STATUS port
    bpl Wait2ndVBlank       ; Loop until bit-7 (sign bit) is 1 (inside VBlank)

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