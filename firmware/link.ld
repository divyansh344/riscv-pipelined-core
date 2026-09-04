OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* Instruction memory: 4KB at 0x0 */
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    
    /* Data memory: 4KB artificially mapped to 0x10000000 for GCC */
    DMEM (rw) : ORIGIN = 0x10000000, LENGTH = 4K
}

SECTIONS
{
    /* Code goes to IMEM */
    .text :
    {
        *(.text.init) /* Make sure crt0.S comes first */
        *(.text*)
        *(.rodata*)
    } > IMEM

    /* Initialized data goes to DMEM */
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data*)
        _edata = .;
    } > DMEM AT > IMEM /* Load address is in IMEM, we won't actually use standard data copy for now */

    /* Uninitialized data (BSS) goes to DMEM */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > DMEM

    /* Stack is placed at the very end of DMEM */
    PROVIDE(_stack_top = ORIGIN(DMEM) + LENGTH(DMEM));
}
