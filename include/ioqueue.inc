%ifndef IOQUEUE_INC
%define IOQUEUE_INC

%include "include/builtin.inc"

; Buffer size.
BUFSIZE equ 64

; Circular queue structure.
struc IOQueue
    .Head:      resd 1        ; Queue head.
    .Tail:      resd 1        ; Queue tail.
    .Lock:      resd 4        ; Mutex lock.
    .Producer:  resd 1        ; Waiting producer.
    .Consumer:  resd 1        ; Waiting consumer.
    .Buffer:    resb BUFSIZE  ; Data buffer.
endstruc

;-------------------------------------------------------------------------------
; Macro prototype: void ioq_init(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_init

%macro ioq_init 1
    ; Push 4-byte ioq argument.
    push_32 %1
    
    ; Call function and restore stack.
    call_lib ioq_init
    add esp, dword 4
%endmacro

%define ioq_init(ioq) ioq_init ioq

;-------------------------------------------------------------------------------
; Macro prototype: uint32_t ioq_next_pos(uint32_t pos)
;-------------------------------------------------------------------------------
extern_lib ioq_next_pos

%macro ioq_next_pos 1
    ; Push 4-byte pos argument.
    push_32 %1
    
    ; Call function and restore stack.
    call_lib ioq_next_pos
    add esp, dword 4
%endmacro

%define ioq_next_pos(pos) ioq_next_pos pos

;-------------------------------------------------------------------------------
; Macro prototype: bool_t ioq_full(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_full

%macro ioq_full 1
    ; Push 4-byte ioq argument.
    push_32 %1
    
    ; Call function and restore stack.
    call_lib ioq_full
    add esp, dword 4
%endmacro

%define ioq_full(ioq) ioq_full ioq

;-------------------------------------------------------------------------------
; Macro prototype: bool_t ioq_empty(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_empty

%macro ioq_empty 1
    ; Push 4-byte ioq argument.
    push_32 %1
    
    ; Call function and restore stack.
    call_lib ioq_empty
    add esp, dword 4
%endmacro

%define ioq_empty(ioq) ioq_empty ioq

;-------------------------------------------------------------------------------
; Macro prototype: void ioq_wait(pointer_t waiter)
;-------------------------------------------------------------------------------
extern_lib ioq_wait

%macro ioq_wait 1
    ; Push 4-byte waiter argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib ioq_wait
    add esp, dword 4
%endmacro

%define ioq_wait(waiter) ioq_wait waiter

;-------------------------------------------------------------------------------
; Macro prototype: void ioq_wakeup(pointer_t waiter)
;-------------------------------------------------------------------------------
extern_lib ioq_wakeup

%macro ioq_wakeup 1
    ; Push 4-byte waiter argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib ioq_wakeup
    add esp, dword 4
%endmacro

%define ioq_wakeup(waiter) ioq_wakeup waiter

;-------------------------------------------------------------------------------
; Macro prototype: char_t ioq_getchar(pointer_t ioq)
;-------------------------------------------------------------------------------
extern_lib ioq_getchar

%macro ioq_getchar 1
    ; Push 4-byte ioq argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib ioq_getchar
    add esp, dword 4
%endmacro

%define ioq_getchar(ioq) ioq_getchar ioq

;-------------------------------------------------------------------------------
; Macro prototype: void ioq_putchar(pointer_t ioq, char_t char)
;-------------------------------------------------------------------------------
extern_lib ioq_putchar

%macro ioq_putchar 2
    ; Push 1-byte char argument.
    push_8 %2

    ; Push 4-byte ioq argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib ioq_putchar
    add esp, dword 4 + 1
%endmacro

%define ioq_putchar(ioq, char) ioq_putchar ioq, char

%endif
