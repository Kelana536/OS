%ifndef TASK_INC
%define TASK_INC

%include "include/builtin.inc"
%include "include/system/page.inc"

; Thread states.
TASK_RUNNING    equ 0
TASK_READY      equ 1
TASK_BLOCKED    equ 2
TASK_WAITING    equ 3
TASK_HANGING    equ 4
TASK_DIED       equ 5

; Thread control block structure.
struc ThreadControl
    .StackTop:      resd 1      ; Top of the thread stack.
    .Status:        resd 1      ; Current thread state.
    .Priority:      resd 1      ; Time slice per run.
    .Name:          resd 4      ; Thread name buffer.

    .Ticks:         resd 1      ; Remaining ticks in current slice.
    .TotalTicks:    resd 1      ; Total ticks executed.

    .PageDir        resd 1      ; Page directory virtual address.
    .SignElem:      resd 2      ; List element for scheduling.

    .MagicNum:      resd 1      ; Guard magic to detect stack overflow.
endstruc

extern get_running_thread

extern thread_schedule

;-------------------------------------------------------------------------------
; Macro prototype: void thread_ctrl_init(pointer_t ctrl, pointer_t name, uint32_t ticks)
;-------------------------------------------------------------------------------
extern_lib thread_ctrl_init

%macro thread_ctrl_init 3
    ; Push 4-byte ticks argument.
    push_32 %3

    ; Push 4-byte name argument.
    push_32 %2

    ; Push 4-byte ctrl argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib thread_ctrl_init
    add esp, dword 4 + 4 + 4
%endmacro

%define thread_ctrl_init(ctrl, name, ticks) thread_ctrl_init ctrl, name, ticks

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t thread_start(pointer_t function, pointer_t name, pointer_t priority, pointer_t func_arg)
;-------------------------------------------------------------------------------
extern_lib thread_start

%macro thread_start 4
    ; Push 4-byte func_arg argument.
    push_32 %4

    ; Push 4-byte priority argument.
    push_32 %3

    ; Push 4-byte name argument.
    push_32 %2

    ; Push 4-byte function argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib thread_start
    add esp, dword 4 + 4 + 4 + 4
%endmacro

%define thread_start(function, name, priority, func_arg) thread_start function, name, priority, func_arg

;-------------------------------------------------------------------------------
; Macro prototype: void thread_block(uint32_t stat)
;-------------------------------------------------------------------------------
extern_lib thread_block

%macro thread_block 1
    ; Push 4-byte stat argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib thread_block
    add esp, dword 4
%endmacro

%define thread_block(stat) thread_block stat

;-------------------------------------------------------------------------------
; Macro prototype: void thread_unblock(pointer_t pthread)
;-------------------------------------------------------------------------------
extern_lib thread_unblock

%macro thread_unblock 1
    ; Push 4-byte pthread argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib thread_unblock
    add esp, dword 4
%endmacro

%define thread_unblock(pthread) thread_unblock pthread

%endif
