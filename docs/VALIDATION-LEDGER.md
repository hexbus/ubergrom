# Validation ledger

This file records items that should be tested or confirmed before being promoted to copy-and-paste reference examples.

## Open / test before publishing as canonical

### GPL power-up bank-select example

The hardware/software design supports using a GROM/GPL power-up link to establish a ROM bank during console startup. The concept is documented, but an exact GPL source example should be assembled and tested on real hardware before being presented as canonical syntax.

### Contributed examples

The Tim/InsaneMultitasker TELCO UART patch and Fred Kaal ADC digitizer code are preserved as contributed application examples. They should not be rewritten into "minimal" examples without testing the resulting standalone versions.

## Resolved

- 74LS378 startup state is not guaranteed; BankTest may be used to characterize an individual cold power-up without making that result a design guarantee.
- Bank selection on this board depends on the write address; the written data value is immaterial.
- U2 and the ATmega/UberGROM subsystem are separate programming domains.
- JP1 stays in the U2 write-disabled position for normal operation; the current design does not provide a supported U2 in-circuit programming method.
- JP4 is implemented in the released firmware as the UberGROM distribution lock for FlashCtl and protected configuration EEPROM writes.
- The PCB exposes four GPIO pins and four ADC inputs.
