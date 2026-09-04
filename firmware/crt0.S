    .section .text.init
    .global _start

_start:
    /* Initialize the Stack Pointer */
    la sp, _stack_top
    
    /* Optional: We can clear BSS here if needed */
    
    /* Jump to main function */
    jal ra, main
    
    /* Infinite loop if main returns */
_halt:
    beq zero, zero, _halt
