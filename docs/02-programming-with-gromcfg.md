# Programming the UberGROM with GROMCFG

GROMCFG configures the ATmega1284P portion of the cartridge from a TI-99/4A. It maps physical UberGROM devices into logical TI GROM locations and loads data into mapped GROM pages.

GROMCFG does **not** program the separate 512 KiB ROM flash.

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

The firmware exposes five cartridge-usable 8 KiB GROM slots in each base:

```text
>6000  >8000  >A000  >C000  >E000
```

The console-reserved `>0000`, `>2000`, and `>4000` slots are intentionally not overridden by this cartridge firmware.

### Physical page

The ATmega has fifteen physical 8 KiB GROM pages, numbered 0 through 14 (`>0` through `>E`). Mapping controls where each physical page appears in the TI's logical base/slot space. Mapping the same page more than once does not create another copy.

## Recovery startup

1. Install a correctly programmed ATmega1284P in the cartridge.
2. JP4 does not currently implement write protection, so its position does not affect programming. Do not rely on it to protect existing GROM flash or EEPROM contents.
3. Insert the cartridge with the console powered off.
4. Hold **Space** while powering on.
5. Continue holding Space through the initial startup scan.
6. Select **RUN PROGRAM FILE** from the recovery menu.
7. Load `GROMCFG` from the supplied `GROMCFG.dsk`, mass storage, RAM disk, or another supported device.

The recovery loader is inserted only on the first power-up scan. A software reset or `FCTN`+`=` does not recreate that first-power-up event; power-cycle the console and hold Space again.

## Recommended planning worksheet

Before changing the cartridge, write down the intended mapping:

| Logical base | Slot | Device | Physical page/file |
|---:|---:|---|---|
| `>9800` | `>6000` | GROM | page 0 / `GAMEG1.BIN` |
| `>9800` | `>8000` | GROM | page 1 / `GAMEG2.BIN` |
| `>983C` | `>A000` | UART | page 0 |
| `>983C` | `>E000` | FlashCtl | page 0, required by GROMCFG while programming |

This prevents loading a file into the wrong physical page or reusing a page unintentionally.

## Mapping and loading a GROM image

1. Use `FCTN`+left/right to select the target GROM base.
2. Select the target slot by pressing `6`, `8`, `A`, `C`, or `E`.
3. Choose **GROM** and select a physical page from 0 through E.
4. Press `V` and select the same slot so the viewer is explicitly pointed at the intended page.
5. Press `L` to load a PROGRAM-format file.
6. Enter the device and filename.
7. Answer whether the file has a six-byte GRAM Kracker header.
8. Inspect the first bytes in the viewer. Executable cartridge GROMs commonly begin with `>AA`; data-only GROM pages may not.
9. Repeat for each page.

The six-byte-header question is not auto-detected. GROMCFG simply skips six bytes when told to do so. A wrong answer shifts the entire image.

## Important EEPROM ordering rule

Loading a full EEPROM image can overwrite the mapping table. When importing EEPROM content, load the EEPROM data first and then configure the final mapping, or be prepared to restore the mapping afterward.

## Saving and restoring the entire ATmega device

`Control-S` saves the complete device state:

1. 120 KiB of GROM flash data,
2. 4 KiB of EEPROM, including configuration.

The file uses DF128 records and requires approximately 124 KiB plus filesystem overhead. A single-sided, single-density 90 KiB disk is too small.

`Control-L` restores a complete device save and overwrites the GROM flash and EEPROM configuration.

The `formatter` utility included with GROMSim can split a complete device save into flash and EEPROM programmer files for programming outside the TI.

## Advanced settings and finalization

GROMCFG depends on multiple-base operation and a FlashCtl mapping at base 15, slot `>E000`, while it is programming the device. Actions that disable those facilities should be performed only after all loading and backup operations are complete.

Advanced settings include:

- enable/disable independent GROM bases;
- enable/disable the recovery loader;
- enable/disable address rollover behavior;
- remove the FlashCtl mapping.

After finalization:

1. Save a complete device backup.
2. Quit GROMCFG.
3. Power-cycle and test every menu entry.
4. Test any ROM component separately.
5. Do not rely on JP4 as a final write-protect mechanism; the current firmware does not implement it. Remove the FlashCtl mapping when appropriate and retain a verified backup instead.
