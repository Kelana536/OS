%include "include/stdio.inc"
%include "include/stdlib.inc"
%include "include/string.inc"
%include "include/bitmap.inc"
%include "include/list.inc"
%include "include/thread.inc"
%include "include/sync.inc"
%include "include/ioqueue.inc"

[bits 32]
extern idt_init
extern mem_init
extern thread_init
extern tss_init
extern kbd_ioq

func _start
    set_cursor_ex(0, 0)
    call idt_init
    call mem_init
    call thread_init
    call tss_init
    
    thread_start(thread_a, "consumer_a", 31, " A_")
    thread_start(thread_b, "consumer_b", 31, " B_")

    jmp $
func_end


func thread_a
    ; Undefine macro to avoid name collisions.
    %undef prefix

    ; Declare function argument.
    arg pointer_t, prefix

    ; Function body.
    loop_a:
        cli 
        ioq_empty(kbd_ioq)
        cmp eax, TRUE
        je loop_a_end

        put_str(prefix)
        ioq_getchar(kbd_ioq)
        put_char(al)

    loop_a_end:
        sti
        jmp loop_a
func_end

func thread_b
    ; Undefine macro to avoid name collisions.
    %undef prefix

    ; Declare function argument.
    arg pointer_t, prefix

    ; Function body.
    loop_b:
        cli 
        ioq_empty(kbd_ioq)
        cmp eax, TRUE
        je loop_b_end

        put_str(prefix)
        ioq_getchar(kbd_ioq)
        put_char(al)

    loop_b_end:
        sti
        jmp loop_b
func_end

