%include "include/list.inc"
%include "include/string.inc"
%include "include/stdio.inc"

%include "include/memory.inc"
%include "include/thread.inc"

; %define SHOW_THREAD_INFO

section .data
    global thread_ready_list
    
    head  dq 0
    tail  dq 0

    thread_ready_list: istruc List
        at List.Head,   dd head
        at List.Tail,   dd tail
    iend

[bits 32]
section .text
;-------------------------------------------------------------------------------
; Function: get_running_thread
; Description: Get the control block of the running thread.
; Parameters: None.
; Returns: Pointer to the current thread control block.
;-------------------------------------------------------------------------------
global get_running_thread

get_running_thread:
    mov eax, esp
    and eax, 0xfffff000
    ret

;-------------------------------------------------------------------------------
; Function: thread_ctrl_init
; Description: Initialize a thread control block.
; Parameters:
;   - %1: Control block address.
;   - %2: Thread name string (max 15 chars).
;   - %3: Time slice (ticks).
; Returns: None.
;-------------------------------------------------------------------------------
func_lib thread_ctrl_init
    ; Undefine macros to avoid name collisions.
    %undef ctrl
    %undef name
    %undef priority

    ; Declare function arguments.
    arg pointer_t, ctrl
    arg pointer_t, name
    arg uint32_t, priority

    ; Function body.
    mov ebx, ctrl
    memset(ebx, 0, ThreadControl_size)

    ; Copy the thread name into the PCB.
    lea esi, [ebx + ThreadControl.Name]
    strcpy(esi, name)

    ; Set initial state to ready.
    mov [ebx + ThreadControl.Status], dword TASK_READY

    ; Set time slice and counters.
    set_priority: mov edx, priority
    mov [ebx + ThreadControl.Priority], dword edx
    mov [ebx + ThreadControl.Ticks], dword edx
    mov [ebx + ThreadControl.TotalTicks], dword 0

    ; Threads have no page directory; set to NULL.
    mov [ebx + ThreadControl.PageDir], dword NULL

    ; Use one page for the thread stack.
    mov [ebx + ThreadControl.StackTop], ebx
    add [ebx + ThreadControl.StackTop], dword PAGE_SIZE

    ; Guard magic to detect stack overflow.
    mov [ebx + ThreadControl.MagicNum], dword 0x20130427
func_end

;-------------------------------------------------------------------------------
; Function: thread_start
; Description: Create and start a new thread.
; Parameters:
;   - %1: Thread entry function.
;   - %2: Thread name.
;   - %3: Time slice (ticks).
;   - %4: Thread argument pointer.
; Returns: New thread control block.
;-------------------------------------------------------------------------------
thread_exit:
    cli
    call get_running_thread
    mov ebx, eax
    jmp when_thread_died

func_lib thread_start
    ; Undefine macros to avoid name collisions.
    %undef function
    %undef name
    %undef priority
    %undef func_arg

    ; Declare function arguments.
    arg pointer_t, function
    arg pointer_t, name
    arg uint32_t, priority
    arg pointer_t, func_arg

    ; Allocate one page for TCB and stack.
    get_kernel_pages(1)
    mov ebx, eax
    thread_ctrl_init(ebx, name, priority)
    
    ; Push argument and return address onto the stack.
    mov esp, [ebx + ThreadControl.StackTop]

    push dword func_arg
    push dword thread_exit

    ; Push interrupt return frame.
    pushfd
    push dword cs
    push dword function

    ; Push segment registers.
    push ds
    push es
    push fs
    push gs
    push ss

    ; Push general registers.
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0
    push dword 0

    ; Save the current stack top.
    mov [ebx + ThreadControl.StackTop], esp
    
    ; Insert the thread into the ready list.
    lea esi, [ebx + ThreadControl.SignElem]
    list_append(thread_ready_list, esi)

    %ifdef SHOW_THREAD_INFO
        printf("\n--------------------------------\n")
        printf("Start Thread: %s\nMalloc Page Addr: %p", name, ebx)
        printf("\n--------------------------------\n")
    %endif

    return_32 ebx
func_end


;-------------------------------------------------------------------------------
; Function: thread_schedule
; Description: Run the scheduler.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
global thread_schedule

thread_schedule:
    cli ; Disable interrupts to avoid preemption during scheduling.

    ; Handle the current thread state before switching.
    call get_running_thread
    mov ebx, eax

    cmp [ebx + ThreadControl.Status], dword TASK_RUNNING
    je when_thread_running

    cmp [ebx + ThreadControl.Status], dword TASK_READY
    je when_thread_ready
    
    cmp [ebx + ThreadControl.Status], dword TASK_BLOCKED
    je when_thread_block

    cmp [ebx + ThreadControl.Status], dword TASK_WAITING
    je when_thread_block

    cmp [ebx + ThreadControl.Status], dword TASK_HANGING
    je when_thread_block

    cmp [ebx + ThreadControl.Status], dword TASK_DIED
    je when_thread_died

    ; Switch to the next thread.
    enter_next_thread:
        list_is_empty(thread_ready_list)
        cmp eax, TRUE
        je ready_thread_empty

        list_pop(thread_ready_list)
        lea ebx, [eax - ThreadControl.SignElem]
        mov esp, [ebx + ThreadControl.StackTop]
        jmp thread_schedule

    ready_thread_empty:
        panic("thread_ready_list is empty")

    ; NOTE: Time slice expired; refresh ticks and re-queue the thread.
    when_thread_running:
        mov edx, [ebx + ThreadControl.Priority]
        mov [ebx + ThreadControl.Ticks], edx

        mov [ebx + ThreadControl.Status], dword TASK_READY
        
        lea edx, [ebx + ThreadControl.SignElem]
        list_append(thread_ready_list, edx)
        jmp enter_next_thread

    ; Thread is ready; restore context and run.
    when_thread_ready:
        mov [ebx + ThreadControl.Status], dword TASK_RUNNING
        
        popad
        pop ss
        pop gs
        pop fs
        pop es
        pop ds
        iret    ; Automatically restore flags and return to execution.

    ; Thread is blocked; move to the next thread.
    when_thread_block:
        jmp enter_next_thread
    
    ; Thread finished; free its page and schedule the next one.
    when_thread_died:
        %ifdef SHOW_THREAD_INFO
            lea edx, [ebx + ThreadControl.Name]

            printf("\n--------------------------------\n")
            printf("Exit Thread: %s\nFree Page Addr: %p", edx, ebx)
            printf("\n--------------------------------\n")
        %endif

        ; NOTE: Switch stacks before freeing the current one.
        mov edx, ebx

        list_pop(thread_ready_list)
        lea ebx, [eax - ThreadControl.SignElem]
        mov esp, [ebx + ThreadControl.StackTop]

        free_kernel_pages(edx, 1)
        jmp thread_schedule

;-------------------------------------------------------------------------------
; Function: thread_init
; Description: Initialize threading and scheduling.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
global thread_init

thread_init:
    ; Capture the caller return address.
    pop edi

    ; Allocate one page for the main thread.
    get_kernel_pages(1)
    mov ebx, eax
    thread_ctrl_init(ebx, "_start", 30)

    ; Initialize the main thread stack.
    mov [ebx + ThreadControl.Status], dword TASK_RUNNING
    mov esp, [ebx + ThreadControl.StackTop]

    ; Push interrupt return frame.
    push dword 0x286
    push dword cs
    push dword edi

    ; Push segment registers.
    push ds
    push es
    push fs
    push gs
    push ss

    ; Push general registers.
    sub esp, 4 * 8

    ; EBP = ebx + PAGE_SIZE.
    mov [esp + 8], ebx  
    add [esp + 8], dword PAGE_SIZE

    ; Enter the scheduler.
    mov [ebx + ThreadControl.StackTop], esp

    list_clear(thread_ready_list)
    call thread_schedule

;-------------------------------------------------------------------------------
; Function: thread_block
; Description: Block the current thread and set its state.
; Parameters:
;   - %1: Thread state.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib thread_block
    ; Undefine macros to avoid name collisions.
    %undef stat

    ; Declare function arguments.
    arg pointer_t, stat

    ; Function body.
    intr_disable

    mov edx, stat
    call get_running_thread
    mov [eax+ThreadControl.Status], edx
    call thread_schedule

    intr_recover
func_end

;-------------------------------------------------------------------------------
; Function: thread_unblock
; Description: Unblock a thread and add it to the ready list.
; Parameters:
;   - %1: Thread control block pointer.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib thread_unblock
    ; Undefine macros to avoid name collisions.
    %undef pthread
    
    ; Declare function arguments.
    arg pointer_t, pthread

    ; Function body.
    intr_disable

    list_exist(thread_ready_list, [ebx+ThreadControl.SignElem])
    cmp eax, FALSE
    je unblock_continue
    panic("thread_unblock: blocked thread in thread_ready_list")
    
    unblock_continue:
        mov ebx, pthread
        list_push(thread_ready_list, [ebx+ThreadControl.SignElem])
        mov [ebx+ThreadControl.Status], dword TASK_READY

    intr_recover
func_end
