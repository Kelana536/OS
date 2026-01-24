%ifndef KEYBOARD_INC
%define KEYBOARD_INC

; 8259A master/slave PIC ports.
PIC_M_CTRL equ 0x20
PIC_M_DATA equ 0x21
PIC_S_CTRL equ 0xA0
PIC_S_DATA equ 0xA1

; Keyboard buffer register port.
KBD_BUF_PORT equ 0x60

; Extended scancode prefix.
EXT_SCANCODE equ 0xe0

; Left Shift make/break codes.
SHIFT_LEFT_MAKE  equ 0x2a
SHIFT_LEFT_BREAK equ 0xaa

; Right Shift make/break codes.
SHIFT_RIGHT_MAKE  equ 0x36
SHIFT_RIGHT_BREAK equ 0xb6

; Alt make/break codes.
ALT_MAKE  equ 0x38
ALT_BREAK equ 0xb8

; Ctrl make/break codes.
CTRL_MAKE  equ 0x1d
CTRL_BREAK equ 0x9d

; Caps Lock make code.
CAPSLOCK  equ 0x3a

; Arrow key make codes.
KEY_UP equ 0x48

KEY_DOWN equ 0x50

KEY_LEFT equ 0x4b

KEY_RIGHT equ 0x4d

%endif