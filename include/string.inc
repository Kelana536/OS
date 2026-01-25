%ifndef STRING_INC
%define STRING_INC

%include "include/builtin.inc"

;-------------------------------------------------------------------------------
; Macro prototype: void memset(pointer_t buffer, uint8_t value, uint32_t length)
;-------------------------------------------------------------------------------
extern_lib memset

%macro memset 3
    ; Push 4-byte length argument.
    push_32 %3

    ; Push 1-byte value argument.
    push_8 %2

    ; Push 4-byte buffer argument.
    push_32 %1

    call_lib memset
    add esp, 4 + 1 + 4
%endmacro

%define memset(buffer, value, length) memset buffer, value, length

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t memcpy(pointer_t target, pointer_t source, uint32_t length)
;-------------------------------------------------------------------------------
extern_lib memcpy

%macro memcpy 3
    ; Push 4-byte length argument.
    push_32 %3

    ; Push 4-byte source argument.
    push_32 %2
    
    ; Push 4-byte target argument.
    push_32 %1

    call_lib memcpy
    add esp, 4 + 4 + 4
%endmacro

%define memcpy(target, source, length) memcpy target, source, length

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t strcpy(pointer_t target, pointer_t source)
;-------------------------------------------------------------------------------
extern_lib strcpy

%macro strcpy 2
    ; Push 4-byte source argument.
    push_32 %2
    
    ; Push 4-byte target argument.
    push_32 %1

    call_lib strcpy
    add esp, 4 + 4
%endmacro

%define strcpy(target, source) strcpy target, source

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t strlen(pointer_t str)
;-------------------------------------------------------------------------------
extern_lib strlen

%macro strlen 1
    ; Push 4-byte str argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib strlen
    add esp, dword 4
%endmacro

%define strlen(str) strlen str

%endif
