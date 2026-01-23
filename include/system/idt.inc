%ifndef IDT_INC
%define IDT_INC

;-------------------------------------------------------------------------------
; Description: Defines IDT (Interrupt Descriptor Table) constants and structures.
;-------------------------------------------------------------------------------

; IDT pointer structure with limit and base address.
struc IdtPointer
    Limit:    resw 1   ; IDT limit.
    BaseAddr: resd 1   ; IDT base address.
endstruc

; Interrupt gate descriptor.
struc InterruptGate
    ; Low 32 bits.
    FuncLow:    resw 1   ; Low 16 bits of handler offset.
    Selector:   resw 1   ; Code segment selector for the handler.
    
    ; High 32 bits.
    ArgCount:      resb 1   ; Parameter count and fixed zero bits.
    AttrType:     resb 1   ; Attributes (P | DPL | S | TYPE).
    FuncHigh:  resw 1   ; High 16 bits of handler offset.
endstruc

; P bit in AttrType indicates segment presence.
; NOTE: P=1 means present in memory; P=0 triggers a CPU exception.
DESC_P equ 1_0000000b

; DPL field encodes privilege level.
; NOTE: Levels 0-3, lower is more privileged (kernel=0, user=3).
DESC_DPL_0 equ 0_00_00000b
DESC_DPL_3 equ 0_11_00000b

; S bit indicates system vs non-system descriptor.
; NOTE: S=0 is system; S=1 is code/data.
DESC_S_SYS  equ 000_0_0000b

; TYPE field encodes the segment or gate subtype.
; NOTE: For code segments: X (execute), C (conforming), R (readable), A (accessed).
; NOTE: For data segments: X (execute), E (expand direction), W (writable), A (accessed).
; NOTE: A is set by the CPU on access and can indicate descriptor use.
; NOTE: C=0 means non-conforming code and forbids cross-privilege access.
; NOTE: C=1 means conforming code, privilege does not change on access.
; NOTE: E=0 means upward expansion (code/data), E=1 means downward (stack).
DESC_TYPE_32 equ 0000_1110b

;-------------------------------------------------------------------------------
; Description: Selector-related constants for RPL and TI bits.
;-------------------------------------------------------------------------------

; Selectors are 16-bit, low 2 bits hold RPL.
RPL_0 equ 00b
RPL_1 equ 01b
RPL_2 equ 10b
RPL_3 equ 11b

; Bit 2 is TI (table indicator).
; NOTE: TI=0 indexes GDT, TI=1 indexes LDT.
TI_GDT equ 00b
TI_LDT equ 10b

; Segment selector constants.
SELECTOR_K_CODE equ (0x01 << 3) | TI_GDT | RPL_0
SELECTOR_K_DATA equ (0x02 << 3) | TI_GDT | RPL_0
SELECTOR_STACK equ SELECTOR_K_DATA
SELECTOR_K_VIDEO equ (0x03 << 3) | TI_GDT | RPL_0

%endif