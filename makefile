SHELL := /bin/sh
ld = i686-elf-ld
RM ?= rm -f
.PHONY: clear run

# ---------- Write virtual disk ----------
mbr_bin = builds/boot/mbr.bin
loader_bin = builds/boot/loader.bin
kernel_bin = builds/kernel/kernel.bin

virtual_disk = builds/virtual_disk
$(virtual_disk): $(mbr_bin) $(loader_bin) $(kernel_bin)
	@mkdir -p $(dir $@)
	dd if=$(mbr_bin) of=$(virtual_disk) bs=512 count=1 conv=notrunc
	dd if=$(loader_bin) of=$(virtual_disk) bs=512 count=4 seek=1 conv=notrunc
	dd if=$(kernel_bin) of=$(virtual_disk) bs=512 count=200 seek=5 conv=notrunc

# ---------- Build boot components ----------
mbr_src = scripts/boot/mbr.asm
loader_src = scripts/boot/loader.asm

$(mbr_bin): $(mbr_src)
	@mkdir -p $(dir $@)
	nasm -f bin -o $(mbr_bin) $(mbr_src)

$(loader_bin): $(loader_src)
	@mkdir -p $(dir $@)
	nasm -f bin -o $(loader_bin) $(loader_src)

# ---------- Build kernel components ----------
kernel_srcs := $(wildcard scripts/kernel/*.asm scripts/kernel/**/*.asm)
kernel_objs = $(patsubst scripts/kernel/%.asm,builds/kernel/%.o,$(kernel_srcs))

$(kernel_bin): $(kernel_objs)
	@mkdir -p $(dir $@)
	$(ld) -m elf_i386 -Od -Ttext 0xc0000d00 --oformat binary -o $(kernel_bin) $(kernel_objs)

# ---------- Clean artifacts ----------
clear:
	@$(RM) $(kernel_objs) $(mbr_bin) $(loader_bin) $(kernel_bin) $(virtual_disk) builds/virtual_disk.lock

# ---------- Run ----------
run:
	./run.sh

# Kernel entry objects.
in_dir = scripts/kernel
out_dir = builds/kernel

target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	@mkdir -p $(dir $@)
	nasm -f elf32 -w-all $< -o $@

# Interrupt objects.
in_dir = scripts/kernel/interrupt
out_dir = builds/kernel/interrupt


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	@mkdir -p $(dir $@)
	nasm -f elf32 -w-all $< -o $@

# Memory objects.
in_dir = scripts/kernel/memory
out_dir = builds/kernel/memory


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	@mkdir -p $(dir $@)
	nasm -f elf32 -w-all $< -o $@

# Print objects.
in_dir = scripts/kernel/print
out_dir = builds/kernel/print


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	@mkdir -p $(dir $@)
	nasm -f elf32 -w-all $< -o $@

# Thread objects.
in_dir = scripts/kernel/thread
out_dir = builds/kernel/thread


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	@mkdir -p $(dir $@)
	nasm -f elf32 -w-all $< -o $@

# Utility objects.
in_dir = scripts/kernel/utils
out_dir = builds/kernel/utils


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	@mkdir -p $(dir $@)
	nasm -f elf32 -w-all $< -o $@

# User program objects.
in_dir = scripts/kernel/userprog
out_dir = builds/kernel/userprog


target = $(patsubst $(in_dir)/%.asm,$(out_dir)/%.o,$(wildcard $(in_dir)/*.asm))
$(target): $(out_dir)/%.o: $(in_dir)/%.asm
	nasm -f elf32 -w-all $< -o $@
