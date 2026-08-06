# Hardware reference

This chapter distinguishes the board's independent ROM and ATmega subsystems and corrects several ambiguous descriptions in the former README.

## Major devices

| Ref. | Device | Function |
|---|---|---|
| U1 | 74LS378 | six-bit non-inverting ROM bank latch |
| U2 | 29F040/39SF040/49F040-compatible 512 KiB flash | CPU ROM at `>6000–>7FFF` |
| U3 | ATmega1284P | UberGROM firmware, GROM content, RAM, EEPROM, and peripherals |

## Jumpers and headers

| Ref. | Normal function |
|---|---|
| JP1 | controls the ROM flash write-enable connection; normal read-only cartridge operation uses the documented default position |
| JP3 | controls the ROM flash output-enable routing; it is not a duplicate of JP1 |
| JP4 | reserved UberGROM write-protect connection; the present firmware does **not** implement write protection, so changing this jumper currently has no protective effect |
| JP5 | UART header: ground, receive, transmit; 5 V TTL levels |
| JP6 | ATmega in-system-programming/SPI header with power and grounds |
| JP7 | analog input header |
| JP8 | reset-line connection; normally closed |

The exact pin numbering and jumper orientation must follow the board silkscreen and final schematic, not assumptions based on connector position.

## JP4 write-protect status

JP4 was designed as a hardware input that could allow the UberGROM firmware to reject writes to its internal GROM flash. **That write-protect function is not implemented in the current firmware.** The jumper may exist on the PCB and may be described as write protect in the schematic or historical manual, but it must presently be treated as reserved/nonfunctional.

Consequently:

- JP4 does not currently prevent GROMCFG, FlashCtl, or other software from modifying the ATmega's emulated GROM flash.
- JP4 does not protect the ATmega's EEPROM or persistent save data.
- JP4 does not hardware-protect the ATmega1284P program Flash from an external programmer.
- Cartridge builders must not rely on JP4 as a distribution lock or safety control.

Protection must instead come from software configuration, removing the FlashCtl mapping when appropriate, retaining backups, and controlling physical access to programming equipment. A future firmware revision may implement JP4, but documentation for that behavior must identify the firmware version in which it became active.

## Programming outside the cartridge

Socketed chips may be removed and programmed in a supported device programmer. Observe ESD precautions and pin-1 orientation.

The in-system-programming header was designed to expose MISO, MOSI, SCK, reset, select, +5 V, and ground. Historical development notes report that programming while the board remained attached to the TI was unsuccessful; treat the console as disconnected and power the target in the manner required by the programmer.

## ROM write controls

The board's ROM bank-switching writes are not flash-programming writes. A TMS9900 `CLR @>6002` selects bank 1 through the 74LS378; it does not alter flash contents.

Changing JP1/JP3 for experimental in-circuit ROM programming is an advanced hardware procedure and should not be described as normal cartridge setup.
