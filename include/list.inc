%ifndef LIST_INC
%define LIST_INC

%include "include/builtin.inc"

; List structure.
struc List
    .Head:  resd 1  ; Pointer to list head.
    .Tail:  resd 1  ; Pointer to list tail.
endstruc

; List element structure.
struc ListElem
    .Prev:  resd 1  ; Pointer to previous element.
    .Next:  resd 1  ; Pointer to next element.
endstruc

;-------------------------------------------------------------------------------
; Macro prototype: void list_clear(pointer_t list)
;-------------------------------------------------------------------------------
extern_lib list_clear

%macro list_clear 1
    ; Push 4-byte list argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_clear
    add esp, dword 4
%endmacro

%define list_clear(list) list_clear list

;-------------------------------------------------------------------------------
; Macro prototype: void list_append(pointer_t list, pointer_t elem)
;-------------------------------------------------------------------------------
extern_lib list_append

%macro list_append 2
    ; Push 4-byte elem argument.
    push_32 %2

    ; Push 4-byte list argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_append
    add esp, dword 4 + 4
%endmacro

%define list_append(list, elem) list_append list, elem

;-------------------------------------------------------------------------------
; Macro prototype: void list_push(pointer_t list, pointer_t elem)
;-------------------------------------------------------------------------------
extern_lib list_push

%macro list_push 2
    ; Push 4-byte elem argument.
    push_32 %2

    ; Push 4-byte list argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_push
    add esp, dword 4 + 4
%endmacro

%define list_push(list, elem) list_push list, elem

;-------------------------------------------------------------------------------
; Macro prototype: void list_print(pointer_t list)
;-------------------------------------------------------------------------------
extern_lib list_print

%macro list_print 1
    ; Push 4-byte list argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_print
    add esp, dword 4
%endmacro

%define list_print(list) list_print list

;-------------------------------------------------------------------------------
; Macro prototype: void list_remove(pointer_t elem)
;-------------------------------------------------------------------------------
extern_lib list_remove

%macro list_remove 1
    ; Push 4-byte elem argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_remove
    add esp, dword 4
%endmacro

%define list_remove(elem) list_remove elem

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t list_pop(pointer_t list)
;-------------------------------------------------------------------------------
extern_lib list_pop

%macro list_pop 1
    ; Push 4-byte list argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_pop
    add esp, dword 4
%endmacro

%define list_pop(list) list_pop list

;-------------------------------------------------------------------------------
; Macro prototype: bool_t list_exist(pointer_t list, pointer_t elem)
;-------------------------------------------------------------------------------
extern_lib list_exist

%macro list_exist 2
    ; Push 4-byte elem argument.
    push_32 %2

    ; Push 4-byte list argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_exist
    add esp, dword 4 + 4
%endmacro

%define list_exist(list, elem) list_exist list, elem

;-------------------------------------------------------------------------------
; Macro prototype: bool_t list_is_empty(pointer_t list)
;-------------------------------------------------------------------------------
extern_lib list_is_empty

%macro list_is_empty 1
    ; Push 4-byte list argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib list_is_empty
    add esp, dword 4
%endmacro

%define list_is_empty(list) list_is_empty list

%endif