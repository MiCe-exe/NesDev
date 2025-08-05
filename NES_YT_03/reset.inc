.macro INIT_NES
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
.endmacro