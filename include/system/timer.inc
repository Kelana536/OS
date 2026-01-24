%ifndef TIMER_INC
%define TIMER_INC

; Target interrupt frequency (100 Hz).
IRQ0_FREQUENCY equ 100

; Input frequency for counter 0.
INPUT_FREQUENCY equ 1193180

; Initial counter value to program.
COUNTER0_VALUE equ (INPUT_FREQUENCY / IRQ0_FREQUENCY)

; Port for counter 0.
CONTRER0_PORT equ 0x40

; Counter number to operate.
COUNTER0_NO equ 0

; Mode number for the control word (rate generator).
COUNTER_MODE equ 2

; Control-word RW/LATCH field (low byte then high byte).
READ_WRITE_LATCH equ 3   

; Control-word register port.
PIT_CONTROL_PORT equ 0x43

; 8259A master/slave PIC ports.
PIC_M_CTRL equ 0x20
PIC_M_DATA equ 0x21
PIC_S_CTRL equ 0xA0
PIC_S_DATA equ 0xA1

%endif