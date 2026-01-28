%include "include/system/primary.inc"

[bits 16]
section .text vstart=0x7c00
    ; ---------- Initialize registers. ----------
    mov ax, 0
    mov cx, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov sp, 0x7c00

    ; ---------- Clear the screen via BIOS interrupt. ----------
    mov ah, 0x06    ; Scroll up function.
    mov al, 0x00    ; Number of lines to scroll, 0 means all.
    mov bh, 0x07    ; Attribute for blank lines.

    ; Top-left corner is (0, 0).
    mov ch, 0
    mov cl, 0

    ; Bottom-right corner is (80, 25).
    mov dh, 24
    mov dl, 79

    ; Invoke BIOS interrupt.
    int 0x10

    ; ---------- Load the loader into memory. ----------
    mov eax, 0x01   ; LBA sector number of the loader.

    mov dx, PRIMARY_LBA_LOW
    out dx, al
    
    mov dx, PRIMARY_LBA_MID
    shr eax, 8
    out dx, al

    mov dx, PRIMARY_LBA_HIGH
    shr eax, 8
    out dx, al

    mov dx, PRIMARY_DEVICE
    shr eax, 8
    and al, 00001111b   ; Write bits 27..24 into the device register low bits.
    or al, 11100000b    ; Select master drive and LBA mode.
    out dx, al

    ; Issue the read command to the drive.
    mov dx, PRIMARY_COMMAND
    mov al, 0x20    ; Read sector command.
    out dx, al

    ; Poll drive status.
    mov dx, PRIMARY_STATUS
    .not_ready:
        nop ; NOTE: Busy-wait to consume a cycle.

        in al, dx
        and al, 10001000b   ; Keep BSY and DRQ bits.
        cmp al, 00001000b   ; Ready when BSY=0 and DRQ=1.
        jnz .not_ready      ; Wait until ready.
    
    ; Read data from the data port.
    mov ax, 4   ; Number of loader sectors.
    mov dx, 256 ; 512 bytes per sector, 1 word per read, 256 reads per sector.
    mul dx

    mov cx, ax
    mov dx, PRIMARY_SECTOR_DATA
    mov bx, 0x500   ; Place in real-mode region 0x500-0x7BFF.
    .go_on_read:
        in ax, dx
        mov [bx], ax
        add bx, 2
        loop .go_on_read
    jmp 0x500   ; Jump to the loader.

    ; Pad the MBR and write the boot signature.
    times 510-($-$$) db 0
    db 0x55, 0xaa