%include "include/stdio.inc"

[bits 32]
;-------------------------------------------------------------------------------
; Function: put_str
; Description: Print a string to the console.
; Parameters:
;   - %1: String address.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib put_str
    ; Track total number of printed characters.
    uint32_t put_count, 0

    ; Traverse the string and print.
    arg pointer_t, char_ptr
    mov esi, char_ptr

    put_str_loop:
        cmp [esi], byte '\'
        je need_escape
        jmp is_nothing

        ; Handle escape sequences.
        need_escape:
            inc esi

            cmp [esi], byte 'n'
            je is_wrap

            cmp [esi], byte 'b'
            je is_back

            jmp is_nothing
            
        ; Escape: newline.
        is_wrap:
            put_char(0x0A)
            jmp put_str_next

        ; Escape: backspace.
        is_back:
            put_char(0x08)
            sub put_count, dword 1
            jmp put_str_next

        ; No escape handling needed.
        is_nothing:
            mov dl, [esi]
            put_char(dl)
            jmp put_str_next

    put_str_next:
        add put_count, dword 1

        ; Stop on null terminator.
        inc esi
        cmp [esi], byte 0
        jne put_str_loop

    return_32 put_count
func_end