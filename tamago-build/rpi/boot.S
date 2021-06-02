    .global _boot

    .text
_boot:
    LDR r1, addr
    BX r1

addr:
    .word ENTRY_POINT
