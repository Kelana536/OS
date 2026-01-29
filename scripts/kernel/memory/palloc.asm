%include "include/string.inc"
%include "include/memory.inc"

[bits 32]
section .text
    extern kernel_pool
    extern user_pool
    extern kernel_vaddr

;-------------------------------------------------------------------------------
; Function: vaddr_get
; Description: Allocate virtual pages from the virtual address pool.
; Parameters:
;   - %1: Pool selector.
;   - %2: Number of pages to allocate.
; Returns: Start virtual address on success, NULL on failure.
;-------------------------------------------------------------------------------
func_lib vaddr_get
    arg bool_t,   pflag
    arg uint32_t, pcount

    uint32_t cnt, 0
    uint32_t bit_idx_start, 0

    ; Select the target pool.
    cmp pflag, byte PF_KERNEL
    je kernel_get
    jmp user_get

    ; Allocate from the kernel pool.
    kernel_get:
        mov ecx, pcount
        mov esi, kernel_vaddr + VirtualAddr.BitMap
        bitmap_scan(esi, ecx)

        mov bit_idx_start, eax
        cmp eax, -1
        jne kset_loop
        return_32 NULL

        kset_loop:
            bitmap_set(kernel_vaddr + VirtualAddr.BitMap, eax, TRUE)
            inc eax
            loop kset_loop
        
        mov eax, bit_idx_start
        shl eax, 12 ; bit_idx_start * 4096
        add eax, [kernel_vaddr + VirtualAddr.AddrStart]
        return_32 eax

    
    ; Allocate from the user pool.
    user_get:
        return_32 NULL
func_end

;-------------------------------------------------------------------------------
; Function: palloc
; Description: Allocate one physical page from a pool.
; Parameters:
;   - %1: Pointer to memory pool.
; Returns: Physical frame address on success, NULL on failure.
;-------------------------------------------------------------------------------
func_lib palloc
    arg pointer_t, m_pool

    int32_t bit_idx, 0
    bitmap_scan(m_pool, 1)
    mov bit_idx, eax

    cmp eax, -1
    jne pget_ok
    return_32 NULL

    pget_ok:
        bitmap_set(m_pool, eax, TRUE)

        mov eax, bit_idx
        shl eax, 12 ; bit_idx * 4096

        mov esi, m_pool
        add eax, [esi+MemPool.AddrStart]
        return_32 eax
func_end

;-------------------------------------------------------------------------------
; Function: pde_ptr
; Description: Get the PDE pointer for a virtual address.
; Parameters:
;   - %1: Virtual address.
; Returns: PDE pointer.
;-------------------------------------------------------------------------------
func_lib pde_ptr
    arg uint32_t, vaddr
    mov eax, vaddr

    ; 0xfffff000 + ((vaddr & 0xffc00000) >> 22) * 4)
    and eax, 0xffc00000
    shr eax, 22
    shl eax, 2
    
    add eax, 0xfffff000
    return_32 eax
func_end

;-------------------------------------------------------------------------------
; Function: pte_ptr
; Description: Get the PTE pointer for a virtual address.
; Parameters:
;   - %1: Virtual address.
; Returns: PTE pointer.
;-------------------------------------------------------------------------------
func_lib pte_ptr
    %undef vaddr
    arg uint32_t, vaddr
    mov eax, vaddr
    mov ebx, vaddr

    ; 0xffc00000 + ((vaddr & 0xffc00000) >> 10) + ((vaddr & 0x003ff000) >> 12) * 4
    and ebx, 0xffc00000
    shr ebx, 10

    and eax, 0x003ff000
    shr eax, 12
    shl eax, 2

    add eax, ebx
    add eax, 0xffc00000
    return_32 eax
func_end

;-------------------------------------------------------------------------------
; Function: page_table_add
; Description: Add a virtual-to-physical mapping in the page table.
; Parameters:
;   - %1: Virtual address.
;   - %2: Physical address.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib page_table_add
    arg pointer_t, _vaddr
    arg pointer_t, _paddr

    pde_ptr(_vaddr)
    mov edi, eax

    pte_ptr(_vaddr)
    mov esi, eax

    ; NOTE: Ensure PDE exists before writing PTE.
    mov eax, [edi]
    and eax, 0x00000001
    cmp eax, 1
    je pde_exist
    jmp pde_not_exist

    pde_exist:
        mov eax, _paddr
        or eax, PAGE_US_USER | PAGE_RW_READ_WRITE | PAGE_P
        mov [esi], eax
        jmp __FUNCEND__

    ; PDE missing, allocate the page table first.
    pde_not_exist:
        ; NOTE: Page table frames are allocated from the kernel pool.
        palloc(kernel_pool)
        or eax, PAGE_US_USER | PAGE_RW_READ_WRITE | PAGE_P
        mov [esi], eax

        ; Zero the newly allocated page frame.
        and esi, 0xfffff000
        memset(esi, 0, PAGE_SIZE)
func_end

;-------------------------------------------------------------------------------
; Function: malloc_page
; Description: Allocate a number of pages.
; Parameters:
;   - %1: Pool selector.
;   - %2: Number of pages to allocate.
; Returns: Start virtual address on success, NULL on failure.
;-------------------------------------------------------------------------------
func_lib malloc_page
    %undef pflag
    %undef pcount
    arg bool_t,   pflag
    arg uint32_t, pcount

    ; Allocate virtual addresses from the pool.
    vaddr_get(pflag, pcount)
    uint32_t vaddr_start, eax

    cmp eax, NULL
    jne vget_ok
    return_32 NULL

    vget_ok:
        %undef vaddr
        uint32_t vaddr, eax
    
    ; NOTE: Virtual addresses are contiguous, physical frames may not be.
    mov ecx, pcount
    padd_loop:
        cmp pflag, byte PF_KERNEL
        je kernel_alloc

        user_alloc:
            palloc(user_pool)
            jmp alloc_done

        kernel_alloc:
            palloc(kernel_pool)
        
        alloc_done:
            cmp eax, NULL
            jne alloc_ok
            return_32 NULL

        alloc_ok:
            page_table_add(vaddr, eax)
            add vaddr, dword PAGE_SIZE
        loop padd_loop

    return_32 vaddr_start
func_end

;-------------------------------------------------------------------------------
; Function: get_kernel_pages
; Description: Allocate pages from the kernel pool.
; Parameters:
;   - %1: Number of pages to allocate.
; Returns: Start virtual address on success, NULL on failure.
;-------------------------------------------------------------------------------
func_lib get_kernel_pages
    %undef pcount
    arg uint32_t, pcount

    malloc_page(PF_KERNEL, pcount)
    %undef vaddr
    uint32_t vaddr, eax

    cmp eax, NULL
    je kgp_ret

    mov ecx, pcount
    shl ecx, 12
    memset(vaddr, 0, ecx)

    kgp_ret: return_32 vaddr
func_end

;-------------------------------------------------------------------------------
; Function: free_kernel_pages
; Description: Free pages allocated from the kernel pool.
; Parameters:
;   - %1: Virtual page address.
;   - %2: Number of pages to free.
; Returns: None.
;-------------------------------------------------------------------------------
func_lib free_kernel_pages
    %undef vaddr
    %undef pcount

    arg pointer_t, vaddr
    arg uint32_t, pcount

    mov ecx, pcount
    mov ebx, vaddr

    ; (vaddr & 0x0ffff000) / 4096 - 256
    and ebx, 0x0ffff000
    shr ebx, 12
    sub ebx, 0x100

    free_loop:
    ; Clear the page.
        memset(vaddr, 0, PAGE_SIZE)

    ; Update physical pool bitmap.
        bitmap_set(kernel_pool + MemPool.BitMap, ebx, FALSE)

    ; Update virtual address bitmap.
        bitmap_set(kernel_vaddr + VirtualAddr.BitMap, ebx, FALSE)

        
    ; Remove the virtual-to-physical mapping.
        pte_ptr(vaddr)
        mov [eax], dword 0

    ; Proceed to the next page.
        inc ebx
        add vaddr, dword PAGE_SIZE
        loop free_loop
func_end