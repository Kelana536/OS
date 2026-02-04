%include "include/list.inc"
%include "include/stdio.inc"

;-------------------------------------------------------------------------------
; Function: list_clear
; Description: Clear all elements in a list.
; Parameters:
;   - %1: Pointer to list.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib list_clear
    ; Undefine macros to avoid name collisions.
    %undef list

    ; Declare function arguments.
    arg pointer_t, list

    ; Function body.
    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edi, [ebx + List.Tail]

    mov [esi + ListElem.Prev], dword NULL
    mov [esi + ListElem.Next], dword edi

    mov [edi + ListElem.Prev], dword esi
    mov [edi + ListElem.Next], dword NULL
func_end

;-------------------------------------------------------------------------------
; Function: list_append
; Description: Append an element to the list tail.
; Parameters:
;   - %1: Pointer to list.
;   - %2: Pointer to element.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib list_append
    ; Undefine macros to avoid name collisions.
    %undef list
    %undef elem

    ; Declare function arguments.
    arg pointer_t, list
    arg pointer_t, elem

    ; Function body.
    mov ebx, list
    mov edi, [ebx + List.Tail]
    mov edx, elem

    mov eax, [edi + ListElem.Prev]
    mov [edx + ListElem.Prev], eax
    mov [edx + ListElem.Next], edi

    mov esi, [edx + ListElem.Prev]
    mov [esi + ListElem.Next], edx

    mov [edi + ListElem.Prev], edx
func_end

;-------------------------------------------------------------------------------
; Function: list_push
; Description: Insert an element at the list head.
; Parameters:
;   - %1: Pointer to list.
;   - %2: Pointer to element.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib list_push
    ; Undefine macros to avoid name collisions.
    %undef list
    %undef elem

    ; Declare function arguments.
    arg pointer_t, list
    arg pointer_t, elem

    ; Function body.
    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edx, elem

    mov eax, [esi + ListElem.Next]
    mov [edx + ListElem.Prev], esi
    mov [edx + ListElem.Next], eax

    mov edi, [edx + ListElem.Next]
    mov [edi + ListElem.Prev], edx

    mov [esi + ListElem.Next], edx
func_end

;-------------------------------------------------------------------------------
; Function: list_print
; Description: Print list elements to the screen.
; Parameters:
;   - %1: Pointer to list.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib list_print
    ; Undefine macros to avoid name collisions.
    %undef list

    ; Declare function arguments.
    arg pointer_t, list

    ; Function body.
    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edi, [ebx + List.Tail]
    mov edx, [esi + ListElem.Next]

    printf("\nHead -> ")

    print_loop:
        cmp edx, edi
        je print_tail

        printf("%p -> ",edx)
        mov edx, [edx + ListElem.Next]
        jmp print_loop

    print_tail: printf("Tail\n")
func_end

;-------------------------------------------------------------------------------
; Function: list_remove
; Description: Remove an element from the list.
; Parameters:
;   - %1: Pointer to element.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib list_remove
    ; Undefine macros to avoid name collisions.
    %undef elem

    ; Declare function arguments.
    arg pointer_t, elem

    ; Function body.
    mov ebx, elem
    mov esi, [ebx + ListElem.Prev]
    mov edi, [ebx + ListElem.Next]

    mov [esi + ListElem.Next], edi
    mov [edi + ListElem.Prev], esi
func_end

;-------------------------------------------------------------------------------
; Function: list_pop
; Description: Pop and return the head element.
; Parameters:
;   - %1: Pointer to list.
; Returns: Pointer to head element.
;-------------------------------------------------------------------------------
func_lib list_pop
    ; Undefine macros to avoid name collisions.
    %undef list
    %undef elem

    ; Declare function arguments.
    arg pointer_t, list

    mov ebx, list
    mov esi, [ebx + List.Head]

    pointer_t elem, [esi +ListElem.Next]
    list_remove(elem)
    return_32 elem
func_end

;-------------------------------------------------------------------------------
; Function: list_exist
; Description: Check whether an element is in the list.
; Parameters:
;   - %1: Pointer to list.
;   - %2: Pointer to element.
; Returns: TRUE if present, FALSE otherwise.
;-------------------------------------------------------------------------------
func_lib list_exist
    ; Undefine macros to avoid name collisions.
    %undef list
    %undef elem

    ; Declare function arguments.
    arg pointer_t, list
    arg pointer_t, elem

    ; Function body.
    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edi, [ebx + List.Tail]
    mov edx, [esi + ListElem.Next]

    check_exist_loop:
        cmp edx, edi
        je non_exist

        cmp edx, elem
        je is_exist

        mov edx, [edx + ListElem.Next]
        jmp check_exist_loop

    is_exist:  return_8 TRUE
    non_exist: return_8 FALSE
func_end

;-------------------------------------------------------------------------------
; Function: list_is_empty
; Description: Check whether a list is empty.
; Parameters:
;   - %1: Pointer to list.
; Returns: TRUE if empty, FALSE otherwise.
;-------------------------------------------------------------------------------
func_lib list_is_empty
    ; Undefine macros to avoid name collisions.
    %undef list

    ; Declare function arguments.
    arg pointer_t, list

    ; Function body.
    mov ebx, list
    mov esi, [ebx + List.Head]
    mov edi, [ebx + List.Tail]
    mov edx, [esi + ListElem.Next]

    cmp edx, edi
    jne non_empty

    is_empty:  return_8 TRUE
    non_empty: return_8 FALSE
func_end