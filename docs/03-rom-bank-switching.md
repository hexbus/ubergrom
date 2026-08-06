# 512 KiB ROM bank switching

The separate cartridge ROM flash is divided into sixty-four 8 KiB banks. One bank at a time appears in the TMS9900 cartridge window `>6000–>7FFF`.

## Scope: this is the UberGROM board's mapper

The banking rules in this chapter apply to the UberGROM/512K ROM-GROM board's non-inverted 74LS378 mapper. They are not a universal TI cartridge-banking convention. In particular, do not use these rules for the Gigacart: that is a different mapper, and the data value written is part of its bank-selection protocol.

## Non-inverted 74LS378 scheme

The latch receives six bank bits from TI address lines A09–A14 and drives flash address lines A13–A18. The bank selected by a write is:

```text
bank = (write_address - >6000) / 2
```

The canonical bank-select address is:

```text
select_address = >6000 + (bank × 2)
```

| Bank | Select address | Flash offset |
|---:|---:|---:|
| 0 | `>6000` | `>00000–>01FFF` |
| 1 | `>6002` | `>02000–>03FFF` |
| 2 | `>6004` | `>04000–>05FFF` |
| 3 | `>6006` | `>06000–>07FFF` |
| ... | ... | ... |
| 63 | `>607E` | `>7E000–>7FFFF` |

For this board, the data written does not select the bank; only the write address matters. `CLR` is conventional because it produces the required write with compact source syntax. The zero written by `CLR` has no special meaning to the UberGROM bank latch.

```asm
       CLR  @>6000          ; select bank 0
       CLR  @>6002          ; select bank 1
       CLR  @>6004          ; select bank 2
```

## Why an ordinary switch-and-continue sequence fails

The complete `>6000–>7FFF` window changes as the write completes. If the CPU is executing code from the old bank, its next instruction is fetched from the new bank at the same CPU address.

This is unsafe unless one of the following is true:

1. the switch routine runs from scratchpad or expansion RAM;
2. identical continuation code occupies the same address in both banks; or
3. an identical bank-transition stub is included at the same address in every bank.

## Scratchpad trampoline

The following trampoline is copied to scratchpad RAM once during initialization. The caller supplies a select address in `R1` and destination address in `R2`.

```asm
BANKRAM EQU  >8320

* Generated scratchpad routine:
*   CLR *R1
*   B   *R2

INSTALL_BANKRAM
       LI   R0,>04D1        ; opcode: CLR *R1
       MOV  R0,@BANKRAM
       LI   R0,>0452        ; opcode: B *R2
       MOV  R0,@BANKRAM+2
       RT

* Example: enter BANK2_ENTRY in bank 2
       LI   R1,>6004
       LI   R2,BANK2_ENTRY
       B    @BANKRAM
```

**Review the opcodes with the assembler used by the project.** A safer build-system practice is to assemble the trampoline as normal code, copy its assembled words to scratchpad, and avoid hand-maintained opcode constants.

An alternative trampoline can generate a direct `CLR @xxxx` followed by `B @xxxx`, as shown in the older multi-bank tutorial. That approach consumes more scratchpad words but avoids register-indirect execution.

## Common stub in every bank

A compact convention is to reserve the same final bytes in every bank:

```asm
       AORG >7FFA
PAGER  CLR  @>6000          ; restore canonical bank
       B    *R9             ; continue at address held in R9
```

Every bank must contain identical words at those addresses. The calling convention must document which register carries the destination or return address and which registers the stub destroys.

For larger projects, use one standard transition ABI throughout the cartridge rather than inventing a different switch sequence in each module.

## Cartridge headers and reset state

The 74LS378 does not guarantee a defined bank after power-up. Do not rely on bank 0 being selected on real hardware.

Recommended practice:

- put a valid cartridge header in every bank when space allows;
- make each header enter a small routine at the same address;
- have that routine select the canonical startup bank and branch to the real initializer;
- before returning to the console menu, restore the canonical bank.

If a data bank must use all 8192 bytes, at minimum protect the plausible startup states supported by the target hardware and test multiple physical latch devices. The strongest general-purpose design remains a header in every bank.

## Example startup header pattern

```asm
       AORG >6000

HEADER BYTE >AA,>01,>01,>00
       DATA >0000           ; power-up list
       DATA PROGLIST        ; program list
       DATA >0000           ; DSR list
       DATA >0000           ; subprogram list
       DATA >0000,>0000

PROGLIST
       DATA >0000
       DATA KICKSTART
       BYTE 8
       TEXT 'MY CART '
       EVEN

KICKSTART
       LWPI >8300
       LIMI 0
       LI   R1,>6000        ; canonical bank 0
       LI   R2,MAIN
       B    @BANKRAM        ; trampoline previously available at fixed RAM
```

A real implementation must ensure the trampoline exists before `KICKSTART` calls it. Common solutions are an identical inline transition stub in every bank or a few instructions in each header that install the RAM trampoline first.

## Building the flash image

Each bank is an independent 8192-byte binary assembled for CPU addresses `>6000–>7FFF`. Concatenate banks in ascending order for the non-inverted board:

```text
bank00.bin + bank01.bin + ... + bank63.bin = cartridge-512k.bin
```

Pad unused bytes deliberately, normally with `>00` or `>FF` according to project convention. Do not permit the linker or concatenation tool to silently omit empty banks.

For a 16 KiB program:

```text
bank 0: first 8 KiB
bank 1: second 8 KiB
```

The physical programmer image may be padded or repeated to 512 KiB when a programmer or emulator requires a full-size image, but that is a packaging decision, not a change to the bank-selection logic.

## Cross-bank symbols

A label such as `DRAW_OBJECT` is not sufficient by itself. A cross-bank reference is the pair:

```text
(bank number, CPU address within >6000–>7FFF)
```

Keep exported entry points in a generated symbol table or linker output. Rebuild all dependent banks when an exported address changes. Prefer fixed entry tables or generated equates over hand-copied addresses.

## Inverted-image warning

Older 74LS379 cartridge boards invert the bank outputs. Their physical 8 KiB order may be the reverse of this board. Converting an inverted image to this non-inverted board requires reversing the order of its 8 KiB segments—not reversing bytes or bits inside each segment.
