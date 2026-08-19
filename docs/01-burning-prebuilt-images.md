# Burning prebuilt UberGROM cartridge images

This chapter answers the common question: **“I already have the cartridge image files. What do I load, at what offset, and which memory gets programmed?”**

The board contains two independent programmable devices:

- **U3 ATmega1284P** — UberGROM firmware, emulated GROM content, configuration, and optional persistent data.
- **U2 external 512 KiB ROM flash** — the separate bank-switched CPU ROM.

Programming one does not program the other.

## 1. Identify the supplied files

A complete release intended to program a **blank ATmega1284P** must provide both the AVR program Flash and the EEPROM configuration that maps the cartridge content. Typical files are:

| File type | Typical size | Destination |
|---|---:|---|
| ATmega Flash-only image | 128 KiB (`>20000`) | ATmega1284P program Flash |
| ATmega EEPROM image | 4 KiB (`>1000`) | ATmega1284P EEPROM |
| Combined ATmega image | 132 KiB (`>21000`) | 128 KiB Flash + 4 KiB EEPROM |
| Cartridge ROM image | usually 512 KiB (`>80000`) | separate U2 ROM flash |

For blank-chip programming, expect either a **combined 132 KiB ATmega image** or the matching **128 KiB Flash + 4 KiB EEPROM pair**. If the cartridge also uses U2 ROM, its ROM image is supplied in addition. A GROM-only cartridge legitimately has no U2 ROM image.

A lone 128 KiB Flash image is not normally a complete blank-chip release because little useful content will be mapped until the EEPROM is configured. Treat Flash-only files as updates for an already configured cartridge unless the release explicitly provides another configuration procedure.

## 2. Understand the ATmega programmer-buffer layout

Many universal programmers present ATmega program Flash and EEPROM in one unified file buffer:

```text
Unified programmer/file buffer

>00000 ┌──────────────────────────────────────┐
       │ ATmega1284P program Flash            │
       │ 128 KiB                              │
       │                                      │
>1FFFF └──────────────────────────────────────┘
>20000 ┌──────────────────────────────────────┐
       │ ATmega1284P EEPROM                   │
       │ 4 KiB                                │
>20FFF └──────────────────────────────────────┘
```

The important distinction is:

> `>20000` is the **file/programmer-buffer offset** used to represent the EEPROM after the 128 KiB Flash. The AVR EEPROM is physically a separate memory space whose own address range is `>0000–>0FFF`.

### Combined 132 KiB image

If the supplied file is exactly `>21000` bytes (132 KiB):

1. Select **ATmega1284P**.
2. Load the complete file at buffer address `>00000`.
3. Enable the programmer option usually called **Include EEPROM**, **Program EEPROM**, or equivalent.
4. Program and verify.

The programmer should route:

```text
file >00000–>1FFFF  -> ATmega program Flash
file >20000–>20FFF  -> ATmega EEPROM
```

### Separate 128 KiB Flash + 4 KiB EEPROM

When the release supplies the two images separately:

1. Load the 128 KiB Flash image at `>00000`.
2. **Without clearing the buffer**, load the 4 KiB EEPROM image at `>20000`.
3. Enable **Include EEPROM**.
4. Program and verify both memories.

In a programmer with separate Flash and EEPROM tabs/buffers, the equivalent operation is to load the 128 KiB file into Flash at Flash `>00000` and the 4 KiB file into EEPROM at EEPROM `>0000`.

### Flash-only 128 KiB image

If only a 128 KiB ATmega Flash file is provided:

- load it at `>00000`;
- do **not** invent or append 4 KiB of `>FF` bytes;
- do not program EEPROM unless the release instructions explicitly say to erase or replace it.

A Flash-only file is useful for updating an already configured cartridge, but it is generally **not sufficient for a blank ATmega1284P**. The matching EEPROM configuration must already exist or be created separately with GROMCFG.

**Important:** with High fuse `D8`, `EESAVE` is unprogrammed, so a normal AVR Chip Erase does **not** preserve EEPROM. Back up the existing 4 KiB EEPROM first, or use a programmer mode that explicitly preserves it.

## 3. Internal layout of the 128 KiB ATmega Flash image

For the ATmega1284P build used by this board:

```text
>00000–>1DFFF   120 KiB: fifteen 8 KiB physical GROM pages
>1E000–>1FFFF     8 KiB: UberGROM firmware / boot section
```

This is why a **128 KiB** file can still contain both cartridge GROM content and Tursi's UberGROM firmware.

The separate 4 KiB EEPROM stores mapping/configuration and can also store application data such as settings or high scores.

## 4. ATmega1284P fuse settings

### Recommended ATmega1284P setting

For newly programmed ATmega1284P devices, use Tursi's recommended setting:

| Fuse | Byte |
|---|---:|
| Extended | `FC` |
| High | `D8` |
| Low | `C2` |

![Tursi XGPro fuse example](images/tursi-xgpro-fuses-fc.png)

The important difference is brown-out detection. TI power supplies are now decades old and the 5 V rail can be slow or uneven while coming up. `FC` enables the approximately 4.3 V brown-out threshold so the AVR does not begin executing until the supply is in a stable operating range. The AVR still starts well before normal TI cartridge boot processing needs it.

Jon Guidry has historically used `FF/D8/C2` successfully on existing cartridges:

![Historical FF/D8/C2 fuse setting](images/atmega1284p-fuse-settings.png)

`FF/D8/C2` is therefore useful historical/reference information, but **`FC/D8/C2` is the recommended setting for new ATmega1284P programming**.

### Document the fuse *functions*, not only the hex bytes

Raw fuse bytes are ATmega1284P-specific. Tursi's firmware was written to be portable to suitable AVR targets, so a port to another AVR must reproduce the intended **functions** using that device's own fuse definitions rather than copying `FF/D8/C2`.

On the ATmega1284P, remember that AVR fuse bits use `0 = programmed` and `1 = unprogrammed`.

#### Low fuse `C2`

`C2 = 1100 0010`

| Bit/function | Setting | Purpose |
|---|---|---|
| CKDIV8 | 1 | divide-by-8 disabled |
| CKOUT | 1 | clock output disabled |
| SUT1:SUT0 | `00` | startup selection used by this build |
| CKSEL3:0 | `0010` | calibrated internal ~8 MHz RC oscillator |

#### High fuse `D8`

`D8 = 1101 1000`

| Bit/function | Setting | Purpose |
|---|---|---|
| OCDEN | 1 | on-chip debug disabled |
| JTAGEN | 1 | JTAG disabled |
| SPIEN | 0 | serial/ISP programming enabled |
| WDTON | 1 | watchdog not forced always-on |
| EESAVE | 1 | EEPROM **not preserved** by Chip Erase |
| BOOTSZ1:0 | `00` | 4096-word / 8192-byte boot section |
| BOOTRST | 0 | reset vector enters boot section |

For ATmega1284P, the 8192-byte boot area occupies the final 8 KiB of program Flash, matching the UberGROM firmware location at file offsets `>1E000–>1FFFF`.

#### Extended fuse

Only `BODLEVEL2:0` are implemented:

| Extended byte | BODLEVEL | Meaning |
|---|---|---|
| `FF` | `111` | brown-out detector disabled |
| `FC` | `100` | approximately 4.3 V brown-out threshold |

For this board, prefer `FC`: the defined brown-out threshold helps keep the MCU held in reset while an aging TI supply is still rising or has fallen below a reliable operating voltage.

### Programmer display differences

Different universal programmers may:

- show only implemented extended-fuse bits;
- mask unused bits;
- label a checked box as “programmed = 0”;
- display the same functional setting with a different visual convention.

Therefore verify the decoded bit functions, then **read the fuses back** after programming.

## 5. Program the optional external ROM

If the release supplies a U2 ROM image:

1. Select the exact installed 29F040/49F040-compatible part supported by your programmer.
2. Erase the device.
3. Load the ROM image at ROM offset `>00000`.
4. Program without byte swapping.
5. Verify the entire device.
6. Install in the correct orientation.

The board's 74LS378 scheme is **non-inverted**. Images built for older inverted 74LS379 cartridge boards may require 8 KiB bank-order conversion, but a release image intended for this board should be programmed as supplied.

## 6. JP4 when configuring or finalizing a cartridge

JP4 is the **ATmega/UberGROM write-protect input**, not a control for U2.

- **JP4 open:** UberGROM FlashCtl and protected configuration writes are permitted.
- **JP4 closed:** PC7 is grounded; the released firmware blocks FlashCtl writes and writes to the protected EEPROM configuration region.

JP4 is the intended **distribution lock** for the UberGROM subsystem. It does not affect the separate U2 ROM or normal user EEPROM/save storage.

See [Hardware reference](05-hardware-reference.md) for the exact scope of the protection.

## 7. First power-on checklist

- Confirm U2 and U3 orientation.
- Confirm the ATmega fuse functions and readback.
- Confirm JP8 is in its normal closed position.
- Keep JP4 open if GROMCFG must change Flash or mapping.
- If a separate U2 ROM image was supplied, verify U2 independently.
- Hold **Space** during cold power-up when the UberGROM recovery/GROMCFG path is required.

If a cartridge has GROM but no expected ROM behavior, troubleshoot U2 separately: the ATmega does not program or control U2's contents.

## Source references

- ATmega1284P datasheet: https://www.microchip.com/en-us/product/atmega1284p
- UberGROM firmware/software by Mike Brent/Tursi: https://github.com/tursilion/ubergrom
