%include "include/builtin.inc"

[bits 32]
SELECTOR_K_VIDEO equ (0x03 << 3) | 0 | 0

;-------------------------------------------------------------------------------
; Function: roll_screen
; Description: Scroll the console up by the given number of rows.
; Parameters:
;   - %1: Number of rows to scroll (1-25).
; Returns: None.
;-------------------------------------------------------------------------------
func_lib roll_screen
    arg uint8_t, count
    
    mov ax, SELECTOR_K_VIDEO
    mov es, ax

    roll_loop:
        cmp count, byte 0
        je __FUNCEND__

        ; (25-1) * 80 * 2 = 3840 bytes to copy.
        mov edi, 0x00 ; Start of row 0.
        mov esi, 0xa0 ; Start of row 1.

        cpy_loop:
            mov edx, dword [es:esi+ecx]
            mov dword [es:edi+ecx], edx

            add ecx, 4
            cmp ecx, 3840
            jne cpy_loop


        ; Clear the last row.
        mov ebx, 3840
        mov ecx, 80

        cls_loop:
            mov word [es:ebx], 0x0720
            add ebx, 2
            loop cls_loop

        dec byte count
        jmp roll_loop
func_end