#set page(width: 800pt, height: 450pt, margin: 2em)
#set text(size: 20pt)

#let slide(title, body) = {
  pagebreak(weak: true)
  align(center + horizon)[
    #text(size: 1.5em, weight: "bold")[#title]
    #v(1em)
    #align(left)[#body]
  ]
}

#align(center + horizon)[
  #text(size: 3em, weight: "bold")[x86 BIOS Bootloader Workshop]
  
  Build your own bootloader from scratch!
  
  #v(2em)
  _Open Hackerspace Day 2026_
]

#slide("Goal")[
  - Understand how a computer boots (Legacy BIOS)
  - Write x86 Assembly (16-bit Real Mode)
  - Switch to 32-bit Protected Mode
  - Load a C stage2
]

#slide("The Boot Process")[
  1.  *Power On*: CPU initializes.
  2.  *BIOS*: Basic Input/Output System runs POST.
  3.  *Boot Sector*: BIOS looks for bootable device.
  4.  *0x7C00*: BIOS loads first 512 bytes here.
  5.  *Execution*: CPU jumps to 0x7C00.
]

#slide("Real Mode (16-bit)")[
  - Default mode for x86 CPUs on boot (even i9!).
  - *1 MB Addressable Memory* ($2^20$ bytes).
  - No memory protection (can crash system easily).
  - *Segmentation*: `Address = Segment * 16 + Offset`
]

#slide("Registers")[
  - *General*: AX, BX, CX, DX (16-bit).
  - *Segments*: CS (Code), DS (Data), SS (Stack), ES (Extra Data), FS (More Extra Data), GS (Still More Extra Data).
  - *Pointers*: SP (Stack), BP (Base), SI (Source), DI (Dest).
  - *IP*: Instruction Pointer.
]

#slide("BIOS Interrupts")[
  - Functions provided by BIOS.
  - Invoked via `int` instruction.
  - Examples:
    - `int 0x10`: Video Services (Print char, set mode).
    - `int 0x13`: Disk Services (Read/Write sectors).
]

#slide("The A20 Line")[
  - *Legacy Issue*: 8086 addresses wrapped at 1MB.
  - *A20 Gate*: Keyboard controller (or chipset) disables 21st bit.
  - Must *enable* it to access memory above 1MB.
  - Method: Fast A20 (Port 0x92) or Keyboard Controller.
]

#slide("Protected Mode (32-bit)")[
  - Access to 4GB memory.
  - Memory Protection (Ring 0 vs Ring 3).
  - No BIOS interrupts! (Must write own drivers).
  - *GDT* (Global Descriptor Table) defines valid Segments.
]

#slide("Global Descriptor Table (GDT)")[
  - Defines memory segments (Code, Data).
  - Base Address, Limit, Access Flags.
  - Loaded with `lgdt` instruction.
]

#slide("Switching Modes")[
  1.  Disable Interrupts (`cli`).
  2.  Load GDT.
  3.  Set PE bit in `CR0` register.
  4.  Far Jump to flush pipeline (`jmp CODE_SEG:init_pm`).
]

#slide("Workshop Steps")[
  1.  *Stage 1 (ASM)*: Setup, Enable A20, Load Stage 2.
  2.  *Stage 2 (C)*: Print "Hello From Stage 2!" to screen.
  3.  *Linker*: Combine into flat binary.
  4.  *QEMU*: Run it!
]

#align(center + horizon)[
  #text(size: 3em, weight: "bold")[Let's Code!]
]
