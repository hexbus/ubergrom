# Validation ledger

This ledger records issues that were either resolved during review or still require a hardware/software test before being stated as fact.

## Resolved: software authorship and maintenance boundary

The UberGROM AVR firmware and associated software are authored by **Mike Brent/Tursi** and retain the license in his source tree.

Authoritative software source:

- https://github.com/tursilion/ubergrom

This hardware/documentation repository describes integration and use. It must not use wording such as “project-maintainer programming practice” that implies ownership of Tursi's code or an obligation for him to maintain this documentation.

## Resolved: ATmega1284P fuse settings and functional meaning

For the ATmega1284P board builds:

**Jon's established setting**

- Extended `FF`
- High `D8`
- Low `C2`

**Tursi's brown-out-protected example**

- Extended `FC`
- High `D8`
- Low `C2`

Functional requirements for High/Low:

- internal calibrated ~8 MHz RC oscillator;
- CKDIV8 disabled;
- 8 KiB boot section;
- BOOTRST enabled;
- serial/ISP programming enabled;
- EEPROM not preserved automatically by Chip Erase.

Extended fuse difference:

- `FF`: BOD disabled;
- `FC`: BODLEVEL `100`, approximately 4.3 V.

Raw bytes are ATmega1284P-specific. Any firmware port to another AVR requires translating the desired functions to that AVR's fuse map rather than copying these bytes.

## Resolved: ATmega programmer-image layout

- 128 KiB program Flash occupies unified buffer `>00000–>1FFFF`.
- 4 KiB EEPROM occupies unified buffer `>20000–>20FFF`.
- Combined image size is 132 KiB (`>21000`).
- Combined file: load at `>00000`, enable **Include EEPROM**.
- Separate files: load 128 KiB Flash at `>00000`, then 4 KiB EEPROM at `>20000` without clearing the buffer, enable **Include EEPROM**.
- `>20000` is a file/programmer-buffer offset; AVR EEPROM's own address space begins at EEPROM `>0000`.
- Flash-only 128 KiB images intentionally omit EEPROM.

This is distinct from GROMCFG's whole-device save, which contains 120 KiB GROM content + 4 KiB EEPROM and excludes the final 8 KiB AVR firmware.

## Resolved: GPIO count

The final PCB exposes **four GPIO pins**. Tursi's `gromtest` confirms only the four low GPIO bits are valid in the test interface.

Remove older uncertainty suggesting four-versus-six GPIO on this board.

## Resolved: JP4 write-protect behavior

Tursi's released source implements JP4 through ATmega PC7.

When closed/grounded:

- `flash.c` rejects FlashCtl erase/program requests and returns write-protected result code `2`;
- `eeprom.c` rejects persistent writes to EEPROM addresses below `>0102`.

JP4 does not block:

- RAM;
- user EEPROM `>0102+`;
- U2 external ROM;
- direct external programming of the ATmega.

This supersedes the earlier draft statement that JP4 was unimplemented.

## Resolved: U2 and U3 programming separation

The external U2 ROM subsystem and U3 ATmega subsystem are independent.

Documentation must not imply:

- that GROMCFG or FlashCtl can program U2;
- that JP1/JP3 affect ATmega EEPROM/GROM Flash;
- that JP4 protects U2.

JP1/JP3 are U2-side signal routing; JP4 is U3-side firmware write protection. **JP1 should remain at 1-2 (U2 write disabled): there is no complete in-circuit U2 programming path, and the cartridge's normal bank-selection mechanism itself uses TI write cycles in ROM space to clock the 74LS378.**

## Resolved: 74LS378 startup behavior

The power-up bank is **not guaranteed by the 74LS378 specification**, but an individual board can be characterized. Tursi's BankTest utility marks the bank detected at cold power-up with `*` (version 2+). Practical experience with these boards commonly finds the first or last bank, but this remains an empirical observation and must not become a software dependency.

Reliable strategies:

- put a valid startup/header/canonicalizer path in every possible ROM bank; or
- on a ROM/GROM cartridge, use a GROM power-up link to establish the desired ROM bank.

Also explicitly document that `QUIT` is software reset and does not reset the 74LS378 latch, so BankTest's startup indication is meaningful only immediately after a true power cycle.

## Resolved: extended-feature reference examples

Tursi has added the `gromtest` application to the current UberGROM source tree. It exercises:

- EEPROM;
- RAM;
- four GPIO;
- ADC;
- UART;
- FlashCtl;
- timer.

The documentation should point to this as the executable reference implementation rather than inventing unsupported register behavior.

## Resolved: FlashCtl usage wording

FlashCtl is not restricted to a “disposable development device.”

It is used by GROMCFG and `gromtest` and is appropriate for cartridge creation, testing, and infrequent Flash updates. It should not be used as high-frequency application storage because Flash erase/program is slow and the documented erase endurance is approximately 10,000 cycles.

## Still to test: hand-built ROM transition examples

The bank-switching documentation now avoids hand-encoded TMS9900 opcode constants. Before promoting any larger example as a complete copy-and-build project, assemble it with the intended assembler and test on real 74LS378 hardware.

## Still to document more fully: GROM power-up link example

The ROM bank chapter now describes the GROM power-up link as a reliable way to establish a canonical ROM bank. Add a minimal, tested GROM power-up-link source example so a new developer can use this path without searching older TI documentation.

## Still to reconcile: external U2 part list

Historical material names 29F040/49F040 and some current text mentions 39SF040. Confirm exact pin/voltage/programmer compatibility for every device before publishing a blanket supported-parts list.
