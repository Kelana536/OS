%include "include/builtin.inc"

[bits 32]

;-------------------------------------------------------------------------------
; Function: get_cursor
; Description: Get the current cursor position.
; Parameters: None.
; Returns: Cursor position.
;-------------------------------------------------------------------------------
func_lib get_cursor
    ; Read the high byte of the cursor position.
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    in al, dx
    mov ah, al

    ; Read the low byte of the cursor position.
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    in al, dx

    return_16 ax
func_end

;-------------------------------------------------------------------------------
; Function: set_cursor
; Description: Set the current cursor position.
; Parameters:
;   - %1: High byte of position.
;   - %2: Low byte of position.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib set_cursor
    arg uint8_t, high
    arg uint8_t, low

    ; Write the high byte of the cursor position.
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    
    mov al, high
    out dx, al

    ; Write the low byte of the cursor position.
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5

    mov al, low
    out dx, al
func_end

;-------------------------------------------------------------------------------
; Function: get_cursor_ex
; Description: Get the current cursor row/column.
; Parameters: None.
; Returns: Cursor row/column.
;-------------------------------------------------------------------------------
func_lib get_cursor_ex
    call_lib get_cursor
    mov dl, 80
    div dl

    mov bh, ah
    mov ah, al
    mov al, bh
    return_16 ax
func_end

;-------------------------------------------------------------------------------
; Function: set_cursor_ex
; Description: Set the current cursor row/column.
; Parameters:
;   - %1: Row.
;   - %2: Column.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib set_cursor_ex
    arg uint8_t, row
    arg uint8_t, col

    cmp row, byte 0
    jl __FUNCEND__

    cmp col, byte 0
    jl __FUNCEND__

    cmp row, byte 24
    jg __FUNCEND__

    cmp col, byte 79
    jg __FUNCEND__

    movzx ax, byte row
    mov dl, 80
    mul dl

    movzx cx, byte col
    add cx, ax

    push_8 cl
    push_8 ch
    call_lib set_cursor
func_end