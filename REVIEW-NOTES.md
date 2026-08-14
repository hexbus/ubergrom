# Designer-review changes — August 2026

This file records documentation changes made after review by Mike Brent/Tursi and Jon Guidry. It is an editorial audit, not part of the UberGROM software license.

## Software ownership and maintenance

Changed documentation to explicitly separate:

- collaborative cartridge hardware documentation; and
- Mike Brent/Tursi's UberGROM AVR firmware and software.

The documentation points to Tursi's repository as the authoritative software source and does not describe another person as maintainer/owner of his code.

## Fuses

Expanded ATmega1284P fuse documentation from raw byte values into the actual fuse functions.

Documented:

- Jon's established `FF/D8/C2`;
- Tursi's `FC/D8/C2` example, differing only in BOD configuration;
- `FF` = BOD disabled;
- `FC` = approximately 4.3 V BOD;
- High `D8` and Low `C2` bit meanings;
- warning that other AVR devices require their own fuse encoding.

## JP4 write protect

Reversed the earlier incorrect statement that JP4 was unimplemented.

Current Tursi source confirms PC7 write protection in:

- `eeprom.c` for the protected configuration EEPROM region; and
- `flash.c` for FlashCtl writes.

Documented what JP4 protects and, equally importantly, what it does not protect.

## U2 ROM versus U3 ATmega

Strengthened the hardware separation throughout the docs:

- JP1/JP3 are U2-side routing;
- JP4 is U3/ATmega-side firmware write protection;
- GROMCFG/FlashCtl cannot program U2;
- ROM bank-select writes do not program U2;
- the ATmega does not control U2 contents.

### JP1 / U2 WE clarification from Jim Fetzner

The current board has no complete way to program the 512 KiB U2 Flash in circuit. JP1 must not be presented as a usable in-circuit programming selector. Leave JP1 at **1-2 (`+5V / Write Disable`)** for normal operation. The reason is architectural: bank switching is performed by TI writes to cartridge ROM-space addresses, which assert the write cycle needed to clock the 74LS378. Those writes select a bank; they are not U2 programming cycles, and U2 is intentionally kept write-disabled.

## GPIO

Resolved the count to four physical GPIO pins on the PCB.

The extended-feature chapter now points to Tursi's `gromtest`, which treats the low four GPIO bits as valid.

## 74LS378 startup and QUIT

Refined the wording to distinguish **no guaranteed startup bank** from **a startup bank that can be measured on an individual cartridge**.

Added Tursi's BankTest utility (`https://github.com/tursilion/banktest`), which marks the bank detected at cold power-up with `*` in version 2 and later. The docs also record the practical observation that first- or last-bank startup is common on these boards, while making clear that software must never rely on that behavior.

Added the separate `QUIT` warning: software reset does not reset the bank latch, so the BankTest startup marker is valid only immediately after a true power cycle.

Documented two reliable strategies:

- startup/header/canonicalizer path in every possible ROM bank; or
- GROM power-up link to establish the ROM bank on a ROM/GROM cartridge.

## gromtest

Added Tursi's current `gromtest` directory as the executable reference for:

- EEPROM
- RAM
- GPIO
- ADC
- UART
- FlashCtl
- timer

## FlashCtl

Removed the “disposable development device only” characterization.

FlashCtl is documented as suitable for configuration, tests, and infrequent updates, while warning against high-frequency storage because Flash writes are slow and erase endurance is finite.
