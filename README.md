# OS

## A minimal 32-bit x86 operating system written in NASM assembly.

## Installation

```sh
# Clone
git clone https://github.com/Adel-Ayoub/OS.git
cd OS

# Build
make

# Run
./run.sh
```

---

## Requirements

- NASM assembler
- i686-elf-ld (cross-linker)
- Bochs emulator
- Make
- Bash

---

## Features

### Completed Features

#### Boot Process
- MBR Boot Sector: 512-byte master boot record
- Protected Mode: 16-bit to 32-bit mode transition
- GDT Setup: Global Descriptor Table configuration
- Paging: Two-level page table with 4KB pages

#### Memory Management
- Physical Memory Pools: Kernel and user memory pools
- Virtual Address Space: Virtual memory allocation
- Page Allocation: Dynamic page allocation/deallocation
- Bitmap Allocator: Efficient bitmap-based tracking

#### Interrupt Handling
- IDT Setup: Interrupt Descriptor Table initialization
- PIC Configuration: 8259A PIC master/slave setup
- Timer Interrupt: Programmable interval timer (100Hz)
- Keyboard Handler: PS/2 keyboard with scancode mapping

#### Threading
- Thread Control Blocks: Per-thread state management
- Cooperative Scheduler: Round-robin scheduling
- Thread Creation: Dynamic thread spawning
- Mutex Locks: Synchronization primitives

#### Console I/O
- VGA Text Mode: 80x25 character display
- Cursor Control: Hardware cursor positioning
- Printf Implementation: Format string support
- Screen Scrolling: Automatic scroll on overflow

### Planned Features
- User Mode: Ring 3 process execution
- System Calls: Kernel API interface
- File System: Basic filesystem support
- Shell: Interactive command shell

---

## Memory Map

| Address | Size | Description |
|---------|------|-------------|
| `0x00000500` | 2KB | Loader |
| `0x00000D00` | 100KB | Kernel |
| `0x00100000` | 4KB | Page Directory |
| `0x00101000` | 1MB | Page Tables |
| `0xC009A000` | 16KB | Memory Bitmaps |
| `0xC0100000` | - | Kernel Heap |

---

## Build System

| Target | Description |
|--------|-------------|
| `make` | Build virtual disk image |
| `make run` | Build and run in Bochs |
| `make clear` | Remove build artifacts |

---

## Project Structure

```
OS/
├── Makefile
├── run.sh
├── LICENSE
├── README.md
├── include/
│   ├── builtin.inc       # Core macros
│   ├── stdio.inc         # I/O macros
│   ├── stdlib.inc        # Standard library
│   ├── string.inc        # String operations
│   ├── bitmap.inc        # Bitmap structure
│   ├── list.inc          # Linked list
│   ├── memory.inc        # Memory management
│   ├── thread.inc        # Threading
│   ├── sync.inc          # Synchronization
│   ├── ioqueue.inc       # I/O queues
│   └── system/
│       ├── gdt.inc       # GDT definitions
│       ├── idt.inc       # IDT definitions
│       ├── page.inc      # Paging constants
│       ├── tss.inc       # TSS structure
│       ├── timer.inc     # Timer constants
│       ├── keyboard.inc  # Keyboard scancodes
│       └── primary.inc   # Disk I/O ports
└── scripts/
    ├── boot/
    │   ├── mbr.asm       # Master boot record
    │   └── loader.asm    # Protected mode loader
    └── kernel/
        ├── main.asm      # Kernel entry
        ├── interrupt/
        │   ├── init.asm  # IDT/PIC setup
        │   ├── timer.asm # Timer handler
        │   └── keyboard.asm
        ├── memory/
        │   ├── init.asm  # Pool initialization
        │   ├── palloc.asm # Page allocator
        │   └── string.asm # memset, memcpy
        ├── print/
        │   ├── char.asm  # put_char
        │   ├── string.asm # put_str
        │   ├── int.asm   # put_int
        │   ├── hex.asm   # put_hex
        │   ├── format.asm # printf
        │   └── panic.asm # Error handler
        ├── thread/
        │   ├── init.asm  # Scheduler
        │   └── sync.asm  # Mutex locks
        ├── userprog/
        │   └── tss.asm   # TSS setup
        └── utils/
            ├── bitmap.asm
            ├── cursor.asm
            ├── list.asm
            ├── ioqueue.asm
            └── screen.asm
```

---

## Architecture

| Component | Description |
|-----------|-------------|
| Boot | MBR loads loader, loader enables protected mode and paging |
| Memory | Split pools for kernel/user, bitmap allocation |
| Interrupts | Hardware interrupts via 8259A PIC |
| Threading | Preemptive scheduling via timer interrupt |
| I/O | VGA text mode, PS/2 keyboard |

---

## Emulator Configuration

The OS runs in Bochs with the following configuration:
- 32MB RAM
- 60MB virtual disk
- VGA text mode
- PS/2 keyboard

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.
