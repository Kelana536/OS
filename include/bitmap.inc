%ifndef BITMAP_INC
%define BITMAP_INC

%include "include/builtin.inc"

; Bitmap structure.
struc BitMap
    .ByteSize:   resd 1   ; Bitmap size in bytes.
    .BitPointer: resd 1   ; Pointer to bitmap data.
endstruc

;-------------------------------------------------------------------------------
; Macro prototype: void bitmap_empty(pointer_t btmp)
;-------------------------------------------------------------------------------
extern_lib bitmap_empty

%macro bitmap_empty 1
    ; Push 4-byte btmp argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib bitmap_empty
    add esp, dword 4
%endmacro

%define bitmap_empty(btmp) bitmap_empty btmp

;-------------------------------------------------------------------------------
; Macro prototype: bool_t bitmap_get(pointer_t btmp, uint32_t bit_idx)
;-------------------------------------------------------------------------------
extern_lib bitmap_get

%macro bitmap_get 2
    ; Push 4-byte bit_idx argument.
    push_32 %2

    ; Push 4-byte btmp argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib bitmap_get
    add esp, dword 4 + 4
%endmacro

%define bitmap_get(btmp, bit_idx) bitmap_get btmp, bit_idx

;-------------------------------------------------------------------------------
; Macro prototype: void bitmap_set(pointer_t btmp, uint32_t bit_idx, bool_t state)
;-------------------------------------------------------------------------------
extern_lib bitmap_set

%macro bitmap_set 3
    ; Push 1-byte state argument.
    push_8 %3

    ; Push 4-byte bit_idx argument.
    push_32 %2

    ; Push 4-byte btmp argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib bitmap_set
    add esp, dword 4 + 4 + 1
%endmacro

%define bitmap_set(btmp, bit_idx, state) bitmap_set btmp, bit_idx, state

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t bitmap_scan(pointer_t btmp, uint32_t count)
;-------------------------------------------------------------------------------
extern_lib bitmap_scan

%macro bitmap_scan 2
    ; Push 4-byte count argument.
    push_32 %2

    ; Push 4-byte btmp argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib bitmap_scan
    add esp, dword 4 + 4
%endmacro

%define bitmap_scan(btmp, count) bitmap_scan btmp, count

%endif