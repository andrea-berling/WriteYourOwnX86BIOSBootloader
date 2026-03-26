# Makefile for BIOS Bootloader Workshop

# Tools
ASM = nasm
CC = gcc
LD = ld

# Flags
ASMFLAGS = -f bin
# -fno-pie and -fno-stack-protector are crucial for freestanding
CCFLAGS = -m32 -ffreestanding -c -g -Os -Wall -Wextra -fno-pie -fno-stack-protector
LDFLAGS = -m elf_i386 -T stage2/linker.ld --oformat binary

# Sources
BOOT_SRC = stage1/boot.asm
KERNEL_C = stage2/main.c

# Output
BUILD_DIR = build
BOOT_BIN = $(BUILD_DIR)/boot.bin
KERNEL_O = $(BUILD_DIR)/kernel.o
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
OS_IMAGE = $(BUILD_DIR)/os-image.bin

.PHONY: all clean run

all: $(OS_IMAGE)

# 1. Assemble Stage 1 Bootloader (Depends on Kernel to know its size)
$(BOOT_BIN): $(BOOT_SRC) $(KERNEL_BIN)
	@mkdir -p $(BUILD_DIR)
	@KERNEL_SIZE=$$(wc -c < $(KERNEL_BIN)); \
	KERNEL_SECTORS=$$(( (KERNEL_SIZE + 511) / 512 )); \
	echo "Kernel size: $$KERNEL_SIZE bytes ($$KERNEL_SECTORS sectors)"; \
	$(ASM) $(ASMFLAGS) -D KERNEL_SECTORS=$$KERNEL_SECTORS $< -o $@

# 2. Compile C Kernel
$(KERNEL_O): $(KERNEL_C)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CCFLAGS) $< -o $@

# 3. Link Kernel (Stage 2)
# Removed kernel_entry.o as we now use linker script to place main()
$(KERNEL_BIN): $(KERNEL_O)
	$(LD) $(LDFLAGS) -o $@ $^

# 4. Create Disk Image (Concatenate Bootloader + Kernel)
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	cat $^ > $@
	# Pad with zeros to ensure it's a multiple of 512 bytes (one sector)
	@SIZE=$$(wc -c < $@); \
	PAD=$$(( (512 - ($$SIZE % 512)) % 512 )); \
	if [ $$PAD -gt 0 ]; then \
		dd if=/dev/zero bs=1 count=$$PAD >> $@ 2>/dev/null; \
	fi

# Run in QEMU
run: $(OS_IMAGE)
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE)

clean:
	rm -rf $(BUILD_DIR)
