%include "include/stdio.inc"

[bits 32]
;-------------------------------------------------------------------------------
; Function: put_hex
; Description: Print an unsigned hexadecimal integer.
; Parameters:
;   - %1: Value to print.
;   - %2: Use uppercase output.
; Returns: Total number of characters printed.
;-------------------------------------------------------------------------------
func_lib put_hex
    ; Divisor used for hex conversion.
    uint32_t divisor, 16

    ; Buffer for hex digits (max 8 chars for 32-bit value).
    uint8_t buffer_end, 0
    local char_t * 8, buffer

    ; Convert by dividing by 16 and printing remainders.
    arg uint32_t, u_num
    arg bool_t, is_upper
    mov eax, dword u_num

    lea esi, buffer
    add esi, 8

    hex_fmt_loop:
        dec esi

        mov edx, 0
        idiv dword divisor

        cmp dl, 9
        jg more_nine

        add dl, '0'
        jmp hex_fmt_next

        ; Remainder > 9, use hex letters.
        more_nine:
            add dl, 'A' - 10

            cmp is_upper, byte FALSE
            jne hex_fmt_next

            add dl, 'a' - 'A'
            
    hex_fmt_next:
        mov [esi], byte dl

        cmp eax, 0
        jne hex_fmt_loop
    
    put_str(esi)
func_end