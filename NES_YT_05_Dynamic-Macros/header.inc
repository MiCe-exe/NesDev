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
