# 512 KiB ROM bank switching

The external U2 ROM is divided into sixty-four 8 KiB banks. One bank at a time appears in the TMS9900 cartridge window `>6000–>7FFF`.

This subsystem is independent of the ATmega/UberGROM subsystem.

## Scope: this board's mapper only

These rules apply to the UberGROM/512K ROM-GROM board's **non-inverted 74LS378 address-selected mapper**.

They are not a universal TI cartridge convention. In particular, the **Gigacart is different**: its mapper also uses the data value written. On this board, the data value is immaterial.

## Selecting a bank

The 74LS378 receives six bank bits from TI address lines A09–A14 and drives U2 address lines A13–A18.

Canonical select address:

```text
select_address = >6000 + (bank × 2)
```

Equivalent bank calculation:

```text
bank = (write_address - >6000) / 2
```

| Bank | Select address | U2 file offset |
|---:|---:|---:|
| 0 | `>6000` | `>00000–>01FFF` |
| 1 | `>6002` | `>02000–>03FFF` |
| 2 | `>6004` | `>04000–>05FFF` |
| 3 | `>6006` | `>06000–>07FFF` |
| ... | ... | ... |
| 63 | `>607E` | `>7E000–>7FFFF` |

### The written data byte/word does not matter

The bank bits come from the **write address**, not the data bus value.

```asm
       CLR  @>6000          ; select bank 0
       CLR  @>6002          ; select bank 1
       CLR  @>6004          ; select bank 2
       CLR  @>6006          ; select bank 3
```

`CLR` is conventional because it conveniently performs a write. The zero it writes has **no special banking meaning**.

## The entire 8 KiB window changes immediately

A bank-select write replaces the complete `>6000–>7FFF` CPU window as the write occurs.

If execution is currently in ROM, the instruction after the bank-select write is fetched from the **new** bank at the same CPU address.

A safe transition must therefore use one of these approaches:

1. execute the switch from scratchpad or expansion RAM;
2. place identical continuation instructions at the same CPU address in both banks; or
3. place an identical bank-switch stub at the same address in every participating bank.

## RAM trampoline without hand-coded opcodes

Let the assembler generate the instruction words, then copy the two-word routine to scratchpad:

```asm
BANKRAM EQU >8320

BANK_TEMPLATE
       CLR  *R1             ; R1 = select address, e.g. >6004
       B    *R2             ; R2 = destination in newly selected bank
BANK_TEMPLATE_END

INSTALL_BANK_TRAMP
       MOV  @BANK_TEMPLATE,@BANKRAM
       MOV  @BANK_TEMPLATE+2,@BANKRAM+2
       RT

* Later: enter BANK2_ENTRY in bank 2
       LI   R1,>6004
       LI   R2,BANK2_ENTRY
       B    @BANKRAM
```

Install the trampoline while the source bank containing `BANK_TEMPLATE` is visible.

This avoids maintaining literal opcode constants in the documentation.

## Same-address transition stub in every bank

Another useful convention is to reserve the same final six bytes in every bank:

```asm
       AORG >7FFA
BANK0_STUB
       CLR  @>6000          ; switch to canonical bank 0
       B    *R9             ; this instruction is fetched from bank 0
```

For this to work, **the exact same two instructions must exist at `>7FFA` in every bank that may execute the stub**.

A caller can load `R9` with the bank-0 destination and branch to `>7FFA`. The `CLR` changes banks; the following `B *R9` survives because the same instruction is present at `>7FFE` in bank 0.

## Startup state: undefined by specification, measurable in practice

The 74LS378 provides **no guaranteed power-up bank state**. A released cartridge must therefore work without assuming that bank 0, the last bank, or any other particular bank will be selected after power-on.

At the same time, the startup state of an **individual cartridge** can be observed and is useful for testing and troubleshooting. Tursi's [BankTest](https://github.com/tursilion/banktest) utility exercises all cartridge banks; version 2 and later places an asterisk (`*`) next to the bank it detected at initial power-up.

In practical experience with these cartridge boards, the first or last ROM bank is commonly observed at cold power-up. Treat that only as an empirical observation about hardware that has been tested—not as a characteristic guaranteed by the 74LS378 and not as a design requirement for software.

BankTest can therefore answer **“which bank did this particular cartridge power up in?”** It cannot turn that observation into a portable guarantee for another 74LS378, another cartridge, or a future power cycle.

A reliable cartridge must still establish a known ROM bank by design.

### ROM-only cartridge: header/canonicalizer in every bank

The most robust ROM-only approach is to spend the small amount of space required for a valid cartridge header/startup path in **every bank**.

Each bank's startup entry should reach identical code that selects the canonical bank and then transfers to the real initializer.

A compact pattern is:

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

KICKSTART
       LWPI >8300
       LIMI 0
       LI   R9,MAIN
       B    @>7FFA          ; same stub exists in every bank

       AORG >7FFA
       CLR  @>6000          ; establish canonical bank 0
       B    *R9
```

The header/startup code and `>7FFA` stub must be laid out consistently in every bank.

The exact header size depends on the menu text and structures, but the principle is simple: sacrificing a few dozen bytes per 8 KiB bank is far safer than relying on an undefined latch state.

### ROM/GROM cartridge: use a GROM power-up link

Because this board also has GROM, a ROM/GROM application may use a **GROM power-up link** to select the desired ROM bank before ROM code depends on it.

This can eliminate the need to depend on ROM-latch state during startup, but the power-up code itself must be designed and tested as part of the cartridge's GROM startup path.

## QUIT does not reset the 74LS378

This is as important as cold-power behavior.

`QUIT` is a **software reset**. It does not toggle a hardware reset input on the 74LS378, so the latch can retain whichever bank the program last selected.

This is also why BankTest's `*` startup-bank indication is valid only when the test is run immediately after an actual power cycle. Once BankTest—or any other program—changes banks, the latch does not return to its original startup state merely because the console performs a software reset.

Therefore a cartridge that works after cold power-up can still fail after `QUIT` if it assumes the ROM latch returned to bank 0.

Design for both cases:

- canonicalize the bank before handing control back when practical;
- provide ROM headers/startup logic that works from any possible bank; and/or
- use the GROM power-up mechanism to establish the desired ROM bank when the console re-enters its cartridge scan path.

## Building the U2 image

Each ROM bank is an 8192-byte image assembled for CPU addresses `>6000–>7FFF`.

For this **non-inverted** board, concatenate them in ascending bank order:

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

If a programmer or packaging format requires a full 512 KiB file, pad unused banks deliberately. Do not silently reorder them.

## Cross-bank symbols

A cross-bank target is not just an address. It is:

```text
(bank number, CPU address in >6000–>7FFF)
```

For maintainable source:

- define a standard bank-transition ABI;
- export fixed entry points or generate bank-equate files;
- rebuild dependent banks whenever exported addresses move;
- avoid hand-copied inter-bank addresses.

## Inverted-image warning

Older 74LS379 boards used inverted bank outputs. Their **8 KiB bank order** may be reversed relative to this board.

Conversion means reversing the sequence of 8 KiB banks. Do **not** reverse the bytes or bits inside each bank.
