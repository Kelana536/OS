%include "include/memory.inc"

[bits 32]
section .text
    global kernel_pool
    global user_pool
    global kernel_vaddr

section .data
    ; Kernel memory pool.
    kernel_pool: istruc MemPool
        at MemPool.BitMap,      dq 0
        at MemPool.AddrStart,   dd 0
        at MemPool.PoolSize,    dd 0
    iend

    ; User memory pool.
    user_pool: istruc MemPool
        at MemPool.BitMap,      dq 0
        at MemPool.AddrStart,   dd 0
        at MemPool.PoolSize,    dd 0
    iend

    ; Kernel virtual address space.
    kernel_vaddr: istruc VirtualAddr
        at VirtualAddr.BitMap,      dq 0
        at VirtualAddr.AddrStart,   dd 0
    iend

;-------------------------------------------------------------------------------
; Function: mem_pool_init
; Description: Initialize memory pools.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
func mem_pool_init
    ; Physical memory size (matches Bochs megs setting).
    all_mem equ 0x2000000 ; 32MB

    ; Page table size = 256 tables including shared kernel mappings.
    page_table_size equ PAGE_SIZE * 256

    ; Used memory = 1 MB + 256 page tables.
    used_mem equ page_table_size + 0x100000

    ; Free memory = total - used.
    free_mem equ all_mem - used_mem

    ; Convert free memory to page count (page-based allocation).
    all_free_pages equ free_mem / PAGE_SIZE

    ; Split free pages evenly between kernel and user.
    kernel_free_pages equ all_free_pages / 2

    ; Remaining pages go to user space.
    user_free_pages equ all_free_pages - kernel_free_pages
    
    ; NOTE: Remainder is dropped to simplify bitmap bounds.

    ; Kernel pool bitmap length (1 bit per page).
    kbm_length equ kernel_free_pages / 8

    ; User pool bitmap length (1 bit per page).
    ubm_length equ user_free_pages / 8

    ; Kernel pool start address.
    kp_start equ used_mem

    ; User pool start address.
    up_start equ kp_start + kernel_free_pages * PAGE_SIZE

    ; Pool base and size.
    mov [kernel_pool + MemPool.AddrStart], dword kp_start
    mov [kernel_pool + MemPool.PoolSize], dword (kernel_free_pages * PAGE_SIZE)

    mov [user_pool + MemPool.AddrStart], dword up_start
    mov [user_pool + MemPool.PoolSize], dword (user_free_pages * PAGE_SIZE)

    ; Pool bitmaps.
    mov [kernel_pool + BitMap.ByteSize], dword kbm_length
    mov [kernel_pool + BitMap.BitPointer], dword MEM_BITMAP_BASE
    bitmap_empty(kernel_pool + MemPool.BitMap)

    mov [user_pool + BitMap.ByteSize], dword ubm_length
    mov [user_pool + BitMap.BitPointer], dword (MEM_BITMAP_BASE + kbm_length)
    bitmap_empty(user_pool + MemPool.BitMap)

    ; Kernel virtual address bitmap.
    mov [kernel_vaddr + BitMap.ByteSize], dword kbm_length
    mov [kernel_vaddr + BitMap.BitPointer], dword (MEM_BITMAP_BASE + kbm_length + ubm_length)
    mov [kernel_vaddr + VirtualAddr.AddrStart], dword K_HEAP_START
    bitmap_empty(kernel_vaddr + VirtualAddr.BitMap)
func_end

;-------------------------------------------------------------------------------
; Function: mem_init
; Description: Initialize memory management.
; Parameters: None.
; Returns: None.
;-------------------------------------------------------------------------------
func mem_init
    call mem_pool_init
func_end