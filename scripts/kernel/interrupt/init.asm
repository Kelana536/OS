%include "include/builtin.inc"
%include "include/system/idt.inc"

[bits 32]
; 8259A master/slave PIC ports.
PIC_M_CTRL equ 0x20
PIC_M_DATA equ 0x21
PIC_S_CTRL equ 0xA0
PIC_S_DATA equ 0xA1

; Number of supported interrupts.
INTR_DESC_CNT equ 0x30

section .data
    ; Storage for INTR_DESC_CNT interrupt descriptors (8 bytes each).
    intr_desc_table times 8 * INTR_DESC_CNT db 0

    ; IDT pointer used to load the IDT table.
    idt_ptr: istruc IdtPointer
        at Limit,    dw 8 * INTR_DESC_CNT - 1
        at BaseAddr, dd intr_desc_table
    iend

    ; Storage for INTR_DESC_CNT interrupt entry addresses.
    global intr_entry_table

    intr_entry_table:
        ; 0x00 Divide-by-zero exception.
        dd intr_entry_no_err

        ; 0x01 Debug exception.
        dd intr_entry_no_err

        ; 0x02 Non-maskable interrupt.
        dd intr_entry_no_err

        ; 0x03 Breakpoint exception (INT3).
        dd intr_entry_no_err

        ; 0x04 Reserved.
        dd intr_entry_no_err

        ; 0x05 Reserved.
        dd intr_entry_no_err

        ; 0x06 Reserved.
        dd intr_entry_no_err

        ; 0x07 Reserved.
        dd intr_entry_no_err

        ; 0x08 Double fault.
        dd intr_entry_with_err

        ; 0x09 Coprocessor segment overrun.
        dd intr_entry_no_err

        ; 0x0A Reserved.
        dd intr_entry_with_err

        ; 0x0B Floating-point error.
        dd intr_entry_with_err

        ; 0x0C Segment not present.
        dd intr_entry_no_err

        ; 0x0D Stack segment fault.
        dd intr_entry_with_err

        ; 0x0E Page fault.
        dd intr_entry_with_err

        ; 0x0F Invalid opcode in protected mode.
        dd intr_entry_no_err

        ; 0x10 Reserved.
        dd intr_entry_no_err

        ; 0x11 Reserved.
        dd intr_entry_with_err

        ; 0x12 Coprocessor error (unmasked).
        dd intr_entry_no_err

        ; 0x13 Reserved.
        dd intr_entry_no_err

        ; 0x14 Reserved.
        dd intr_entry_no_err

        ; 0x15 Reserved.
        dd intr_entry_no_err

        ; 0x16 Reserved.
        dd intr_entry_no_err

        ; 0x17 Reserved.
        dd intr_entry_no_err

        ; 0x18 Reserved.
        dd intr_entry_with_err

        ; 0x19 Reserved.
        dd intr_entry_no_err

        ; 0x1A Reserved.
        dd intr_entry_with_err

        ; 0x1B Reserved.
        dd intr_entry_with_err

        ; 0x1C Reserved.
        dd intr_entry_no_err

        ; 0x1D Reserved.
        dd intr_entry_with_err

        ; 0x1E Reserved.
        dd intr_entry_with_err

        ; 0x1F Reserved.
        dd intr_entry_no_err

        ; 0x20 Timer interrupt (IRQ0).
        dd intr_entry_no_err

        ; 0x21 Keyboard interrupt (IRQ1).
        dd intr_entry_no_err

        ; 0x22 Reserved.
        dd intr_entry_no_err

        ; 0x23 Reserved.
        dd intr_entry_no_err

        ; 0x24 Reserved.
        dd intr_entry_no_err

        ; 0x25 Reserved.
        dd intr_entry_no_err

        ; 0x26 Reserved.
        dd intr_entry_no_err

        ; 0x27 Reserved.
        dd intr_entry_no_err

        ; 0x28 Reserved.
        dd intr_entry_no_err

        ; 0x29 Reserved.
        dd intr_entry_no_err

        ; 0x2A Reserved.
        dd intr_entry_no_err

        ; 0x2B Reserved.
        dd intr_entry_no_err

        ; 0x2C Reserved.
        dd intr_entry_no_err

        ; 0x2D Reserved.
        dd intr_entry_no_err

        ; 0x2E Reserved.
        dd intr_entry_no_err

        ; 0x2F Reserved.
        dd intr_entry_no_err

section .text
    ; Common interrupt entry without error code.
    intr_entry_no_err:
        ; Send EOI to the PIC.
        push eax
        
        mov al, PIC_M_CTRL
        out 0xa0,al
        out 0x20,al

        pop eax

        ; Return from interrupt.
        iret


    ; Common interrupt entry with an error code.
    intr_entry_with_err:
        ; Skip the error code.
        add esp, 4

        ; Send EOI to the PIC.
        push eax
        
        mov al, PIC_M_CTRL
        out 0xa0,al
        out 0x20,al

        pop eax

        ; Return from interrupt.
        iret

;-------------------------------------------------------------------------------
; Function: make_idt_desc
; Description: Register an interrupt descriptor in intr_desc_table.
; Parameters:
;   - %1: Descriptor address.
;   - %2: Descriptor attributes.
;   - %3: Entry function address.
; Returns: None.
;-------------------------------------------------------------------------------
func make_idt_desc
    arg pointer_t, p_gdesc
    arg uint8_t, attr
    arg pointer_t, function

    mov ebx, function
    mov eax, [ebx]

    mov ebx, p_gdesc

    mov word [ebx + FuncLow], ax
    shr eax, 16
    mov word [ebx + FuncHigh], ax

    mov word [ebx + Selector], SELECTOR_K_CODE

    mov byte [ebx + ArgCount],  0

    mov al, attr
    mov byte [ebx + AttrType], al
func_end


;-------------------------------------------------------------------------------
; Function: idt_desc_init
; Description: Initialize the IDT descriptor table.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
func idt_desc_init
    mov ecx, INTR_DESC_CNT
    mov edi, intr_desc_table
    mov esi, intr_entry_table

    make_loop:
        sub esp, 4
        mov dword [esp], esi

        sub esp, 1
        mov byte [esp], DESC_P | DESC_DPL_0 | DESC_S_SYS | DESC_TYPE_32

        sub esp, 4
        mov dword [esp], edi

        call make_idt_desc
        add esp, 4 + 1 + 4
        
        add edi, 8
        add esi, 4
        loop make_loop
func_end

;-------------------------------------------------------------------------------
; Function: idt_init
; Description: Initialize PIC/IDT and load the IDT.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
extern timer_init
extern keyboard_init

func idt_init
    ; Initialize master PIC (8259A).
    mov al, 0x11      ; ICW1.
    out PIC_M_CTRL, al     ; Send ICW1 to master command port.

    mov al, 0x20      ; Set master vector offset to 0x20.
    out PIC_M_DATA, al     ; Send vector offset to master data port.

    mov al, 0x04      ; Master IR2 connected to slave.
    out PIC_M_DATA, al     ; Send IR2 wiring info.

    mov al, 0x01      ; 8086 mode.
    out PIC_M_DATA, al     ; Send mode to master.

    ; Initialize slave PIC (8259A).
    mov al, 0x11      ; ICW1.
    out PIC_S_CTRL, al     ; Send ICW1 to slave command port.

    mov al, 0x28      ; Set slave vector offset to 0x28.
    out PIC_S_DATA, al     ; Send vector offset to slave data port.

    mov al, 0x02      ; Slave connected to master IR2.
    out PIC_S_DATA, al     ; Send wiring info to slave.

    mov al, 0x01      ; 8086 mode.
    out PIC_S_DATA, al     ; Send mode to slave.

    ; Initialize device interrupts.
    call timer_init
    call keyboard_init

    ; Enable IR0 and IR1 on the master PIC.
    mov al, 0xfc
    out PIC_M_DATA, al

    mov al, 0xff
    out PIC_S_DATA, al

    ; Load the IDT with lidt.
    call idt_desc_init
    lidt [idt_ptr]
func_end
