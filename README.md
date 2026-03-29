# Make Your Own BIOS Bootloader Workshop

Welcome to the **"Make Your Own BIOS Bootloader"** workshop! In this session, you will build a legacy BIOS bootloader from scratch using x86 assembly and C.

## 📁 Project Structure

```
bios-workshop/
├── slides/
│   └── slides.typ       # Workshop slides (Typst)
├── stage1/
│   └── boot.asm         # Stage 1 Bootloader (16-bit Assembly)
├── stage2/
│   ├── main.c           # Stage 2 (32-bit C)
│   └── linker.ld        # Linker Script
├── build/               # Build artifacts (created during build)
├── Makefile             # Build automation
└── README.md            # This guide
```

## 🛠️ Prerequisites

You need the following tools installed:

*   **NASM**: The Netwide Assembler
*   **GCC**: The GNU Compiler Collection (cross-compiler for i386 if on non-x86)
*   **QEMU**: To emulate an x86 PC
*   **Make**: To automate the build

### Installation

#### Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install nasm gcc make qemu-system-x86
```

#### Linux (Fedora)
```bash
sudo dnf install nasm gcc make qemu-system-x86
```

#### macOS (Apple Silicon & Intel)
Install via Homebrew:
```bash
brew install nasm make qemu
```
**Important:**
The default `gcc` (clang) cannot produce 32-bit x86 code. You **must** use a cross-compiler:
```bash
brew install x86_64-elf-gcc
```
*Note: You will need to update the `Makefile` to use `x86_64-elf-gcc` and `x86_64-elf-ld` instead of `gcc` and `ld`.*

#### Windows

> **Note:** These instructions are provided as a "best effort" guide. As the author does not use Windows, consider this a homework exercise to figure out the exact details! :)

**Recommended: MSYS2**

[MSYS2](https://www.msys2.org/) provides a modern Unix-like environment on Windows and is the easiest way to get the required tools.

1.  **Install MSYS2** from the official website.
2.  **Open the MSYS2 UCRT64 terminal** and install the necessary packages:
    ```bash
    pacman -S mingw-w64-ucrt-x86_64-gcc \
              mingw-w64-ucrt-x86_64-nasm \
              mingw-w64-ucrt-x86_64-make \
              mingw-w64-ucrt-x86_64-qemu \
              git
    ```
3.  **Use `mingw32-make`** (installed with the make package) to build and run:
    ```bash
    mingw32-make run
    ```

**Alternative: WSL2**
1.  Install WSL2 (Ubuntu).
2.  Follow the **Linux (Debian/Ubuntu)** instructions above inside the WSL terminal.
3.  *Note:* You will need [WSLg](https://github.com/microsoft/wslg) (standard in Windows 11) or an X server (like VcXsrv) to see the QEMU VGA window. Without a display server, you won't see the VGA output.

## 🚀 Build & Run

To build the project and run it in QEMU:

```bash
make run
```

To just build without running:

```bash
make
```

To clean up build artifacts:

```bash
make clean
```

## 📚 Workshop Guide

### Step 1: The Boot Sector (Stage 1)
The BIOS loads the first 512 bytes of the boot disk to memory address `0x7C00`.
We use `INT 0x10, AX=0x1301` to print strings directly to the screen using BIOS services.
We must:
1.  Set up the stack.
2.  Enable the A20 line (to access memory > 1MB).
3.  Load Stage 2 from the disk into memory.
4.  Switch to Protected Mode (32-bit).

See `stage1/boot.asm`.

### Step 2: The Kernel (Stage 2)
Once in 32-bit Protected Mode, we can use C!
We use a special linker section `.text.entry` to ensure our `main()` function is the first code executed.
We write directly to the VGA video memory at `0xB8000` to display text.

See `stage2/main.c`.

### Step 3: Linking
We need a "flat binary" (no ELF/PE headers) because the BIOS doesn't understand executable formats. We use a linker script to place our code at the correct memory address (`0x1000`).

See `stage2/linker.ld`.
