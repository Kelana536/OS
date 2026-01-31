%include "include/stdlib.inc"

[bits 32]
SELECTOR_K_VIDEO equ (0x03 << 3) | 0 | 0

section .data
    global CHAR_ATTR
    CHAR_ATTR db 00001111b

;-------------------------------------------------------------------------------
; Function: put_char
; Description: Print a character to the console.
; Parameters:
;   - %1: Character to print.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib put_char
    intr_disable

    ; Skip null characters.
    arg char_t, ascii
    cmp ascii, byte 0x00
    je __FUNCEND__

    ; Get the video memory cell offset into bx.
    get_cursor()
    shl ax, 1
    mov bx, ax

    ; Initialize es to the video segment selector.
    mov ax, SELECTOR_K_VIDEO
    mov es, ax

    ; Handle printable and control characters.
    cmp ascii, byte 0x08
    je ascii_BS
    cmp ascii, byte 0x09
    je ascii_HT
    cmp ascii, byte 0x0A
    je ascii_LF

    call need_roll
    mov dh, [CHAR_ATTR]
    mov dl, ascii

    mov word [es:bx], dx
    add bx, 2
    jmp update_cursor

    ; Backspace control character.
    ascii_BS:
        mov dl, 160
        mov ax, bx
        div dl

        cmp ah, 0
        je update_cursor

        sub bx, 2
        mov word [es:bx], 0x0f20
        jmp update_cursor

    ; Horizontal tab character.
    ascii_HT:
        ; Divide by 160 to get the current row.
        mov dl, 160
        mov ax, bx
        div dl
        mov dl, al

        ; Compute the next row start position.
        mov ax, 160
        add dl, 1
        mul dl
        sub ax, 2

        mov ecx, 4
        HT_loop:
            cmp bx, ax
            je update_cursor

            mov word [es:bx], 0x0f20
            add bx, 2
            loop HT_loop
        
        jmp update_cursor

    ; Line feed control character.
    ascii_LF:
        ; Divide by 160 to get the current row.
        mov dl, 160
        mov ax, bx
        div dl
        mov dl, al

        ; Compute the next row start position.
        mov ax, 160
        add dl, 1
        mul dl
        mov bx, ax

        jmp update_cursor

    ; Check whether scrolling is needed.
    need_roll:
        cmp bx, 4000
        jl is_not_need

        roll_screen(1) ; Scroll by one row.

        mov bx, (24 * 80 + 0)
        set_cursor(bh, bl)
        shl bx, 1

        is_not_need:
            ret

    ; Update the cursor position.
    update_cursor:
        shr bx, 1
        set_cursor(bh, bl)
    
    intr_recover
func_end
