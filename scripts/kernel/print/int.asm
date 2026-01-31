%include "include/stdio.inc"

[bits 32]
;-------------------------------------------------------------------------------
; Function: put_uint
; Description: Print an unsigned decimal integer.
; Parameters:
;   - %1: Value to print.
; Returns: Total number of characters printed.
;-------------------------------------------------------------------------------
func_lib put_uint
    ; Divisor used for decimal conversion.
    uint32_t divisor, 10

    ; Buffer for decimal digits (max 10 chars for 32-bit value).
    uint8_t buffer_end, 0
    local char_t * 10, buffer

    ; Convert by dividing by 10 and printing remainders.
    arg uint32_t, u_num
    mov eax, dword u_num

    lea esi, buffer
    add esi, 10

    uint_fmt_loop:
        dec esi

        mov edx, 0
        idiv dword divisor

        add dl, '0'
        mov [esi], dl

        cmp eax, 0
        jne uint_fmt_loop

    put_str(esi)
func_end

;-------------------------------------------------------------------------------
; Function: put_int
; Description: Print a signed decimal integer.
; Parameters:
;   - %1: Value to print.
; Returns: Total number of characters printed.
;-------------------------------------------------------------------------------
func_lib put_int
    arg int32_t, num
    mov ecx, dword num

    test ecx, 0x80000000
    jnz is_negative
    
    put_uint(ecx)
    return_32 eax

    ; Negative number handling.
    is_negative:
        put_char('-')

        neg ecx
        put_uint(ecx)

        add eax, 1
        return_32 eax
func_end