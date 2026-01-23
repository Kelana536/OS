%ifndef GDT_INC
%define GDT_INC

; GDT pointer structure with limit and base address.
struc GdtPointer
    Limit:    resw 1   ; GDT limit.
    BaseAddr: resd 1   ; GDT base address.
endstruc

; Segment descriptor structure.
struc SegDescriptor
    ; Low 32 bits.
    LimitLow:      resw 1   ; Segment limit 15..0.
    BaseAddrLow:   resw 1   ; Segment base 15..0.
    
    ; High 32 bits.
    BaseAddrMid:   resb 1   ; Segment base 23..16.
    AttrType:      resb 1   ; Attributes (P | DPL | S | TYPE).
    AttrLimit:     resb 1   ; Flags and limit (G | D/B | L | AVL | limit 19..16).
    BaseAddrHigh:  resb 1   ; Segment base 31..24.
endstruc

; P bit in AttrType indicates segment presence.
; NOTE: P=1 means present; P=0 triggers a CPU exception.
DESC_P equ 1_0000000b

; DPL field encodes privilege level.
; NOTE: Levels 0-3, lower is more privileged (kernel=0, user=3).
DESC_DPL_0 equ 0_00_00000b
DESC_DPL_1 equ 0_01_00000b
DESC_DPL_2 equ 0_10_00000b
DESC_DPL_3 equ 0_11_00000b

; S bit indicates system vs non-system descriptor.
; NOTE: S=0 is system; S=1 is code/data.
DESC_S_SYS  equ 000_0_0000b
DESC_S_CODE equ 000_1_0000b
DESC_S_DATA equ DESC_S_CODE

; TYPE field encodes the segment subtype.
; NOTE: For code segments: X (execute), C (conforming), R (readable), A (accessed).
; NOTE: For data segments: X (execute), E (expand direction), W (writable), A (accessed).
; NOTE: A is set by the CPU on access and can indicate descriptor use.
; NOTE: C=0 forbids cross-privilege access; C=1 allows conforming code.
; NOTE: E=0 expands upward, E=1 expands downward (stack).
DESC_TYPE_CODE equ 0000_1000b ; Executable, non-conforming, not readable, accessed clear.
DESC_TYPE_DATA equ 0000_0010b ; Non-executable, upward, writable, accessed clear.


; G bit selects the segment limit granularity.
; NOTE: G=0 uses 1B units, G=1 uses 4 KB units.
; NOTE: Limit range is 1 MB (2^20) or 4 GB (2^(20+12)).
DESC_G_4K equ 1_0000000b

; D/B bit selects operand and address size.
; NOTE: For code segments, D=0 uses 16-bit (IP), D=1 uses 32-bit (EIP).
; NOTE: For stack segments, B=0 uses 16-bit SP, B=1 uses 32-bit ESP.
DESC_D_32 equ 0_1_000000b

; L bit indicates 64-bit code segments.
; NOTE: This project targets 32-bit, so L=0.
DESC_L equ 00_0_00000b

; AVL bit is available for software use.
DESC_AVL equ 000_0_0000b

; The last 4 bits are the high bits of the segment limit.
; NOTE: Together with LimitLow they form the full 20-bit limit.
DESC_LIMIT_CODE2  equ 0000_1111b
DESC_LIMIT_DATA2  equ DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2 equ 0000_0000b

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
SELECTOR_K_VIDEO equ (0x03 << 3) | TI_GDT | RPL_0

%endif
