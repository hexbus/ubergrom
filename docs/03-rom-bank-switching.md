# 512 KiB ROM bank switching

The external U2 ROM is divided into sixty-four 8 KiB banks. One bank at a time appears in the TMS9900 cartridge window `>6000–>7FFF`.

This subsystem is independent of the ATmega/UberGROM subsystem.

## This board's bank mapper

The UberGROM/512K ROM-GROM board uses a **non-inverted 74LS378 address-selected mapper**.

The 74LS378 receives six bank bits from TI address lines A09–A14 and drives U2 address lines A13–A18.

## Bank selects

Bank *n* is selected by a TI write to:

```text
>6000 + (bank × 2)
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

On this board, the bank bits come from the **write address**, not from the value placed on the data bus.

```asm
       CLR  @>6000          ; bank 0
       CLR  @>6002          ; bank 1
       CLR  @>6004          ; bank 2
       CLR  @>6006          ; bank 3
```

`CLR` is convenient because it performs the required write. The zero value written has no special banking significance.

## The complete 8 KiB ROM window changes immediately

A bank-select write replaces the complete CPU ROM window at `>6000–>7FFF` as the write occurs.

If code is executing from cartridge ROM, the instruction following the bank select is fetched from the **new** bank at the same CPU address. Software must therefore make the transition deliberately.

Common techniques are:

- execute the bank-select operation from scratchpad or expansion RAM;
- arrange an identical transition instruction at the same address in the old and new banks; or
- use a small RAM trampoline.

## RAM trampoline

A straightforward approach is to let the assembler generate the bank-switch routine normally and copy it into scratchpad RAM. This avoids hand-maintaining instruction opcodes.

```asm
BANKRAM EQU >8320

* Copy TRAMP into scratchpad RAM.
INSTALL
       LI   R0,TRAMP
       LI   R1,BANKRAM
INLP
       MOV  *R0+,*R1+
       CI   R0,TRAMPEND
       JNE  INLP
       B    *R11

* Runs from scratchpad.
* R1 = bank select, such as >6004
* R2 = destination address in the newly selected bank
TRAMP
       CLR  *R1
       B    *R2
TRAMPEND
```

To enter a routine in bank 2, for example:

```asm
       LI   R1,>6004
       LI   R2,BANK2ENTRY
       B    @BANKRAM
```

The trampoline can be extended if necessary; just keep it within the scratchpad space reserved by the application.

## Power-up bank behavior

The 74LS378 does **not guarantee a defined state at power-up**, so a released cartridge must not depend on a particular initial ROM bank.

That does not mean an individual cartridge cannot be characterized. Tursi's **BankTest** utility reports the bank observed at cold power-up and places an asterisk (`*`) next to that bank:

- https://github.com/tursilion/banktest

This is useful for hardware testing and troubleshooting. In practical experience, many 74LS378 devices encountered on these cartridge boards have tended to power up at one end of the bank range — often the first or last bank — but that is an empirical observation, **not a guaranteed property of the part**.

Treat BankTest as a way to learn what a particular board did on that power-up, not as permission to make software depend on that result. Run it immediately after a real power cycle when testing startup behavior; later bank selects change the latch state.

## ROM-only startup: put a usable header path in every bank

For a ROM-only cartridge, the reliable approach is to provide a cartridge header/startup path in every bank that the 74LS378 could expose during the console scan.

The most compact canonicalization is to make the **first instruction of the program entry point itself** select the intended bank. If every bank points its program-list entry to `KICKSTART` at the same address, only that first instruction needs to be duplicated after the header. Once it executes, the next instruction is fetched from bank 0.

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
       CLR  @>6000          ; FIRST instruction: establish bank 0
                            ; next instruction is now fetched from bank 0
       LWPI >8300
       LIMI 0
       B    @MAIN
```

Place the header, program-list entry, and the first `CLR @>6000` instruction at the same addresses in every bank. The remainder of `KICKSTART` and `MAIN` need only exist in bank 0.

### Header-space optimization

The console does not require every possible cartridge-header list to be populated. It is possible to save a few bytes by reusing fields that the cartridge does not need, but conventional headers are easier to inspect and maintain. Unless space is unusually tight, favor a normal, readable header layout.

## ROM/GROM cartridges: use GROM to control or launch U2 ROM

Because this board provides both programmable GROM and a separate 512 KiB U2 ROM, the GROM side can establish ROM state or act as the cartridge menu/launcher.

Two related patterns are useful:

1. a **GPL power-up link** can select a known ROM bank during the console's startup scan; and
2. a **GPL program-list entry** can launch a particular banked-ROM application when the user selects it from the TI menu.

The second pattern is demonstrated by the genericized two-application launcher in [`../examples/gpl-multi-program-menu/`](../examples/gpl-multi-program-menu/). The launcher technique was validated in a working cartridge; the public example deliberately uses generic application names and sample U2 addresses.

### GPL multi-ROM launcher

The example is assembled into logical GROM slot `>8000`. Its GROM cartridge header contributes two menu entries:

```text
ROM APP1  -> bank select >6000 -> ROM entry >6100
ROM APP2  -> bank select >6002 -> ROM entry >6100
```

Each GPL menu entry stores the selected bank address and ROM entry point into scratchpad. Shared GPL code then creates this TMS9900 sequence in scratchpad:

```asm
       CLR  @bank_select
       B    @rom_entry
```

and invokes it with `XML >F0`. The bank-select write therefore executes outside the U2 cartridge window, so switching the complete `>6000–>7FFF` ROM window is safe.

The checked-in values are illustrative. A real cartridge substitutes the bank select and CPU entry address required by each U2 application.

### Mix ROM-resident and GROM-resident programs on one cartridge

The GPL launcher does not have to own every menu entry on the cartridge. Other mapped GROMs can contain their own standard cartridge headers and program lists.

For example, a three-choice cartridge can be arranged as:

| GROM base | GROM slot / resource | Contents | Selection-list contribution |
|---:|---:|---|---|
| base 0 (`>9800`) | `>8000` | GPL multi-ROM launcher | two U2 application entries |
| base 0 (`>9800`) | `>A000` | independent GROM program | one independent GROM entry |
| U2 | banks as assigned | ROM application code | launched by the GPL entries |

The TI scans cartridge GROM locations while building its selection list, so the separate GROM header can contribute its own program entry in addition to the entries supplied by the GPL launcher. The physical result is one cartridge offering a mixture of GROM and bank-switched ROM software.

Keep the terminology straight:

- a **GROM base** is the CPU port set (`>9800`, `>9804`, ...);
- a **GROM slot** is one of `>6000`, `>8000`, `>A000`, `>C000`, or `>E000` within that base; and
- a **physical GROM page** is one of the ATmega1284P's fifteen 8 KiB Flash pages selected by GROMCFG and mapped into a base/slot.

The physical page number does not need to match the logical slot.

If two existing GROM programs both expect the same logical slot, UberGROM's multiple-base support can also be used to place them at the same slot on different GROM bases. Mapping is not relocation, however: moving an existing image from `>6000` to `>A000` does not rewrite any absolute GPL/GROM addresses embedded in that image.

See [`../examples/gpl-multi-program-menu/README.md`](../examples/gpl-multi-program-menu/README.md) for the generic launcher source and example mappings.

For a broader explanation of combining ROM-resident programs with independent GROM cartridges, including the historical 1979 Milton Bradley Gamevision Demonstration Cartridge layout and compatibility caveats, see [Building multi-program UberGROM cartridges](06-multi-program-cartridges.md).

## QUIT does not reset the 74LS378

Cold power-up is only half of the startup problem.

`QUIT` is a **software reset** and does not reset the 74LS378 latch. If a program selected another ROM bank before returning to the console, that bank can remain selected during the next cartridge scan.

A robust design therefore establishes its expected bank during startup rather than assuming that a console restart returned the latch to bank 0.

## Building the U2 image

Each bank is an 8192-byte image assembled for CPU addresses `>6000–>7FFF`.

For this non-inverted board, concatenate banks in ascending order:

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

When padding unused space, prefer `>FF`. That is the erased state of the Flash device, so a programmer can often skip those bytes; this reduces programming time and unnecessary device programming compared with padding erased space with `>00`.

Do not silently reverse bank order. Images for older inverted-bank hardware may need bank-order conversion before use on this board.

## Cross-bank addresses

The same CPU address can refer to different bytes depending on which bank is selected. A cross-bank reference therefore consists of both:

```text
(bank number, CPU address)
```

There is no requirement to use a particular linker, generated symbol-table workflow, or bank ABI. Many TI multi-bank programs simply track these relationships directly in source. Fixed entry points, equates, tables, or generated symbols can all be useful depending on the size of the project.

The important rule is simply: when code transfers across banks, make sure both the **bank select** and the **destination address in that bank** are correct.

## Inverted-image warning

Older 74LS379 boards used inverted bank outputs. Their **8 KiB bank order** may be reversed relative to this board.

Conversion means reversing the sequence of 8 KiB banks. Do **not** reverse the bytes or bits inside each bank.
