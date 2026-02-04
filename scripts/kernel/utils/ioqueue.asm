%include "include/sync.inc"
%include "include/ioqueue.inc"
%include "include/thread.inc"

;-------------------------------------------------------------------------------
; Function: ioq_init
; Description: Initialize the circular queue.
; Parameters:
;   - %1: Pointer to queue.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib ioq_init
    ; Undefine macros to avoid name collisions.
    %undef ioq
    
    ; Declare function arguments.
    arg pointer_t, ioq
    
    ; Function body.
    mov ebx, ioq

    lea edx, [ebx+IOQueue.Lock]
    lock_init(edx)

    mov [ebx+IOQueue.Producer], dword NULL
    mov [ebx+IOQueue.Consumer], dword NULL

    mov [ebx+IOQueue.Head], dword 0
    mov [ebx+IOQueue.Tail], dword 0
func_end

;-------------------------------------------------------------------------------
; Function: ioq_next_pos
; Description: Get the next index in the buffer.
; Parameters:
;   - %1: Current position.
; Returns: Next position.
;-------------------------------------------------------------------------------
func_lib ioq_next_pos
    ; Undefine macros to avoid name collisions.
    %undef pos

    ; Declare function arguments.
    arg uint32_t, pos

    ; Function body.
    add pos, dword 1
    mov eax, pos
    mov ebx, BUFSIZE

    xor edx, edx
    div ebx
    return_32 edx
func_end

;-------------------------------------------------------------------------------
; Function: ioq_full
; Description: Check whether the queue is full.
; Parameters:
;   - %1: Pointer to queue.
; Returns: TRUE if full, FALSE otherwise.
;-------------------------------------------------------------------------------
func_lib ioq_full
    ; Undefine macros to avoid name collisions.
    %undef ioq

    ; Declare function arguments.
    arg pointer_t, ioq

    ; Function body.
    mov ebx, ioq

    ioq_next_pos([ebx+IOQueue.Head])
    cmp eax, [ebx+IOQueue.Tail]
    jne not_full

    return_8 TRUE
    not_full: return_8 FALSE
func_end

;-------------------------------------------------------------------------------
; Function: ioq_empty
; Description: Check whether the queue is empty.
; Parameters:
;   - %1: Pointer to queue.
; Returns: TRUE if empty, FALSE otherwise.
;-------------------------------------------------------------------------------
func_lib ioq_empty
    ; Undefine macros to avoid name collisions.
    %undef ioq

    ; Declare function arguments.
    arg pointer_t, ioq

    ; Function body.
    mov ebx, ioq

    mov eax, [ebx+IOQueue.Head]
    cmp eax, [ebx+IOQueue.Tail]
    jne not_empty

    return_8 TRUE
    not_empty: return_8 FALSE
func_end

;-------------------------------------------------------------------------------
; Function: ioq_wait
; Description: Block a producer or consumer on this queue.
; Parameters:
;   - %1: Pointer to thread pointer.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib ioq_wait
    ; Undefine macros to avoid name collisions.
    %undef waiter

    ; Declare function arguments.
    arg pointer_t, waiter

    ; Function body.
    mov ebx, waiter
    
    call get_running_thread
    mov [ebx], eax
    thread_block(TASK_BLOCKED)
func_end

;-------------------------------------------------------------------------------
; Function: ioq_wakeup
; Description: Wake a waiting producer or consumer.
; Parameters:
;   - %1: Pointer to thread pointer.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib ioq_wakeup
    ; Undefine macros to avoid name collisions.
    %undef waiter

    ; Declare function arguments.
    arg pointer_t, waiter

    ; Function body.
    mov ebx, waiter
    thread_unblock([ebx])
    mov [ebx], dword NULL
func_end

;-------------------------------------------------------------------------------
; Function: ioq_getchar
; Description: Consumer gets a character from the queue.
; Parameters:
;   - %1: Pointer to queue.
; Returns: ASCII character.
;-------------------------------------------------------------------------------
func_lib ioq_getchar
    ; Undefine macros to avoid name collisions.
    %undef ioq

    ; Declare function arguments.
    arg pointer_t, ioq

    ; Declare function local variable.
    char_t char, 0

    ; Function body.
    mov ebx, ioq

    while_ioq_empty:
        ioq_empty(ebx)
        cmp eax, FALSE
        je ioq_not_empty

        lea edx, [ebx+IOQueue.Lock]
        lea ecx, [ebx+IOQueue.Consumer]

        lock_acquire(edx)
        ioq_wait(ecx)
        lock_release(edx)

        jmp while_ioq_empty

    ioq_not_empty:
        lea ecx, [ebx+IOQueue.Buffer]
        add ecx, [ebx+IOQueue.Tail]
        mov al, [ecx]
        mov char, al

        ioq_next_pos([ebx+IOQueue.Tail])
        mov [ebx+IOQueue.Tail], eax

        cmp [ebx+IOQueue.Producer], dword NULL
        je get_char_ret

        lea ecx, [ebx+IOQueue.Producer]
        ioq_wakeup(ecx)

    get_char_ret:
        return_8 char
func_end

;-------------------------------------------------------------------------------
; Function: ioq_putchar
; Description: Producer writes a character to the queue.
; Parameters:
;   - %1: Pointer to queue.
;   - %2: ASCII character.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib ioq_putchar
    ; Undefine macros to avoid name collisions.
    %undef ioq
    %undef char

    ; Declare function arguments.
    arg pointer_t, ioq
    arg char_t, char

    ; Function body.
    mov ebx, ioq
    
    while_ioq_full:
        ioq_full(ebx)
        cmp eax, FALSE
        je ioq_not_full

        lea edx, [ebx+IOQueue.Lock]
        lea ecx, [ebx+IOQueue.Producer]

        lock_acquire(edx)
        ioq_wait(ecx)
        lock_release(edx)

        jmp while_ioq_full

    ioq_not_full:
        lea ecx, [ebx+IOQueue.Buffer]
        add ecx, [ebx+IOQueue.Head]
        mov al, char
        mov [ecx], al

        ioq_next_pos([ebx+IOQueue.Head])
        mov [ebx+IOQueue.Head], eax

        cmp [ebx+IOQueue.Consumer], dword NULL
        je __FUNCEND__

        lea ecx, [ebx+IOQueue.Consumer]
        ioq_wakeup(ecx)
func_end
