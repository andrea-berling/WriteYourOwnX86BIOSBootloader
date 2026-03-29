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
STAGE2_C = stage2/main.c

# Output
BUILD_DIR = build
STAGE1_BIN = $(BUILD_DIR)/stage1.bin
STAGE2_O = $(BUILD_DIR)/stage2.o
STAGE2_BIN = $(BUILD_DIR)/stage2.bin
OS_IMAGE = $(BUILD_DIR)/os-image.bin

.PHONY: all clean run

all: $(OS_IMAGE)

# 1. Assemble Stage 1 Bootloader (Depends on stage 2 to know its size)
$(STAGE1_BIN): $(BOOT_SRC) $(STAGE2_BIN)
	@mkdir -p $(BUILD_DIR)
	@STAGE2_SIZE=$$(wc -c < $(STAGE2_BIN)); \
	STAGE2_SECTORS=$$(( (STAGE2_SIZE + 511) / 512 )); \
	echo "stage2 size: $$STAGE2_SIZE bytes ($$STAGE2_SECTORS sectors)"; \
	$(ASM) $(ASMFLAGS) -D STAGE2_SECTORS=$$STAGE2_SECTORS $< -o $@

# 2. Compile C stage2
$(STAGE2_O): $(STAGE2_C)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CCFLAGS) $< -o $@

# 3. Link stage2 (Stage 2)
$(STAGE2_BIN): $(STAGE2_O)
	$(LD) $(LDFLAGS) -o $@ $^

# 4. Create Disk Image (Concatenate Bootloader + stage2)
$(OS_IMAGE): $(STAGE1_BIN) $(STAGE2_BIN)
	cat $^ > $@
	# Pad with zeros to ensure it's a multiple of 512 bytes (one sector)
	@SIZE=$$(wc -c < $@); \
	PAD=$$(( (512 - ($$SIZE % 512)) % 512 )); \
	if [ $$PAD -gt 0 ]; then \
		dd if=/dev/zero bs=1 count=$$PAD >> $@ 2>/dev/null; \
	fi

# Run in QEMU
run: $(OS_IMAGE)
	# Will also work with qemu-system-x86_64
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE)

clean:
	rm -rf $(BUILD_DIR)
