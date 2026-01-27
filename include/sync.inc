%ifndef SYNC_INC
%define SYNC_INC

%include "include/list.inc"

; Mutex lock structure.
struc MutexLock
    .Holder:        resd 1  ; Lock holder.
    .Sema:          resd 1  ; Semaphore counter.
    .WaiterList:    resd 2  ; Waiting list.
endstruc

;-------------------------------------------------------------------------------
; Macro prototype: void lock_init(pointer_t plock)
;-------------------------------------------------------------------------------
extern_lib lock_init

%macro lock_init 1
    ; Push 4-byte plock argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib lock_init
    add esp, dword 4
%endmacro

%define lock_init(plock) lock_init plock

;-------------------------------------------------------------------------------
; Macro prototype: void lock_acquire(pointer_t plock)
;-------------------------------------------------------------------------------
extern_lib lock_acquire

%macro lock_acquire 1
    ; Push 4-byte plock argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib lock_acquire
    add esp, dword 4
%endmacro

%define lock_acquire(plock) lock_acquire plock

;-------------------------------------------------------------------------------
; Macro prototype: void lock_release(pointer_t plock)
;-------------------------------------------------------------------------------
extern_lib lock_release

%macro lock_release 1
    ; Push 4-byte plock argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib lock_release
    add esp, dword 4
%endmacro

%define lock_release(plock) lock_release plock

%endif