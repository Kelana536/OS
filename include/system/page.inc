%ifndef PAGE_INC
%define PAGE_INC

; Size of a page.
PAGE_SIZE equ 0x1000

; Physical address of the page directory in two-level paging.
; NOTE: 1M PTEs are grouped into 1K PDEs, each pointing to a page table of 1K PTEs.
PAGE_DIR_PHYS_ADDR equ 0x100000

; Physical address of the first page table in two-level paging.
; NOTE: Each PDE is 4 bytes, so 1K PDEs consume 4 KB after the directory.
PAGE_TABLE_PHYS_ADDR equ PAGE_DIR_PHYS_ADDR + PAGE_SIZE

; P bit for PDE/PTE indicates presence.
; NOTE: P=1 means the page is present in physical memory.
; NOTE: Paging uses P and page-faults to manage virtual memory.
PAGE_P equ 1b

; RW bit for PDE/PTE indicates write access.
; NOTE: RW=1 means read/write, RW=0 means read-only.
PAGE_RW_READ_ONLY  equ 00b
PAGE_RW_READ_WRITE equ 10b

; US bit for PDE/PTE indicates user/supervisor.
; NOTE: US=1 allows user-level access (including ring 3).
; NOTE: US=0 restricts access to rings 0-2.
PAGE_US_SUPERVISOR equ 000b
PAGE_US_USER       equ 100b

%endif