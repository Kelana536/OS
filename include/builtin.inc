%ifndef BUILTIN_INC
%define BUILTIN_INC

%define DQ_MARK "

;-------------------------------------------------------------------------------
; Macro name: func.
; Description: Start a function and set up the stack frame.
; Inputs:
;   - %1: Function label name.
; Registers modified: ebp, esp.
;-------------------------------------------------------------------------------
%macro func 1
    %assign __RETVALUE__ 0
    %assign __STACK_VAR__ 0
    %assign __STACK_ARG__ 4 * 9

    %define __FUNCNAME__ %1
    %define __FUNCEND__ %1 %+ _end
    %define __FUNCSTR__ DQ_MARK %+ %1 %+ DQ_MARK

    section .text
    global __FUNCNAME__

    __FUNCNAME__:
        pushad
        mov ebp, esp
%endmacro

;-------------------------------------------------------------------------------
; Macro name: func_end.
; Description: End a function, restore the stack frame, and return.
; Inputs: None.
; Registers modified: ebp, esp.
;-------------------------------------------------------------------------------
%macro func_end 0
    __FUNCEND__:
        mov esp, ebp
        
        ; NOTE: Set return value if requested.
        %if __RETVALUE__ == 1
            mov [esp + 28], dword eax
        %endif

        popad
        ret
%endmacro

;-------------------------------------------------------------------------------
; Macro name: return_8/16/32.
; Description: Set eax to the return value and jump to the function end.
; Inputs:
;   - %1: Return value.
; Registers modified: eax.
;-------------------------------------------------------------------------------
%macro return_8 1
    %assign __RETVALUE__ 1

    %ifnum %1
        mov eax, %1
    %else
        movzx eax, byte %1
    %endif
    
    jmp __FUNCEND__
%endmacro

%macro return_16 1
    %assign __RETVALUE__ 1
   
    %ifnum %1
        mov eax, %1
    %else
        movzx eax, word %1
    %endif

    jmp __FUNCEND__
%endmacro

%macro return_32 1
    %assign __RETVALUE__ 1

    %ifnidni %1, eax
        mov eax, dword %1
    %endif
    
    jmp __FUNCEND__
%endmacro

;-------------------------------------------------------------------------------
; Macro name: local.
; Description: Allocate a stack block and bind it to a variable.
; Inputs:
;   - %1: Variable size in bytes.
;   - %2: Variable name.
; Registers modified: esp.
;-------------------------------------------------------------------------------
%macro local 2
    %define uint8_t 1
    %define uint16_t 2
    %define uint32_t 4

    %assign __STACK_VAR__ __STACK_VAR__ - (%1)
    sub esp, dword %1
    %xdefine @%2 ebp %+ __STACK_VAR__
    %xdefine %2 [@%2]

    %undef uint8_t
    %undef uint16_t
    %undef uint32_t
%endmacro

;-------------------------------------------------------------------------------
; Macro name: uint8_t / uint16_t / uint32_t / ...
; Description: Allocate a 1/2/4-byte variable and set a default value.
; Inputs:
;   - %1: Variable name.
;   - %2: Default value.
; Registers modified: esp.
;-------------------------------------------------------------------------------
%macro uint8_t 2
    %assign __STACK_VAR__ __STACK_VAR__ - 1
    %xdefine @%1 ebp %+ __STACK_VAR__
    %xdefine %1 [@%1]
    push_8 %2
%endmacro

%macro uint16_t 2
    %assign __STACK_VAR__ __STACK_VAR__ - 2
    %xdefine @%1 ebp %+ __STACK_VAR__
    %xdefine %1 [@%1]
    push_16 %2
%endmacro

%macro uint32_t 2
    %assign __STACK_VAR__ __STACK_VAR__ - 4
    %xdefine @%1 ebp %+ __STACK_VAR__
    %xdefine %1 [@%1]
    push_32 %2
%endmacro

%xdefine int8_t  uint8_t
%xdefine int16_t uint16_t
%xdefine int32_t uint32_t

%xdefine bool_t    uint8_t
%xdefine char_t    uint8_t
%xdefine pointer_t uint32_t

%xdefine NULL  0 ; Null value.
%xdefine TRUE  1 ; Boolean true.
%xdefine FALSE 0 ; Boolean false.

;-------------------------------------------------------------------------------
; Macro name: arg.
; Description: Declare a stack argument size and name.
; Inputs:
;   - %1: Argument size in bytes.
;   - %2: Argument name.
; Registers modified: esp.
;-------------------------------------------------------------------------------
%macro arg 2
    %define uint8_t 1
    %define uint16_t 2
    %define uint32_t 4

    %xdefine @%2  ebp+ %+ __STACK_ARG__
    %xdefine %2 [@%2]
    %assign __STACK_ARG__ __STACK_ARG__ + %1

    %undef uint8_t
    %undef uint16_t
    %undef uint32_t
%endmacro

;-------------------------------------------------------------------------------
; Macro name: push_8/16/32.
; Description: Push an 8/16/32-bit value to the stack.
; Inputs:
;   - %1: Value to push.
; Registers modified: None.
;-------------------------------------------------------------------------------
%macro push_8 1
    ; Case: immediate value.
    %ifnum %1
        sub esp, dword 1
        mov [esp], byte %1

    ; Case: register value.
    %elifid %1
        sub esp, dword 1
        mov [esp], byte %1
    
    ; Case: variable or argument.
    %else
        sub esp, 1
        push eax
        mov al, byte %1
        mov [esp+4], byte al
        pop eax
    %endif
%endmacro

%macro push_16 1
    push word %1
%endmacro

%macro push_32 1
    ; Case: string literal.
    %ifstr %1
        ; section .data
        ;     %%str db %1, 0
        ; section .text
        ;     push dword %%str
        __pushstr %1
    
    ; Case: label or offset.
    %elifid %1
        %define ebp
            %ifnum %1
                %assign %%offset %1
            %else
                %assign %%offset 0
            %endif
        %undef ebp

        %if %%offset == 0
            push dword %1
        %else
            push dword ebp
            add [esp], dword %%offset
        %endif

    ; Case: other.
    %else
        push dword %1
    
    %endif
%endmacro

;-------------------------------------------------------------------------------
; Macro name: __pushstr.
; Description: Push a global string literal, creating it if missing.
; NOTE: Duplicate detection is handled here to keep call sites simple.
; Inputs:
;   - %1: String literal.
; Registers modified: None.
;-------------------------------------------------------------------------------
%assign __str_count__ 0 ; Count of defined strings.

%macro def_str 2
    %define %1 %2
%endmacro

%macro __pushstr 1
    %assign __str_exist__ 0 ; Track whether the string exists.
    %assign __str_index__ 0 ; Index of existing strings.

    %rep __str_count__
        %ifidn %1, __def_str__ %+ __str_index__
            %assign __str_exist__ 1
        %endif

        %if __str_exist__ == 0
            %assign __str_index__ __str_index__ + 1
        %endif
    %endrep

    %if __str_exist__ == 0
        section .data
            __str__ %+ __str_count__ db %1, 0
        section .text
            push dword __str__ %+ __str_count__
            def_str __def_str__ %+ __str_index__, %1

        %assign __str_count__ __str_count__ + 1
    %else
        push dword __str__ %+ __str_index__
    %endif

%endmacro

;-------------------------------------------------------------------------------
; Macro name: intr_disable.
; Description: Disable interrupts and store state in edi.
; Inputs: None.
; Registers modified: edi.
;-------------------------------------------------------------------------------
%macro intr_disable 0
    pushfd
    pop edi
    cli
%endmacro

;-------------------------------------------------------------------------------
; Macro name: intr_recover.
; Description: Restore interrupt state and jump to function end.
; Inputs: None.
; Registers modified: None.
;-------------------------------------------------------------------------------
%macro intr_recover 0
    bt edi, 9
    jnc __FUNCEND__
    sti
%endmacro

;-------------------------------------------------------------------------------
; Description: Helper macros for declaring and calling library functions.
;-------------------------------------------------------------------------------
%macro func_lib 1
    func lib_%1
%endmacro

%macro call_lib 1
    call lib_%1
%endmacro

%macro extern_lib 1
    extern lib_%1
%endmacro

%endif
