# Validation ledger

This file records items that should be tested or confirmed before being promoted to copy-and-paste reference examples.

## Open / test before publishing as canonical

### GPL power-up bank-select example

The hardware/software design supports using a GROM/GPL power-up link to establish a ROM bank during console startup. The concept is documented, but an exact GPL source example should be assembled and tested on real hardware before being presented as canonical syntax.

### GROM relocation / multi-base compatibility catalog

The multi-program chapter documents the mechanisms and a test-matrix format, but cartridge-by-cartridge compatibility should be measured rather than assumed. In particular, distinguish moving a title to another logical GROM **slot** from keeping the same slot on another GROM **base**, and separately record GROM+ROM dependencies.

### Contributed and requested examples

The Tim/InsaneMultitasker TELCO UART patch and Fred Kaal ADC digitizer code are preserved as contributed application examples. They should not be rewritten into "minimal" examples without testing the resulting standalone versions.

Two additional examples have been requested from the community but are **not yet part of the repository**:

- an application-level user EEPROM/high-score save example; and
- an UberHDX UART/serial example.

Move either item into the resolved/included documentation only after source is received, reviewed, and its required mapping is documented.

## Resolved

- The two-application GPL **program-list launcher technique** has been validated in a working cartridge. The checked-in `gromhead.g`/`gromhead.gbc` have been genericized for publication, so their menu names, bank selects, and ROM entry points are examples rather than a claim that those exact public sample values form a complete cartridge. The power-up pointer is zero; this is not a GPL power-up-link example.
- The 1979 Milton Bradley **Gamevision Demonstration Cartridge** provides a historical dealer-demo example of independent cartridge headers at logical GROM slots `>6000`, `>8000`, `>A000`, `>C000`, and `>E000`; proprietary images are not redistributed.
- 74LS378 startup state is not guaranteed; BankTest may be used to characterize an individual cold power-up without making that result a design guarantee.
- Bank selection on this board depends on the write address; the written data value is immaterial.
- U2 and the ATmega/UberGROM subsystem are separate programming domains.
- JP1 stays in the U2 write-disabled position for normal operation; the current design does not provide a supported U2 in-circuit programming method.
- JP4 is implemented in the released firmware as the UberGROM distribution lock for FlashCtl and protected configuration EEPROM writes.
- The PCB exposes four GPIO pins and four ADC inputs.
