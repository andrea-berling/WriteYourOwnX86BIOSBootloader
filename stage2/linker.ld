SECTIONS
{
    /* The BIOS loads the kernel at 0x1000 */
    . = 0x1000;

    .text :
    {
        *(.text.entry)  /* Ensure main function is first */
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }

    .data :
    {
        *(.data)
    }

    .bss :
    {
        *(.bss)
    }
}
