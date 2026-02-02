%include "include/stdio.inc"
%include "include/sync.inc"
%include "include/thread.inc"

;-------------------------------------------------------------------------------
; Function: lock_init
; Description: Initialize a mutex lock.
; Parameters:
;   - %1: Pointer to lock.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib lock_init
    ; Undefine macros to avoid name collisions.
    %undef plock

    ; Declare function arguments.
    arg pointer_t, plock

    ; Function body.
    mov esi, plock

    mov [esi + MutexLock.Holder], dword NULL
    mov [esi + MutexLock.Sema], dword 0
    
    lea edx, [esi + MutexLock.WaiterList]
    list_clear(edx)
func_end

;-------------------------------------------------------------------------------
; Function: lock_acquire
; Description: Acquire a mutex lock.
; Parameters:
;   - %1: Pointer to lock.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib lock_acquire
    ; Undefine macros to avoid name collisions.
    %undef plock

    ; Declare function arguments.
    arg pointer_t, plock

    ; Function body.
    intr_disable
    mov esi, plock
    
    ; Fast path if the current thread already holds the lock.
    call get_running_thread
    mov ebx, eax

    cmp [esi + MutexLock.Holder], ebx
    je inc_sema

    ; Non-zero semaphore means the lock is held.
    cmp [esi + MutexLock.Sema], dword 0
    jne lock_used

    mov [esi + MutexLock.Holder], ebx
    je inc_sema

    ; Block the current thread and enqueue it when lock is held.
    lock_used:
        lea ecx, [esi + MutexLock.WaiterList]
        lea edx, [ebx + ThreadControl.SignElem]
        mov [ebx + ThreadControl.Status], dword TASK_BLOCKED
        list_append(ecx, edx)

        ; Push interrupt return frame.
        pushfd
        push dword cs
        push dword inc_sema

        ; Push segment and general registers.
        push ds
        push es
        push fs
        push gs
        push ss
        pushad

        ; Schedule another thread.
        mov [ebx + ThreadControl.StackTop], esp
        jmp thread_schedule

    inc_sema: inc dword [esi + MutexLock.Sema]
    intr_recover
func_end

;-------------------------------------------------------------------------------
; Function: lock_release
; Description: Release a mutex lock.
; Parameters:
;   - %1: Pointer to lock.
; Returns: None.
;-------------------------------------------------------------------------------
extern thread_ready_list

func_lib lock_release
    ; Undefine macros to avoid name collisions.
    %undef plock

    ; Declare function arguments.
    arg pointer_t, plock

    ; Function body.
    intr_disable
    mov esi, plock
    
    ; Return if current thread does not hold the lock.
    call get_running_thread
    mov ebx, eax

    cmp [esi + MutexLock.Holder], ebx
    je is_hold_thread
    jmp release_end    

    ; If semaphore > 1, the lock is re-entrant and needs multiple releases.
    is_hold_thread:
        cmp [esi + MutexLock.Sema], dword 1
        je lock_free

        dec dword [esi + MutexLock.Sema]
        intr_recover

    lock_free:
        mov [esi + MutexLock.Holder], dword NULL
        mov [esi + MutexLock.Sema], dword 0

    ; Return if the wait list is empty.
    lea ecx, [esi + MutexLock.WaiterList]
    list_is_empty(ecx)

    cmp eax, FALSE
    je have_wait_thread
    jmp release_end

    ; Wake the first waiter and put it on the ready list.
    have_wait_thread:
        ; Save current thread stack frame.
        pushfd
        push dword cs
        push dword release_end

        push ds
        push es
        push fs
        push gs
        push ss
        pushad

        mov [ebx + ThreadControl.StackTop], esp
        
        ; Unblock the waiter and schedule.
        list_pop(ecx)
        lea ebx, [eax - ThreadControl.SignElem]
        mov [esi + MutexLock.Holder], ebx

        mov [ebx + ThreadControl.Status], dword TASK_READY
        list_push(thread_ready_list, eax)
        jmp thread_schedule

    release_end: intr_recover
func_end
