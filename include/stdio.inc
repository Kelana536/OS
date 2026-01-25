%ifndef STDIO_INC
%define STDIO_INC

%include "include/builtin.inc"

;-------------------------------------------------------------------------------
; Macro prototype: void put_char(char_t ascii)
;-------------------------------------------------------------------------------
extern_lib put_char

%macro put_char 1
    ; Push 1-byte ascii argument.
    push_8 %1

    ; Call function and restore stack.
    call_lib put_char
    add esp, dword 1
%endmacro

%define put_char(ascii) put_char ascii

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t put_str(pointer_t char_ptr)
;-------------------------------------------------------------------------------
extern_lib put_str

%macro put_str 1
    ; Push 4-byte char_ptr argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib put_str
    add esp, dword 4
%endmacro

%define put_str(char_ptr) put_str char_ptr

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t put_uint(uint32_t number)
;-------------------------------------------------------------------------------
extern_lib put_uint

%macro put_uint 1
    ; Push 4-byte number argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib put_uint
    add esp, dword 4
%endmacro

%define put_uint(number) put_uint number

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t put_int(uint32_t number)
;-------------------------------------------------------------------------------
extern_lib put_int

%macro put_int 1
    ; Push 4-byte number argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib put_int
    add esp, dword 4
%endmacro

%define put_int(number) put_int number

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t put_hex(uint32_t number, bool_t is_upper)
;-------------------------------------------------------------------------------
extern_lib put_hex

%macro put_hex 2
    ; Push 1-byte is_upper argument.
    push_8 %2 

    ; Push 4-byte number argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib put_hex
    add esp, dword 4 + 1
%endmacro

%define put_hex(number, is_upper) put_hex number, is_upper

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t printf(pointer_t format, ...)
;-------------------------------------------------------------------------------
extern_lib printf

%macro printf 1-*
    %rep %0
        %rotate %0 - 1
        push_32 %1     
    %endrep

    call_lib printf
    add esp, %0 * 4
%endmacro

%define printf(format) printf format
%define printf(format, arg1) printf format, arg1
%define printf(format, arg1, arg2) printf format, arg1, arg2
%define printf(format, arg1, arg2, arg3) printf format, arg1, arg2, arg3
%define printf(format, arg1, arg2, arg3, arg4) printf format, arg1, arg2, arg3, arg4
%define printf(format, arg1, arg2, arg3, arg4, arg5) printf format, arg1, arg2, arg3, arg4, arg5
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6) printf format, arg1, arg2, arg3, arg4, arg5, arg6
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6, arg7) printf format, arg1, arg2, arg3, arg4, arg5, arg6, arg7
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) printf format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
%define printf(format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) printf format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

;-------------------------------------------------------------------------------
; Macro prototype: void panic(pointer_t error)
;-------------------------------------------------------------------------------
extern_lib panic

%macro panic 1
    ; Disable interrupts to avoid interference.
    cli

    ; Push error message string.
    push_32 %1

    ; Push function name string.
    push_32 __FUNCSTR__

    ; Push line number.
    push_32 __LINE__

    ; Push file name string.
    push_32 __FILE__

    ; Call function and restore stack.
    call_lib panic
    add esp, 4 * 4

    ; Halt execution here.
    cli
    jmp $
%endmacro

%define panic(error) panic error

%endif
