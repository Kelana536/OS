%include "include/string.inc"
%include "include/bitmap.inc"

;-------------------------------------------------------------------------------
; Function: bitmap_empty
; Description: Clear the bitmap data region.
; Parameters:
;   - %1: Pointer to bitmap.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib bitmap_empty
    arg pointer_t, btmp
    
    mov esi, btmp
    memset([esi + BitMap.BitPointer], 0, [esi + BitMap.ByteSize])
func_end

;-------------------------------------------------------------------------------
; Function: bitmap_get
; Description: Get the state of a bitmap bit.
; Parameters:
;   - %1: Pointer to bitmap.
;   - %2: Bit index.
; Returns: Bit state (0 or 1).
;-------------------------------------------------------------------------------
func_lib bitmap_get
    ; Undefine macros to avoid name collisions.
    %undef btmp

    ; Declare function arguments.
    arg pointer_t, btmp
    arg uint32_t, bit_idx

    ; Declare temporary variables.
    uint32_t byte_idx, 0
    uint8_t bit_odd, 0
    
    ; byte_idx = bit_idx / 8
    ; bit_odd = bit_idx % 8
    mov eax, bit_idx
    mov ebx, 8
    xor edx, edx
    div ebx

    mov byte_idx, eax
    mov bit_odd, dl

    ; Load the byte containing the target bit.
    mov esi, btmp
    mov edi, [esi + BitMap.BitPointer]

    add edi, byte_idx
    mov bl, byte [edi]

    ; Mask out other bits via bit operations.
    mov cl, bit_odd

    mov dl, 1
    shl dl, cl

    and bl, dl

    ; Check whether the masked bit is zero.
    cmp bl, 0
    jz is_zero

    is_one:
        return_8 1

    is_zero:
        return_8 0
func_end

;-------------------------------------------------------------------------------
; Function: bitmap_set
; Description: Set the state of a bitmap bit.
; Parameters:
;   - %1: Pointer to bitmap.
;   - %2: Bit index.
;   - %3: Bit state (0 or 1).
; Returns: None.
;-------------------------------------------------------------------------------
func_lib bitmap_set
    ; Undefine macros to avoid name collisions.
    %undef btmp 
    %undef bit_idx
    %undef byte_idx
    %undef bit_odd
    
    ; Declare function arguments.
    arg pointer_t, btmp
    arg uint32_t, bit_idx
    arg uint8_t, state

    ; Declare temporary variables.
    uint32_t byte_idx, 0
    bool_t bit_odd, FALSE

    ; byte_idx = bit_idx / 8
    ; bit_odd = bit_idx % 8
    mov eax, bit_idx
    mov ebx, 8
    xor edx, edx
    div ebx

    mov byte_idx, eax
    mov bit_odd, dl

    ; Load the byte containing the target bit.
    mov esi, btmp
    mov edi, [esi + BitMap.BitPointer]

    add edi, byte_idx
    mov bl, byte [edi]

    ; Update the target bit via bit operations.
    mov cl, bit_odd
    mov dl, 1
    shl dl, cl

    cmp state, byte FALSE
    je set_free
    
    set_used:
        or bl, dl
        jmp set_end

    set_free:
        not dl
        and bl, dl

    set_end: mov [edi], byte bl
func_end

;-------------------------------------------------------------------------------
; Function: bitmap_scan
; Description: Find a contiguous run of free bits.
; Parameters:
;   - %1: Pointer to bitmap.
;   - %2: Required run length.
; Returns: Start index or -1.
;-------------------------------------------------------------------------------
func_lib bitmap_scan
    ; Undefine macros to avoid name collisions.
    %undef btmp
    %undef bit_idx
    %undef byte_idx
    
    ; Declare function arguments.
    arg pointer_t, btmp
    arg uint32_t, count

    ; Declare temporary variables.
    uint32_t byte_idx, 0
    uint32_t bit_idx, 0

    ; Skip bytes that are fully occupied.
    mov esi, btmp
    mov ecx, [esi + BitMap.ByteSize]
    mov edi, [esi + BitMap.BitPointer]

    is_full_loop:
        mov dl, byte [edi]
        cmp dl, 11111111b
        jne is_byte_free

        inc edi
        inc dword byte_idx

        cmp byte_idx, ecx
        jae is_all_full

        jmp is_full_loop

    is_all_full:
        return_32 -1
    
    is_byte_free:
        mov eax, byte_idx
        shl eax, 3  ; eax * 8
        mov bit_idx, eax
    
    fetch_bits_init:
        uint32_t bit_count, 0
        uint32_t fetch_times, 0
        uint32_t next_idx, bit_idx

        ; fetch_times = btmp.ByteSize * 8 - bit_idx
        mov eax, [esi + BitMap.ByteSize]
        shl eax, 3  ; eax * 8
        sub eax, bit_idx
        mov fetch_times, eax

        mov bit_idx, dword -1
        mov ecx, count
    
    fetch_bits_loop:
        cmp fetch_times, dword 0
        je fetch_bits_done

    ; Call bitmap_get.
        push dword next_idx
        push dword btmp
        call_lib bitmap_get

    ; Non-zero means the bit is occupied.
        cmp eax, 0
        jne bit_used

        inc dword bit_count
        cmp bit_count, ecx
        je bit_enough

        jmp fetch_bits_continue
        
        bit_used:
            mov bit_count, dword 0
            jmp fetch_bits_continue

        bit_enough:
            inc dword next_idx
            sub next_idx, ecx

            mov ecx, next_idx
            mov bit_idx, ecx

            jmp fetch_bits_done

    fetch_bits_continue:
        inc dword next_idx
        dec dword fetch_times
        
        cmp fetch_times, dword 0
        je fetch_bits_done
        jmp fetch_bits_loop

    fetch_bits_done: return_32 bit_idx
func_end