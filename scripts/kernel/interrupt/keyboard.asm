%include "include/ioqueue.inc"
%include "include/stdio.inc"
%include "include/stdlib.inc"
%include "include/system/keyboard.inc"

section .data
    ; Ctrl key pressed state.
    ctrl_status     db 0

    ; Shift key pressed state.
    shift_status    db 0

    ; Alt key pressed state.
    alt_status      db 0

    ; Caps Lock pressed state.
    caps_status     db 0

    ; Scancode-to-ASCII maps.
    map1 db 0, 0, "1234567890-=", 0x08, 0x09, "qwertyuiop[]", 0x0A, 0, "asdfghjkl;'`", 0, "\zxcvbnm,./", 0, 0, 0, ' '
    map2 db 0, 0, "1234567890-=", 0x08, 0x09, "QWERTYUIOP[]", 0x0A, 0, "ASDFGHJKL;'`", 0, "\ZXCVBNM,./", 0, 0, 0, ' '
    map3 db 0, 0, "!@#$%^&*()_+", 0x08, 0x09, "QWERTYUIOP{}", 0x0A, 0, "ASDFGHJKL:", 0x22, '~', 0, "|ZXCVBNM<>?", 0, 0, 0, ' '
    map4 db 0, 0, "!@#$%^&*()_+", 0x08, 0x09, "qwertyuiop{}", 0x0A, 0, "asdfghjkl:", 0x22, '~', 0, "|zxcvbnm<>?", 0, 0, 0, ' '

    ; Keyboard circular buffer.
    global kbd_ioq
    kbd_ioq: istruc IOQueue
        at IOQueue.Head, dd 0
        at IOQueue.Tail, dd 0
        at IOQueue.Lock, dd 0,0,0,0
        at IOQueue.Producer, dd 0
        at IOQueue.Consumer, dd 0
        at IOQueue.Buffer, times BUFSIZE db 0
    iend

section .text
;-------------------------------------------------------------------------------
; Function: keyboard_intr_entry
; Description: Entry for the 0x21 keyboard interrupt.
; NOTE: This interrupt does not push an error code.
;-------------------------------------------------------------------------------
keyboard_intr_entry:
    pushad
    
    ; Send EOI to the PIC.
    mov al,0x20
    out 0xa0,al
    out 0x20,al

    ; Read the keyboard data buffer.
read_code:
    in al, KBD_BUF_PORT
    movzx eax, al

    cmp eax, EXT_SCANCODE
    je keyboard_intr_exit

    cmp eax, SHIFT_LEFT_MAKE
    je is_shift_make

    cmp eax, SHIFT_LEFT_BREAK
    je is_shift_break

    cmp eax, SHIFT_RIGHT_MAKE
    je is_shift_make

    cmp eax, SHIFT_RIGHT_BREAK
    je is_shift_break

    cmp eax, CTRL_MAKE
    je is_ctrl_make

    cmp eax, CTRL_BREAK
    je is_ctrl_break

    cmp eax, ALT_MAKE
    je is_alt_make

    cmp eax, ALT_BREAK
    je is_alt_break

    cmp eax, CAPSLOCK
    je is_caps_lock

    cmp eax, KEY_UP
    je is_key_up

    cmp eax, KEY_DOWN
    je is_key_down

    cmp eax, KEY_LEFT
    je is_key_left

    cmp eax, KEY_RIGHT
    je is_key_right

    jmp write_code
    
    is_shift_make:
        mov [shift_status], byte 1
        jmp keyboard_intr_exit

    is_shift_break:
        mov [shift_status], byte 0
        jmp keyboard_intr_exit

    is_ctrl_make:
        mov [ctrl_status], byte 1
        jmp keyboard_intr_exit

    is_ctrl_break:
        mov [ctrl_status], byte 0
        jmp keyboard_intr_exit

    is_alt_make:
        mov [alt_status], byte 1
        jmp keyboard_intr_exit

    is_alt_break:
        mov [alt_status], byte 0
        jmp keyboard_intr_exit

    is_caps_lock:
        cmp [caps_status], byte 0
        je caps_open
        jmp caps_close

        caps_open:
            mov [caps_status], byte 1
            jmp keyboard_intr_exit

        caps_close:
            mov [caps_status], byte 0
            jmp keyboard_intr_exit

    is_key_up:
        get_cursor_ex()
        sub ah, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    is_key_down:
        get_cursor_ex()
        add ah, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    is_key_left:
        get_cursor_ex()
        sub al, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    is_key_right:
        get_cursor_ex()
        add al, 1
        set_cursor_ex(ah, al)
        jmp keyboard_intr_exit

    ; Emit the character into the queue.
write_code:
    cmp eax, 0x80
    jge keyboard_intr_exit

    cmp [shift_status], byte 1
    je use_map3_or_map4

    cmp [caps_status], byte 1
    je use_map2

    jmp use_map1

    use_map3_or_map4:
        cmp [caps_status], byte 1
        je use_map4
        jmp use_map3

        use_map4:
            lea esi, [eax + map4]
            jmp code_put

        use_map3:
            lea esi, [eax + map3]
            jmp code_put
    
    use_map2:
        lea esi, [eax + map2]
        jmp code_put

    use_map1:
        lea esi, [eax + map1]
    
    code_put: 
        ioq_putchar(kbd_ioq, [esi])
        ; put_char([esi])

    ; Return from interrupt.
keyboard_intr_exit:
    popad
    iret

;-------------------------------------------------------------------------------
; Function: keyboard_init
; Description: Initialize the keyboard interrupt.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
extern intr_entry_table

func keyboard_init
    ; Initialize the buffer.
    ioq_init(kbd_ioq)

    ; Register keyboard_intr_entry in intr_entry_table.
    mov [intr_entry_table + 0x21 * 4], dword keyboard_intr_entry
func_end
