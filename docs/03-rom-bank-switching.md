# 512 KiB ROM bank switching

The external U2 ROM is divided into sixty-four 8 KiB banks. One bank at a time appears in the TMS9900 cartridge window `>6000–>7FFF`.

This subsystem is independent of the ATmega/UberGROM subsystem.

## Mapper used by this board

The UberGROM/512K ROM-GROM board uses a **non-inverted 74LS378 address-selected mapper**.

The 74LS378 receives six bank bits from TI address lines A09–A14 and drives U2 address lines A13–A18.

## Bank select

For bank *n* (`0–63`), the bank select is:

```text
bank_select = >6000 + (bank × 2)
```

Equivalent calculation when examining a bank-select write:

```text
bank = (write_address - >6000) / 2
```

| Bank | Bank select | U2 file offset |
|---:|---:|---:|
| 0 | `>6000` | `>00000–>01FFF` |
| 1 | `>6002` | `>02000–>03FFF` |
| 2 | `>6004` | `>04000–>05FFF` |
| 3 | `>6006` | `>06000–>07FFF` |
| ... | ... | ... |
| 63 | `>607E` | `>7E000–>7FFFF` |

### The written data value is immaterial

The bank bits come from the **write address**, not the data bus value.

```asm
       CLR  @>6000          ; bank select 0
       CLR  @>6002          ; bank select 1
       CLR  @>6004          ; bank select 2
       CLR  @>6006          ; bank select 3
```

`CLR` is conventional because it conveniently performs the write. The zero it writes has **no special banking meaning**.

## The entire 8 KiB window changes immediately

A bank-select write replaces the complete `>6000–>7FFF` CPU window as the write occurs.

If execution is currently in ROM, the instruction after the bank-select write is fetched from the **new** bank at the same CPU address.

A safe transition therefore normally uses one of these approaches:

1. execute the bank-select write from scratchpad/expansion RAM; or
2. arrange the transition so the instruction fetched immediately after the bank-select write is valid at the same address in the destination bank.

## Scratchpad RAM trampoline

The cleanest general-purpose method is to let the assembler produce the instructions normally, then copy the short routine into scratchpad RAM. This avoids hard-coding TMS9900 opcodes in the documentation and can be extended if a larger transition routine is needed.

```asm
BANKRAM EQU >8320

* Copy TRAMP into scratchpad RAM at BANKRAM.
INSTALL
       LI   R0,TRAMP
       LI   R1,BANKRAM
INLP
       MOV  *R0+,*R1+
       CI   R0,TRAMPEND
       JNE  INLP
       B    *R11

* This function is copied to scratchpad.
* On entry:
*   R1 = bank select (>6000, >6002, ... >607E)
*   R2 = destination address in the new bank
TRAMP
       CLR  *R1
       B    *R2
TRAMPEND
```

After `INSTALL` has run, a call such as:

```asm
       LI   R1,>6004        ; select bank 2
       LI   R2,BANK2ENTRY
       B    @BANKRAM
```

performs the bank select while executing from RAM and then branches into the newly visible bank.

Keep the scratchpad routine short and be mindful of other software using scratchpad RAM.

## Startup state: undefined by specification, measurable in practice

The 74LS378 provides **no guaranteed power-up bank state**. A released cartridge must therefore work without assuming that bank 0, the last bank, or any other particular bank will be selected after power-on.

At the same time, the startup state of an **individual cartridge** can be observed and is useful for testing and troubleshooting. Tursi's [BankTest](https://github.com/tursilion/banktest) utility exercises all cartridge banks; version 2 and later places an asterisk (`*`) next to the bank it detected at initial power-up.

In practical experience with these cartridge boards, the first or last ROM bank is commonly observed at cold power-up. Treat that only as an empirical observation about tested hardware—not as a guaranteed characteristic of the 74LS378.

A reliable cartridge still establishes a known ROM bank by design.

## ROM-only startup: put a header in every bank

For a ROM-only cartridge, the simplest reliable rule is: **put a valid cartridge header/startup entry in every possible bank**.

The startup entry should be at the same address in each bank, and its **first instruction should select the canonical bank**. Because the complete cartridge window changes immediately, the *next* instruction is then fetched from the canonical bank. This minimizes how much code must be duplicated.

For example, if bank 0 is canonical:

```asm
       AORG >6000

HEADER BYTE >AA,>01,>01,>00
       DATA >0000
       DATA PROGLIST
       DATA >0000
       DATA >0000
       DATA >0000,>0000

PROGLIST
       DATA >0000
       DATA KICKSTART
       BYTE 8
       TEXT 'MY CART '
       EVEN

* KICKSTART must begin at the same address in every bank.
KICKSTART
       CLR  @>6000          ; FIRST instruction: select canonical bank 0

* Everything after this point is fetched from bank 0.
       LWPI >8300
       LIMI 0
       B    @MAIN
```

Every bank needs enough valid header/menu data to reach `KICKSTART`, and `KICKSTART` must begin at the same address. Once the first instruction selects bank 0, the remainder does not need to be duplicated in every bank.

### Advanced header-space note

The conventional header above is intentionally clean and readable. Developers trying to recover a few bytes can exploit the fact that the console does not use every header field in every cartridge configuration; for example, unused DSR/subprogram-list fields may be repurposed as data. That is a space-saving technique, not the recommended documentation baseline—use a normal header unless the saved bytes matter.

## ROM/GROM startup: GROM power-up link

Because this board also supports GROM, a ROM/GROM cartridge can use a **GPL/GROM power-up link** to establish the desired ROM bank during the console's GROM power-up processing. This avoids relying on whatever state the 74LS378 happened to have when the ROM scan occurs.

Conceptually, the GPL power-up code performs a store to the desired ROM bank select (for bank 0, the `>6000` bank select) before ROM code relies on that bank.

The exact GPL source syntax should be assembled and tested before being presented as a copy-and-paste reference example; see the validation ledger for that pending example.

## QUIT does not reset the 74LS378

`QUIT` is a **software reset**. It does not reset the 74LS378 latch, so the cartridge can remain in whichever bank software selected most recently.

This is also why BankTest's `*` startup-bank indication is meaningful only immediately after an actual power cycle. Once any program changes banks, a subsequent software reset does not recreate the original cold-power latch state.

Design for both cold power-up and later re-entry from the console:

- ROM-only cartridges should be able to reach the canonical-bank instruction from every bank; and/or
- ROM/GROM cartridges can use the GROM power-up path to establish the desired bank.

## Building the U2 image

Each ROM bank is an 8192-byte image assembled for CPU addresses `>6000–>7FFF`.

For this **non-inverted** board, concatenate banks in ascending order:

```text
bank00.bin + bank01.bin + ... + bank63.bin = cartridge-512k.bin
```

Physical file layout:

```text
bank 0   >00000–>01FFF
bank 1   >02000–>03FFF
...
bank 63  >7E000–>7FFFF
```

For a 16 KiB program:

```text
bank 0 = first 8 KiB
bank 1 = second 8 KiB
```

### Pad unused ROM space with `>FF`

When a bank or full 512 KiB image contains unused space, prefer `>FF` padding rather than `>00`.

Erased Flash already reads as `>FF`, so an external programmer does not need to program those bytes. This makes programming faster and avoids unnecessary program operations. Do not silently reorder banks while padding.

## Cross-bank targets

A cross-bank destination consists of two pieces of information:

```text
(bank number, CPU address in >6000–>7FFF)
```

There is no assumption here that a TI linker will manage that relationship automatically. Many multi-bank programs simply track these targets explicitly in source.

Practical approaches include:

- fixed entry addresses that are deliberately kept stable;
- a hand-maintained equate/include file containing bank numbers and addresses; or
- a generated equate file if your build system already has a tool for producing one.

Generated symbol tables and full dependent-bank rebuild schemes are **optional build conveniences**, not requirements of the cartridge hardware. The essential rule is only that the caller use the correct bank select and the correct CPU address for the version of the destination code being built.

## Inverted-image warning

Older 74LS379 boards used inverted bank outputs. Their **8 KiB bank order** may be reversed relative to this board.

Conversion means reversing the sequence of 8 KiB banks. Do **not** reverse the bytes or bits inside each bank.
