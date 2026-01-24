%ifndef TSS_INC
%define TSS_INC

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

; Task State Segment (TSS) structure.
struc TaskStateSegment
    .BackLink: resd 1
    .Esp0:     resd 1
    .Ss0:      resd 1
    .Esp1:     resd 1
    .Ss1:      resd 1
    .Esp2:     resd 1
    .Ss2:      resd 1
    .Cr3:      resd 1
    .Eip:      resd 1
    .Eflags:   resd 1
    .Eax:      resd 1
    .Ecx:      resd 1
    .Edx:      resd 1
    .Ebx:      resd 1
    .Esp:      resd 1
    .Ebp:      resd 1
    .Esi:      resd 1
    .Edi:      resd 1
    .Es:       resd 1
    .Cs:       resd 1
    .Ss:       resd 1
    .Ds:       resd 1
    .Fs:       resd 1
    .Gs:       resd 1
    .Ldt:      resd 1
    .Trace:    resd 1
    .IoBase:   resd 1
endstruc

; Size of the TSS structure.
TSS_SIZE equ 27 * 4

; GDT constant definitions.
DESC_G_4K equ 1
DESC_D_32 equ 1
DESC_L    equ 0
DESC_AVL  equ 0
DESC_P    equ 1
DESC_DPL_0 equ 0
DESC_DPL_1 equ 1
DESC_DPL_2 equ 2
DESC_DPL_3 equ 3

TI_GDT equ 0
RPL_0 equ 0
RPL_1 equ 1
RPL_2 equ 2
RPL_3 equ 3

DESC_S_CODE equ 1
DESC_S_DATA equ 1
DESC_S_SYS  equ 0
DESC_TYPE_CODE  equ 8
DESC_TYPE_DATA  equ 2

; Segment selector constants.
SELECTOR_K_DATA equ (0x02 << 3) | TI_GDT | RPL_0
SELECTOR_TSS    equ (0x04 << 3) | TI_GDT | RPL_0
SELECTOR_U_CODE equ (0x05 << 3) | TI_GDT | RPL_0
SELECTOR_U_DATA equ (0x06 << 3) | TI_GDT | RPL_0


; 32-bit available TSS (Type=1001b).
; 32-bit busy TSS (Type=1011b).
DESC_TYPE_TSS equ 0000_1001b

; D/B bit in TSS descriptor is called B.
; NOTE: B=0 means not busy, B=1 means busy or nested. Initialize as 0.
TSS_DESC_D equ 0

; NOTE: DESC_P << 7     : P=1, segment present.
; NOTE: DESC_DPL_0 << 5 : DPL=0, kernel only.
; NOTE: DESC_S_SYS << 4 : S=0, system segment.
; NOTE: DESC_TYPE_TSS   : Type=0x9 (32-bit available TSS).
TSS_ATTR_LOW equ (DESC_P << 7) | (DESC_DPL_0 << 5) | (DESC_S_SYS << 4) | DESC_TYPE_TSS

; NOTE: DESC_G_4K << 7  : G=1, limit granularity is 4 KB.
; NOTE: TSS_DESC_D << 6 : B=0, task starts non-busy.
; NOTE: DESC_L << 5     : L=0, not 64-bit.
; NOTE: DESC_S_SYS << 4 : Reserved (kept for descriptor format).
TSS_ATTR_HIGH equ (DESC_G_4K << 7) | (TSS_DESC_D << 6) | (DESC_L << 5) | (DESC_S_SYS << 4)

; High attribute byte composition.
GDT_ATTR_HIGH equ (DESC_G_4K << 7) | (DESC_D_32 << 6) | (DESC_L << 5) | (DESC_AVL << 4)

; User-mode (DPL=3) code segment low attribute byte.
GDT_CODE_ATTR_LOW_DPL3 equ (DESC_P << 7) | (DESC_DPL_3 << 5) | (DESC_S_CODE << 4) | DESC_TYPE_CODE

; User-mode (DPL=3) data segment low attribute byte.
GDT_DATA_ATTR_LOW_DPL3 equ (DESC_P << 7) | (DESC_DPL_3 << 5) | (DESC_S_CODE << 4) | DESC_TYPE_DATA

%endif
