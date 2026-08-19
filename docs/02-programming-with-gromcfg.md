# Programming the UberGROM with GROMCFG

GROMCFG is part of Mike Brent/Tursi's UberGROM software ecosystem. It configures the **ATmega/UberGROM side** of the cartridge from a TI-99/4A by mapping physical UberGROM devices into logical TI GROM locations and loading data into the mapped Flash pages.

Authoritative UberGROM software source:

- https://github.com/tursilion/ubergrom

This documentation explains how to use the released software with this cartridge board; it does not claim ownership or maintenance of Tursi's code.

> **GROMCFG does not program the separate U2 512 KiB ROM flash.** The U2 ROM subsystem and the ATmega subsystem are independent.

## Concepts

### Base

A GROM base is a set of four CPU ports:

| Base | Read data | Read address | Write data | Write address |
|---:|---:|---:|---:|---:|
| 0 | `>9800` | `>9802` | `>9C00` | `>9C02` |
| 1 | `>9804` | `>9806` | `>9C04` | `>9C06` |
| ... | ... | ... | ... | ... |
| 15 | `>983C` | `>983E` | `>9C3C` | `>9C3E` |

### Slot

The cartridge-usable 8 KiB GROM slots are:

```text
>6000  >8000  >A000  >C000  >E000
```

The console GROM ranges `>0000`, `>2000`, and `>4000` are intentionally not overridden by the standard cartridge firmware.

### Physical GROM page

The ATmega1284P build has fifteen physical 8 KiB GROM Flash pages, numbered 0 through 14 (`>0` through `>E`). Mapping controls where those physical pages appear in the TI's logical base/slot space.

A logical mapping does not copy data. The same physical page can be mapped into more than one location.

## JP4 must be open while configuring protected content

JP4 is implemented by the released firmware.

With JP4 **closed**, PC7 is grounded and firmware write protection blocks:

- FlashCtl writes to the ATmega's emulated GROM Flash; and
- persistent writes to the protected EEPROM configuration/mapping region.

Therefore leave JP4 **open** while using GROMCFG to build or reconfigure a cartridge.

The jumper does not block ordinary user EEPROM above the protected configuration region, RAM, or the separate U2 ROM.

## Recovery startup

1. Install a correctly programmed ATmega1284P.
2. Leave JP4 open.
3. Insert the cartridge with the TI powered off.
4. Hold **Space** while powering on.
5. Continue holding Space through the initial startup scan.
6. Select **RUN PROGRAM FILE** from the recovery menu.
7. Load `GROMCFG` from the supplied disk image, mass storage, RAM disk, or another compatible device.

The recovery path is associated with cold startup. If needed again, power-cycle and hold Space.

## Plan the map first

Write the intended map before loading files:

| Logical base | Slot | Device | Physical page/file |
|---:|---:|---|---|
| `>9800` | `>6000` | GROM | page 0 / `GAMEG1.BIN` |
| `>9800` | `>8000` | GROM | page 1 / `GAMEG2.BIN` |
| `>983C` | `>A000` | UART | page 0 |
| `>983C` | `>E000` | FlashCtl | page 0 while configuring |

This is especially useful on multi-base cartridges because GROMCFG separates **logical mapping** from **physical Flash page selection**.

## Mapping and loading a GROM page

1. Use `FCTN`+left/right to select the target base.
2. Select slot `6`, `8`, `A`, `C`, or `E`.
3. Choose **GROM** and choose physical page `0` through `E`.
4. Select **Viewer** and explicitly select the same target slot.
5. Choose **Load**.
6. Enter the source device and filename.
7. Answer whether the input file contains a six-byte GRAM Kracker header.
8. Inspect the beginning of the loaded page.
9. Repeat for every page.

For executable cartridge GROMs, `>AA` is commonly visible in the cartridge header. Data-only pages need not begin with a header.

### GRAM Kracker six-byte header

GROMCFG does not infer the header. If told that the six-byte header exists, it skips those six bytes before loading. A wrong answer shifts the entire GROM image.

## EEPROM and mapping data

The ATmega1284P has 4 KiB of EEPROM. The protected low portion contains UberGROM configuration/mapping; the remaining EEPROM is available for application storage.

The configuration interface also uses an unlock sequence. JP4 adds a second, independent hardware check: even after software unlock, the protected configuration write is rejected while JP4 is closed.

Because a complete EEPROM image can contain mapping data, importing an EEPROM dump may alter the cartridge map. Plan the final mapping after EEPROM import or restore the intended map afterward.

## Saving/restoring an entire configured device

GROMCFG's whole-device save is **not the same format as a 132 KiB universal-programmer image**.

A GROMCFG device save contains approximately:

```text
120 KiB  emulated GROM Flash data
  4 KiB  EEPROM/configuration
--------
124 KiB  device payload
```

It excludes the final 8 KiB of ATmega firmware. Its EEPROM/configuration ordering is arranged for GROMCFG restoration.

By contrast, a 132 KiB universal-programmer image is:

```text
128 KiB ATmega program Flash
  4 KiB ATmega EEPROM
--------
132 KiB
```

Do not interchange the two formats blindly.

## Advanced settings and finalization

GROMCFG needs access to FlashCtl while programming. Do not remove the FlashCtl mapping or close JP4 until all Flash changes are finished.

A practical finalization sequence is:

1. Finish all GROM page loading and mapping.
2. Test all bases/slots.
3. Save a complete GROMCFG backup.
4. Make any desired final advanced-setting changes.
5. Exit GROMCFG and cold-boot/test the cartridge.
6. If the cartridge should be locked against later GROMCFG Flash/configuration changes, power off and **close JP4**.

With JP4 closed, GROMCFG will not be able to rewrite the protected Flash/configuration areas until the jumper is opened again.

## Reference implementation and tests

Tursi's current source tree also includes `gromtest`, which exercises the UberGROM devices from TI code:

- https://github.com/tursilion/ubergrom/tree/main/gromtest

Use that source as the implementation reference for GROM read/write patterns, GPIO, ADC, UART, FlashCtl, timer, RAM, and EEPROM tests.
