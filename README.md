# UberGROM Cartridge for TI-99/4A

## DRAFT 

A powerful 512K ROM/GROM multi-bank cartridge with an onboard ATmega1284P microcontroller and flexible I/O expansion for TI-99/4A development, testing, and gameplay.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Hardware Description](#hardware-description)
- [Bill of Materials (BOM)](#bill-of-materials-bom)
- [Jumper Settings](#jumper-settings)
- [Flashing Firmware](#flashing-firmware)
- [Programming the GROMs/ROMs](#programming-the-gromsroms)
- [EEPROM Usage](#eeprom-usage)
- [ATmega1284P Memory Map](#atmega1284p-memory-map)
- [Supported Devices](#supported-devices)
- [Understanding Bases, Slots, and Pages](#understanding-bases-slots-and-pages)
- [ROM and GROM Primer](#rom-and-grom-primer)
- [Serial I/O & Bluetooth](#serial-io--bluetooth)
- [Possible Uses for Analog I/O](#possible-uses-for-analog-io)
- [Compatible Software](#compatible-software)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

---

## Overview

The UberGROM is an experimental development cartridge designed for the TI-99/4A home computer. It provides 512K of ROM, 120K of virtual GROM, EEPROM for persistent configuration, and additional I/O features via the onboard ATmega1284P microcontroller. Originally created by Mike “Tursi” Brent, the UberGROM allows for versatile cartridge development and expands the GROM architecture far beyond what TI originally implemented.

## Features

- ATmega1284P microcontroller running at 8MHz internal clock
- 512K Flash ROM (39SF040 supported)
- 120K of GROM in 8K banks
- 4K EEPROM configuration space with wear protection
- 15K of RAM (8K + 7K banks)
- Optional serial communication header
- Optional analog input ports
- Supports 16 GROM bases
- Recovery loader and power-on vector handling
- Fits in standard TI-99/4A cartridge case and slot

## Hardware Description

The UberGROM board consists of the following major components:

- **U3:** ATmega1284P microcontroller in DIP40 socket (recommended socketed)
- **U2:** 39SF040 Flash ROM in PLCC-32 socket (supports 512K ROM)
- **U1:** 74LS378 6-bit D flip-flop in DIP16 socket (recommended socketed)
- **C1:** 1nF capacitor (may be omitted for GROM stability)
- **C2–C5:** 0.1μF decoupling capacitors for power stabilization
- **R1:** 68Ω resistor (data line buffering)
- **R2:** 2.2kΩ pull-up resistor
- **JP1:** 3-pin enable jumper (place jumper on pins 1–2 to activate cartridge)
- **JP3:** 3-pin enable jumper (same as JP1 — either may be used)
- **JP4:** 2-pin write-protect header (optional)
- **JP5:** Serial header (3-pin)
- **JP6:** I/O header (8-pin for +5V, GND, SS*, RESET*, MOSI, MISO, SCK, etc.)
- **JP7:** ADC header (5-pin for DC0–DC3 analog lines)
- **JP8:** Reset header (2-pin, must be jumpered for boot)

## Bill of Materials (BOM)

| RefDes | Part                          | Package     | Notes                          |
|--------|-------------------------------|-------------|---------------------------------|
| U1     | 74LS378                       | DIP16       | Socketed recommended           |
| U2     | 39SF040                       | PLCC-32     | Socketed, 512K Flash            |
| U3     | ATmega1284P                  | DIP40       | Socketed, 128KB flash, 4KB EEPROM |
| C1     | 1nF Capacitor                 | Through-hole| Optional, omit if GROM is unstable |
| C2–C5  | 0.1μF Capacitors              | Through-hole| Decoupling                      |
| R1     | 68Ω Resistor                  | Through-hole|                                 |
| R2     | 2.2kΩ Resistor                | Through-hole|                                 |
| JP1    | 3-pin Header                  |             | Cartridge enable (1–2 jumpered) |
| JP3    | 3-pin Header                  |             | Same function as JP1           |
| JP4    | 2-pin Header                  |             | Write protect (not used)       |
| JP5    | 3-pin Header                  |             | Serial interface                |
| JP6    | 8-pin Header                  |             | GPIO / Programming / SPI       |
| JP7    | 5-pin Header                  |             | Analog inputs                   |
| JP8    | 2-pin Header                  |             | Reset (must be jumpered)       |

## Jumper Settings

- **JP1 and JP3:** Jumper pins 1–2 to enable cartridge
- **JP4:** (optional) Write protect — not implemented
- **JP5:** Serial programming or communication
- **JP6:** GPIO/SPI breakout
- **JP7:** Optional analog inputs
- **JP8:** Reset enable — must be jumpered to boot

## Flashing Firmware

To program the ATmega1284P:

1. Connect a programmer (such as USBasp, AVRISP mkII, or ArduinoISP)
2. Set fuses for internal 8MHz oscillator, no clock divide:
   - `Low Fuse:` `0xE2`
   - `High Fuse:` `0xD9`
   - `Extended Fuse:` `0xFF`
3. Use `avrdude`:
```bash
avrdude -c usbasp -p m1284p -U lfuse:w:0xE2:m -U hfuse:w:0xD9:m -U efuse:w:0xFF:m
```
4. Flash firmware:
```bash
avrdude -c usbasp -p m1284p -U flash:w:ubergrom.hex:i
```

## Programming the GROMs/ROMs

- The `ubergrom.hex` firmware image includes Tursi’s bootloader at the top 4K of memory.
- User data for GROMs starts after address `>0000` and is mapped in 8K slots.
- The 39SF040 PLCC Flash supports up to 512K of ROM.
- ROM bank switching uses writes to a paging register — typically done by writing to the ROM’s own address space.  See [Stuart Conner's article](http://www.stuartconner.me.uk/ti/ti.htm#bank_switching) on 74LS379 bank switching.
- Note: For ROMs, the 74LS378 switches 8K banks forward (bottom → top) and is the current standard. The 74LS379 switches banks in reverse (top → bottom) and is legacy. MAME refers to these as .8 (74LS378) and .9 (74LS379).

## EEPROM Usage

- 4KB EEPROM (within ATmega1284P)
- EEPROM space is memory-mapped and write-protected by default
- Top 2K of EEPROM is used for configuration (`>F800` in GROM base 15)
- Unlock EEPROM:
```text
Write 0x55 → >FFFF (base 15)
Write 0xAA → >FFFF
Write 0x5A → >FFFF
```
- EEPROM config bits:
  - `0x01`: Enable multiple GROM bases
  - `0x02`: Disable recovery loader
  - `0x04`: Allow rollover past 8K boundary

## ATmega1284P Memory Map

| Region         | Size     | Address Range    | Purpose                      |
|----------------|----------|------------------|-------------------------------|
| Flash Program  | 128KB    | `0x0000–0x1FFFF` | Main code and GROM content    |
| Bootloader     | 4KB      | `0x20000–0x20FFF`| Optional AVR bootloader       |
| SRAM           | 16KB     | `0x0100–0x40FF`  | RAM usage (8K + 7K bank)      |
| EEPROM         | 4KB      | Mapped in GROM   | Config and persistent storage |

## Supported Devices

The UberGROM supports memory-mapped access to various internal and external devices:

| Type ID | Device   | Access Type    | Pageable? |
|---------|----------|----------------|-----------|
| 0       | RAM      | R/W            | Yes       |
| 1       | GROM     | Read-only      | Yes       |
| 2       | EEPROM   | R/W            | No        |
| 3       | GPIO     | R/W Peripheral | No        |
| 4       | ADC      | Read-only      | Yes       |
| 5       | UART     | R/W Peripheral | No        |
| 6       | FlashCtl | R/W Peripheral | No        |
| 7       | Timer    | Read-only      | No        |

Each GROM slot may map one device. Devices may be paged using the second nibble of the configuration.

## Understanding Bases, Slots, and Pages

- **Base:** A GROM “base” is a CPU-side address block. Each base accesses a unique 64K GROM space.
  - Base 0: `>9800`, Base 1: `>9804`, etc. up to Base 15

- **Slot:** An 8K chunk within a base. TI GROMs have 8K slots: `>6000`, `>8000`, `>A000`, etc.

- **Page:** A segment of memory within a device mapped to a slot. For example, GROM Page 2 = bytes `>10000–>11FFF`.

- Up to 16 bases × 6 usable slots per base = 96 GROM segments total (768KB).

## ROM and GROM Primer

TI-99/4A cartridges historically use:

- **ROMs**: For CPU code, accessed via address decoding
- **GROMs**: For GPL programs, data, or menus — accessed via TI’s proprietary auto-increment GROM port

See:
- [TI ROMs and decoding](https://www.unige.ch/medecine/nouspikel/ti99/roms.htm) and [here](http://www.stuartconner.me.uk/ti/ti.htm#bank_switching)
- [TI GROM overview](https://www.unige.ch/medecine/nouspikel/ti99/groms.htm)
- [GPL Reference](https://www.unige.ch/medecine/nouspikel/ti99/gpl.htm)
- [UberGROM Programming - Start here!](https://forums.atariage.com/topic/305712-the-mega-ubergrom-thread-start-here/)
- [Tursi's GROMCFG Primer](https://youtu.be/KgBOirVyC0Q)

## Serial I/O & Bluetooth

JP5 offers a basic UART-compatible serial interface:

- 3-pin header: GND, TX, RX
- Default baud rate can be configured in EEPROM
- 5V TTL level only; use a level shifter or Serial/Bluetooth module (e.g. HC-05) that can support 5V.  Do not use a 3.3V serial or Bluetooth version.

## Possible Uses for Analog I/O

JP7 provides access to 4 analog inputs (DC0–DC3).
Example use cases:

- Potentiometers or dials
- Light sensors
- Analog joystick support

## Compatible Software

- Any GROM-based or ROM-based software
- Tursi’s UberGROM loader
- EasyBug for recovery (bootloader)
- Custom utilities written in GPL or assembly

## Troubleshooting

| Symptom                          | Solution                                      |
|----------------------------------|-----------------------------------------------|
| Cartridge not detected           | Check JP1/JP3 enable jumpers and sockets      |
| Unexpected resets                | Try removing C1 (1nF) capacitor               |
| EEPROM won’t write               | Ensure correct unlock sequence was used       |
| No bootloader appears            | Bootloader may be disabled in config (0x02)   |

## Credits

- Mike Brent (Tursi) – Developed the UberGROM firmware, AVR architecture, and core + documentation
- James Fetzner (Ksarul) – Contributed to PCB overall design and documentation
- Jon Guidry (acadiel) – Contributed to PCB ROM design and documentation
- Mark Wills, Stuart Conner, Thierry Nouspikel, and others – Special thanks for their valuable support and contributions!
