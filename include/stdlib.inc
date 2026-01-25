%ifndef STDLIB_INC
%define STDLIB_INC

%include "include/builtin.inc"

;-------------------------------------------------------------------------------
; Macro prototype: uint16_t get_cursor()
;-------------------------------------------------------------------------------
extern_lib get_cursor
%define get_cursor(...) call_lib get_cursor

;-------------------------------------------------------------------------------
; Macro prototype: uint16_t get_cursor_ex()
;-------------------------------------------------------------------------------
extern_lib get_cursor_ex
%define get_cursor_ex(...) call_lib get_cursor_ex

;-------------------------------------------------------------------------------
; Macro prototype: void set_cursor(uint8_t high, uint8_t low)
;-------------------------------------------------------------------------------
extern_lib set_cursor

%macro set_cursor 2
    ; Push 1-byte low argument.
    push_8 %2

    ; Push 1-byte high argument.
    push_8 %1

    ; Call function and restore stack.
    call_lib set_cursor
    add esp, dword 1 + 1
%endmacro

%define set_cursor(high, low) set_cursor high, low

;-------------------------------------------------------------------------------
; Macro prototype: void set_cursor_ex(uint8_t row, uint8_t col)
;-------------------------------------------------------------------------------
extern_lib set_cursor_ex

%macro set_cursor_ex 2
    ; Push 1-byte col argument.
    push_8 %2

    ; Push 1-byte row argument.
    push_8 %1

    ; Call function and restore stack.
    call_lib set_cursor_ex
    add esp, dword 1 + 1
%endmacro

%define set_cursor_ex(row, col) set_cursor_ex row, col

;-------------------------------------------------------------------------------
; Macro prototype: void roll_screen(uint8_t count)
;-------------------------------------------------------------------------------
extern_lib roll_screen

%macro roll_screen 1
    ; Push 1-byte count argument.
    push_8 %1

    ; Call function and restore stack.
    call_lib roll_screen
    add esp, dword 1
%endmacro

%define roll_screen(count) roll_screen count

;-------------------------------------------------------------------------------
; Macro prototype: void set_text_attr(bool_t blink, uint8_t bg_color, uint8_t fg_color)
;-------------------------------------------------------------------------------
extern CHAR_ATTR
extern_lib set_text_attr

; Black | Gray.
BLACK equ 000b
GRAY equ 1000b

; Blue | Light blue.
BLUE  equ 001b
LIGHT_BULE equ 1001b

; Green | Light green.
GREEN equ 010b
LIGHT_GREEN equ 1010b

; Cyan | Light cyan.
CYAN equ 011b
LIGHT_CYAN equ 1011b

; Red | Light red.
RED equ 100b
LIGHT_RED equ 1100b

; Magenta | Light magenta.
MAGENTA equ 101b
LIGHT_MAGENTA equ 1101b

; Brown | Yellow.
BROWN equ 110b
YELLOW equ 1110b

; White | Bright white.
WHITE equ 111b
LIGHT_WHITE equ 1111b

%macro set_text_attr 3
    mov [CHAR_ATTR], byte %1 << 7 | %2 << 4 | %3 
%endmacro

%define set_text_attr(blink, bg_color, fg_color) set_text_attr blink, bg_color, fg_color

%endif
