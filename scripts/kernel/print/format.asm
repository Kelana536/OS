%include "include/stdio.inc"

[bits 32]
;-------------------------------------------------------------------------------
; Function: printf
; Description: Formatted output function.
; Parameters:
;   - %1: Format string.
;   - %1+: Format arguments.
; Returns: Total number of characters printed.
;-------------------------------------------------------------------------------
func_lib printf
    intr_disable
    ; Track the total number of printed characters.
    uint32_t put_count, 0

    push esi
    push edi

    ; Pointer to stack arguments.
    arg pointer_t, format
    lea edi, format
    mov esi, [edi]

    put_str_loop:
        cmp [esi], byte '\'
        je need_escape
        
        cmp [esi], byte '%'
        je need_format
        
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
            mov [esi], byte 0x0A
            jmp is_nothing

        ; Escape: backspace.
        is_back:
            put_char(0x08)
            jmp print_str_next

        ; Handle format specifiers.
        need_format:
            inc esi

            cmp [esi], byte 's'
            je is_string
            cmp [esi], byte 'd'
            je is_int
            cmp [esi], byte 'u'
            je is_uint
            cmp [esi], byte 'p'
            je is_ptr
            cmp [esi], byte 'x'
            je is_hex_lower
            cmp [esi], byte 'X'
            je is_hex_upper
            cmp [esi], byte 'n'
            je is_count

            jmp is_nothing

        ; Format: string.
        is_string:
            add edi, 4
            put_str([edi])

            add put_count, eax
            jmp print_str_next

        ; Format: signed integer.
        is_int:
            add edi, 4
            put_int([edi])

            add put_count, eax
            jmp print_str_next
        
        ; Format: unsigned integer.
        is_uint:
            add edi, 4
            put_uint([edi])

            add put_count, eax
            jmp print_str_next
        
        ; Format: pointer address.
        is_ptr:
            put_char('0')
            put_char('x')
            jmp is_hex_lower

        ; Format: hexadecimal (lowercase).
        is_hex_lower:
            add edi, 4
            put_hex([edi], 0)

            add put_count, eax
            jmp print_str_next
        
        is_hex_upper:
            add edi, 4
            put_hex([edi], 1)

            add put_count, eax
            jmp print_str_next

        ; Format: print count.
        is_count:
            put_uint(put_count)

            add put_count, eax
            jmp print_str_next

        ; No escape or formatting needed.
        is_nothing:
            put_char([esi])

            add put_count, dword 1
            jmp print_str_next

    print_str_next:
        ; Stop when reaching the null terminator.
        inc esi
        cmp [esi], byte 0
        jne put_str_loop
    
    intr_recover
    return_32 put_count
func_end
