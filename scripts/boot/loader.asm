%include "include/system/gdt.inc"
%include "include/system/page.inc"
%include "include/system/primary.inc"

section .text vstart=0x500
    jmp enter_protected_mode

    ; Unused descriptor 0 in the GDT.
    null_desc: istruc SegDescriptor
        at LimitLow,      dw 0
        at BaseAddrLow,   dw 0

        at BaseAddrMid,   db 0
        at AttrType,      db 0
        at AttrLimit,     db 0
        at BaseAddrHigh,  db 0
    iend

    ; Code segment descriptor.
    code_desc: istruc SegDescriptor
        at LimitLow,      dw 0xffff
        at BaseAddrLow,   dw 0x0000

        at BaseAddrMid,   db 0x00
        at AttrType,      db DESC_P | DESC_DPL_0 | DESC_S_CODE | DESC_TYPE_CODE
        at AttrLimit,     db DESC_G_4K | DESC_D_32 | DESC_L | DESC_AVL | DESC_LIMIT_CODE2
        at BaseAddrHigh,  db 0x00
    iend

    ; Data segment descriptor.
    data_desc: istruc SegDescriptor
        at LimitLow,      dw 0xffff
        at BaseAddrLow,   dw 0x0000

        at BaseAddrMid,   db 0x00
        at AttrType,      db DESC_P | DESC_DPL_0 | DESC_S_DATA | DESC_TYPE_DATA
        at AttrLimit,     db DESC_G_4K | DESC_D_32 | DESC_L | DESC_AVL | DESC_LIMIT_DATA2
        at BaseAddrHigh,  db 0x00
    iend

    ; Video memory segment descriptor.
    VIDEO_BASE equ 0xb8000
    video_desc: istruc SegDescriptor
        at LimitLow,      dw 0x0007   ; (7 + 1) * 4KB = 32 KB.
        at BaseAddrLow,   dw VIDEO_BASE & 0000_1111111111111111b

        at BaseAddrMid,   db VIDEO_BASE >> 16
        at AttrType,      db DESC_P | DESC_DPL_0 | DESC_S_DATA | DESC_TYPE_DATA
        at AttrLimit,     db DESC_G_4K | DESC_D_32 | DESC_L | DESC_AVL | DESC_LIMIT_VIDEO2
        at BaseAddrHigh,  db 0x00   ; VIDEO_BASE >> 24.
    iend

    ; Prepare GDTR with the GDT base and limit.
    GDT_LIMIT equ ($ - null_desc) - 1

    gdt_ptr: istruc GdtPointer
        at Limit,    dw GDT_LIMIT
        at BaseAddr, dd null_desc
    iend

; Switch from 16-bit real mode to 32-bit protected mode.
enter_protected_mode:
    ; Enable the A20 line.
    in al, 0x92
    mov al, 00000010b
    out 0x92, al

    ; Load the GDT.
    lgdt [gdt_ptr]

    ; Set the PE bit in CR0.
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax
    
    ; Flush the pipeline and decode in 32-bit mode.
    jmp dword SELECTOR_K_CODE:protected_mode_main

[bits 32]
protected_mode_main:
    mov ax, SELECTOR_K_VIDEO
    mov es, ax
    mov ax, SELECTOR_K_DATA
    mov ss, ax

    jmp open_page_mode

; Set up paging and initialize memory bitmaps.
setup_page:
    mov ax, SELECTOR_K_DATA
    mov ds, ax

    ; Clear the page directory area.
    mov ecx, 4096
    mov esi, 0
    clear_page_dir:
        mov byte [PAGE_DIR_PHYS_ADDR + esi], 2

        add esi, 1
        loop clear_page_dir
    
    ; Create page directory entries.
    ; NOTE: Page tables are dynamic and can be allocated or cleared as needed.
    PAGE_ADDR equ PAGE_US_USER | PAGE_RW_READ_WRITE | PAGE_P

    create_pde:
        ; Point the first directory entry to the first page table.
        ; NOTE: Map the 3–4 GB range to the kernel for shared OS space.
        mov eax, PAGE_TABLE_PHYS_ADDR | PAGE_ADDR
        mov [PAGE_DIR_PHYS_ADDR + 0], eax
        mov [PAGE_DIR_PHYS_ADDR + (1024 - 256) * 4], eax
        
        ; Point the last directory entry to the page directory itself.
        mov eax, PAGE_DIR_PHYS_ADDR | PAGE_ADDR
        mov [PAGE_DIR_PHYS_ADDR + (1024 - 1) * 4], eax


    ; Create page table entries.
    mov ebx, PAGE_TABLE_PHYS_ADDR
    mov ecx, 256    ; 1 MB low memory maps to 256 pages of 4 KB.
    mov esi, 0
    mov edx, PAGE_ADDR

    create_pte:
        ; Map the first 256 PTEs to the 1 MB low physical pages.
        mov [ebx+esi*4], edx
        add edx, 4096

        add esi, 1
        loop create_pte

    ; Create kernel page tables.
    ; NOTE: Only the first page table is backed now, but the kernel range is reserved.
    mov eax, (PAGE_TABLE_PHYS_ADDR + 0x1000) | PAGE_ADDR ; Point to the second page table.
    mov ebx, PAGE_DIR_PHYS_ADDR
    mov ecx, 254
    mov esi, 769

    create_kernel_pde:
        mov [ebx+esi*4], eax
        add esi, 1  ; Move to the next PDE.
        add eax, 0x1000 ; Move to the next page table.
        loop create_kernel_pde
    ret

; Enable paging.
open_page_mode:
    call setup_page
    sgdt [gdt_ptr]

    ; Move the video segment base into the 3–4 GB kernel space.
    ; NOTE: This is equivalent to video_desc.BaseAddr += 0xC0000000.
    or dword [video_desc + 4], 0xc0000000

    ; Move the GDT base into the 3–4 GB kernel space.
    ; Move the stack pointer into the 3–4 GB kernel space.
    add dword [gdt_ptr + BaseAddr], 0xc0000000
    add esp, 0xc0000000

    ; Load CR3 with the page directory physical address.
    mov eax, PAGE_DIR_PHYS_ADDR
    mov cr3, eax

    ; Set the PG bit in CR0 to enable paging.
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    lgdt [gdt_ptr]
    jmp enter_kernel

; Load the kernel and jump to its entry.
enter_kernel:
    mov eax, 0x05   ; LBA sector number of the kernel.

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
    mov ax, 200   ; Number of kernel sectors.
    mov dx, 256 ; 512 bytes per sector, 1 word per read, 256 reads per sector.
    mul dx

    mov cx, ax
    mov dx, PRIMARY_SECTOR_DATA

    mov ebx, 0xd00   ; 0x500 + 512 * 4.
    .go_on_read:
        in ax, dx
        mov [ebx], ax
        add ebx, 2
        loop .go_on_read
    jmp 0xd00   ; Jump to the kernel.
