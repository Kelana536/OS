%include "include/stdio.inc"
%include "include/thread.inc"
%include "include/system/timer.inc"

[bits 32]
;-------------------------------------------------------------------------------
; Function: timer_intr_entry
; Description: Entry for the 0x20 timer interrupt.
; NOTE: This interrupt does not push an error code.
;-------------------------------------------------------------------------------
timer_intr_entry:
    push ds
    push es
    push fs
    push gs
    push ss
    pushad

    ; Send EOI to the PIC.
    mov al,0x20
    out 0xa0,al
    out 0x20,al

    ; Get the current running thread.
    call get_running_thread
    mov ebx, eax

    ; Check if the current time slice expired.
    cmp [ebx + ThreadControl.Ticks], dword 0
    jg time_intr_exit

    ; Schedule the next thread.
    mov [ebx + ThreadControl.StackTop], esp
    call thread_schedule

time_intr_exit:
    inc dword [ebx + ThreadControl.TotalTicks]
    dec dword [ebx + ThreadControl.Ticks]

    popad
    pop ss
    pop gs
    pop fs
    pop es
    pop ds
    iret

;-------------------------------------------------------------------------------
; Function: timer_init
; Description: Initialize the timer interrupt.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
extern intr_entry_table

func timer_init
    ; Write PIT control word to port 0x43.
    mov al, (COUNTER0_NO << 6 | READ_WRITE_LATCH << 4 | COUNTER_MODE << 1)
    out PIT_CONTROL_PORT, al

    ; Write low 8 bits of COUNTER0_VALUE.
    mov eax, COUNTER0_VALUE
    out CONTRER0_PORT, al

    ; Write high 8 bits of COUNTER0_VALUE.
    shr eax, 8
    out CONTRER0_PORT, al

    ; Register timer_intr_entry in intr_entry_table.
    mov [intr_entry_table + 0x20 * 4], dword timer_intr_entry
func_end
