%ifndef PRIMARY_INC
%define PRIMARY_INC

; Primary data register for the disk controller (16-bit, others are 8-bit).
PRIMARY_SECTOR_DATA equ 0x1F0

; Register holding the remaining sector count.
PRIMARY_SECTOR_COUNT equ 0x1F2

; Register holding LBA28 bits 7..0.
PRIMARY_LBA_LOW equ 0x1F3

; Register holding LBA28 bits 15..8.
PRIMARY_LBA_MID equ 0x1F4

; Register holding LBA28 bits 23..16.
PRIMARY_LBA_HIGH equ 0x1F5

; Register for LBA mode selection and drive selection.
; NOTE: Low 4 bits store LBA28 bits 27..24.
; NOTE: High 4 bits: bit7=1, bit6=1 for LBA (0 for CHS), bit5=1, bit4=1 slave (0 master).
PRIMARY_DEVICE equ 0x1F6

; Command register for disk operations.
; NOTE: Common commands: 0xEC (identify), 0x20 (read), 0x30 (write).
PRIMARY_COMMAND equ 0x1F7

; Status register for disk operations.
; NOTE: Bit0 ERR=1 indicates command error.
; NOTE: Bit3 DRQ=1 indicates data ready to read.
; NOTE: Bit6 DRDY=1 indicates drive ready.
; NOTE: Bit7 BSY=1 indicates busy and other bits are invalid.
PRIMARY_STATUS equ 0x1F7

%endif