%include "include/builtin.inc"

[bits 32]
;-------------------------------------------------------------------------------
; Function: memset
; Description: Fill a memory region with a byte value.
; Parameters:
;   - %1: Buffer address.
;   - %2: Byte value.
;   - %3: Length in bytes.
; Returns: Buffer address.
;-------------------------------------------------------------------------------
func_lib memset
    arg pointer_t, buffer
    arg uint8_t, value
    arg uint32_t, setlen

    mov esi, buffer
    mov ecx, setlen

    mov dl, value
    set_loop:
        mov [esi], dl
        inc esi
        loop set_loop
    
    return_32 buffer
func_end

;-------------------------------------------------------------------------------
; Function: memcpy
; Description: Copy one memory region to another.
; Parameters:
;   - %1: Destination address.
;   - %2: Source address.
;   - %3: Length in bytes.
; Returns: Destination address.
;-------------------------------------------------------------------------------
func_lib memcpy
    arg pointer_t, target
    arg pointer_t, source
    arg uint32_t, cpylen

    mov ecx, cpylen
    mov esi, source
    mov edi, target

    cpy_loop:
        mov dl, byte [esi]
        mov byte [edi], dl

        inc esi
        inc edi
        loop cpy_loop

    return_32 target
func_end

;-------------------------------------------------------------------------------
; Function: strcpy
; Description: Copy a source string to a destination.
; Parameters:
;   - %1: Destination string address.
;   - %2: Source string address.
; Returns: Destination string address.
;-------------------------------------------------------------------------------
func_lib strcpy
    ; Undefine macros to avoid name collisions.
    %undef target
    %undef source
    
    arg pointer_t, target
    arg pointer_t, source

    mov esi, source
    mov edi, target

    s_cpy_loop:
        mov dl, [esi]

        cmp dl, NULL
        je s_cpy_ret
        
        mov [edi], byte dl
        
        inc esi
        inc edi
        jmp s_cpy_loop

    s_cpy_ret: return_32 target
func_end

;-------------------------------------------------------------------------------
; Function: strlen
; Description: Compute the length of a string.
; Parameters:
;   - %1: String address.
; Returns: String length.
;-------------------------------------------------------------------------------
func_lib strlen
    ; Undefine macros to avoid name collisions.
    %undef str

    ; Declare function argument.
    arg pointer_t, str

    ; Declare function local variable.
    uint32_t length, 0

    ; Function body.
    mov esi, str

    s_len_loop:
        cmp [esi], byte 0
        je s_len_ret

        inc esi
        inc dword length
        jmp s_len_loop
    
    s_len_ret: return_32 length
func_end
