# Designer/community review changes — August 2026

This file records documentation changes made after review by Mike Brent/Tursi, James Fetzner, Jon Guidry, Tim/InsaneMultitasker, Fred Kaal/F.G. Kaal, and other TI community discussion. It is an editorial audit, not part of the UberGROM software license.

## Software ownership and maintenance

The documentation explicitly separates the collaborative cartridge hardware/documentation project from Mike Brent/Tursi's UberGROM AVR firmware and software. Tursi's repository remains the authoritative software source; these docs do not claim ownership of or maintenance responsibility for his code.

## Complete ATmega release images

Clarified that a blank ATmega1284P needs both its 128 KiB program Flash image and its 4 KiB EEPROM configuration. A complete release should therefore provide either a combined 132 KiB image or the matching Flash+EEPROM pair. A 128 KiB Flash-only file is treated as an update artifact unless configuration is supplied separately.

## Fuses and brown-out detection

Expanded the fuse documentation from raw bytes into their functions. For new ATmega1284P programming, `FC/D8/C2` is now the recommended setting because the ~4.3 V BOD keeps the AVR held until the aging TI 5 V supply is in a stable range. Jon's historically used `FF/D8/C2` remains documented as known-working reference information, not the preferred new-device setting.

## JP4 distribution lock

Corrected the earlier erroneous claim that JP4 was unimplemented. Tursi's released source checks PC7 in `eeprom.c` and `flash.c`.

JP4 is now described as the intended **distribution lock**:

- blocks FlashCtl erase/program operations;
- blocks protected configuration EEPROM writes below `>0102`;
- leaves RAM and user EEPROM `>0102+` available for normal application storage;
- does not interact with the independent U2 ROM subsystem.

Repeated discussion of defeating protection with an external programmer was removed because it is outside the useful operational scope of the cartridge documentation.

## U2 ROM versus U3 ATmega

Strengthened the separation between the two cartridge domains:

- GROMCFG/FlashCtl cannot program U2;
- U2 banking cannot alter ATmega memory;
- JP1/JP3 are U2-side controls;
- JP4 is an ATmega/UberGROM control.

Jim Fetzner clarified that the current design has no supported in-circuit programming method for U2. JP1 should remain at 1-2 / write disabled for normal operation because TI writes to cartridge ROM space are intentionally used to clock the 74LS378 bank latch while U2 itself remains write-disabled.

## 74LS378 startup, BankTest, and QUIT

The docs retain the hardware rule that the 74LS378 power-up state is **not guaranteed**, but the wording now distinguishes specification from practical testing.

Tursi's BankTest is documented as a useful diagnostic that marks the bank observed on a particular cold power-up with `*`. Practical experience that many parts tend to start at the first or last bank is identified as empirical observation, not a design guarantee.

The separate `QUIT` warning remains: a software reset does not reset the bank latch.

## Bank-switching examples

Changed terminology from “select address” to **bank select** and removed discussion of unrelated mapper designs.

Replaced the earlier confusing trampoline with Tursi's suggested approach: assemble `CLR *R1 / B *R2` normally and copy the assembled routine into scratchpad with a loop.

For ROM-only startup, the first instruction at `KICKSTART` now performs the bank select (`CLR @>6000`). This means every bank needs the common header/entry and first bank-select instruction, after which execution continues from bank 0.

Added the GROM/GPL power-up-link strategy as the other clean way to establish the ROM bank. Exact GPL source syntax remains in the validation ledger until tested.

Changed padding guidance to prefer `>FF`, the erased state of the external Flash.

Relaxed the cross-bank-symbol section: there is no mandated TI linker or generated-symbol workflow; projects may track bank+address relationships in whatever maintainable way fits the codebase.

## GPIO and ATmega1284P configuration

Resolved the production PCB to four physical GPIO pins. The extended-feature table now explicitly states that it documents the ATmega1284P configuration used by the production board.

## gromtest

Tursi added `gromtest` to the upstream UberGROM repository. The documentation uses it as the authoritative executable reference for EEPROM, RAM, GPIO, ADC, UART, FlashCtl, and timer behavior rather than redistributing or rewriting Tursi's source.

## UART

Documented the 256-byte receive buffer and the need for TI-side flow-control/buffer management at sustained high rates.

Added Tim/InsaneMultitasker's TELCO UberGROM patch as a contributed real-world example. It demonstrates 38.4K 8N1 initialization, character transmit, receive-count polling, draining the UberGROM receive buffer, and moving incoming data into a larger 4 KiB RAM circular buffer.

## ADC

Added Fred Kaal/F.G. Kaal's two-channel digitizer example. It demonstrates TMS9900 reads from two mapped ADC channels and passes the 0–255 values back to TI BASIC, which converts the linkage angles into X/Y coordinates.

The contributed source is included; historical magazine scans are not redistributed in the documentation package.

## EEPROM, timer, and Flash endurance

- EEPROM endurance is documented as approximately 100,000 write/erase cycles per cell and is not recommended for frequently changing/live banking state.
- Flash endurance remains approximately 10,000 erase cycles.
- Timer wording notes that it is based on the internal oscillator but that AVR devices are factory calibrated and should normally be reasonably close.
- FlashCtl is documented as appropriate for configuration, testing, and infrequent updates rather than as a disposable-development-only feature.
