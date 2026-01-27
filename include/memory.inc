%ifndef MEMORY_INC
%define MEMORY_INC

%include "include/bitmap.inc"
%include "include/system/page.inc"

; Bitmap base address in the 1 MB layout.
; NOTE: Chosen to align to a page boundary near the last usable region.
; NOTE: Reserved size supports up to 512 MB of memory (16 KB bitmap).
MEM_BITMAP_BASE equ 0xc009a000

; Kernel heap start address for dynamic allocation.
; NOTE: Kernel virtual space starts at 0xC0000000, heap begins after it.
K_HEAP_START equ 0xc0100000

; Virtual address structure with bitmap and base.
struc VirtualAddr
    .BitMap:    resd 2   ; Bitmap for virtual address use.
    .AddrStart: resd 1   ; Virtual base address.
endstruc

; Physical memory pool structure for kernel and user pools.
struc MemPool
    .BitMap:    resd 2   ; Pool bitmap.
    .AddrStart: resd 1   ; Pool base address.
    .PoolSize:  resd 1   ; Pool size in bytes.
endstruc

; Pool type flags.
PF_USER equ 0
PF_KERNEL equ 1

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t vaddr_get(bool_t pflag, uint32_t pcount)
;-------------------------------------------------------------------------------
extern_lib vaddr_get

%macro vaddr_get 2
    ; Push 4-byte pcount argument.
    push_32 %2

    ; Push 1-byte pflag argument.
    push_8 %1

    ; Call function and restore stack.
    call_lib vaddr_get
    add esp, dword 1 + 4
%endmacro

%define vaddr_get(pflag, pcount) vaddr_get pflag, pcount

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t palloc(pointer_t m_pool)
;-------------------------------------------------------------------------------
extern_lib palloc

%macro palloc 1
    ; Push 4-byte m_pool argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib palloc
    add esp, dword 4
%endmacro

%define palloc(m_pool) palloc m_pool

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t pde_ptr(uint32_t vaddr)
;-------------------------------------------------------------------------------
extern_lib pde_ptr

%macro pde_ptr 1
    ; Push 4-byte vaddr argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib pde_ptr
    add esp, dword 4
%endmacro

%define pde_ptr(vaddr) pde_ptr vaddr

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t pte_ptr(uint32_t vaddr)
;-------------------------------------------------------------------------------
extern_lib pte_ptr

%macro pte_ptr 1
    ; Push 4-byte vaddr argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib pte_ptr
    add esp, dword 4
%endmacro

%define pte_ptr(vaddr) pte_ptr vaddr

;-------------------------------------------------------------------------------
; Macro prototype: void page_table_add(pointer_t _vaddr, pointer_t _paddr)
;-------------------------------------------------------------------------------
extern_lib page_table_add

%macro page_table_add 2
    ; Push 4-byte _paddr argument.
    push_32 %2

    ; Push 4-byte _vaddr argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib page_table_add
    add esp, dword 4 + 4
%endmacro

%define page_table_add(_vaddr, _paddr) page_table_add _vaddr, _paddr

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t malloc_page(bool_t pflag, uint32_t pcount)
;-------------------------------------------------------------------------------
extern_lib malloc_page

%macro malloc_page 2
    ; Push 4-byte pcount argument.
    push_32 %2

    ; Push 1-byte pflag argument.
    push_8 %1

    ; Call function and restore stack.
    call_lib malloc_page
    add esp, dword 1 + 4
%endmacro

%define malloc_page(pflag, pcount) malloc_page pflag, pcount

;-------------------------------------------------------------------------------
; Macro prototype: pointer_t get_kernel_pages(bint32_t pcount)
;-------------------------------------------------------------------------------
extern_lib get_kernel_pages

%macro get_kernel_pages 1
    ; Push 4-byte pcount argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib get_kernel_pages
    add esp, dword 4
%endmacro

%define get_kernel_pages(pcount) get_kernel_pages pcount

;-------------------------------------------------------------------------------
; Macro prototype: void free_kernel_pages(pointer_t vaddr, uint32_t pcount)
;-------------------------------------------------------------------------------
extern_lib free_kernel_pages

%macro free_kernel_pages 2
    ; Push 4-byte pcount argument.
    push_32 %2

    ; Push 4-byte vaddr argument.
    push_32 %1

    ; Call function and restore stack.
    call_lib free_kernel_pages
    add esp, dword 4 + 4
%endmacro

%define free_kernel_pages(vaddr, pcount) free_kernel_pages vaddr, pcount

%endif