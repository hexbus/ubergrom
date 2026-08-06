# Burning prebuilt UberGROM cartridge images

This chapter covers the common question: **“I already have the cartridge image files. Which chips do I program, and what settings do I use?”**

## 1. Identify the supplied files

A complete release may contain one or two programmer images:

| Image | Required? | Destination |
|---|---|---|
| ATmega1284P/UberGROM image, commonly 132 KiB | Always | ATmega1284P |
| ROM image, normally 512 KiB | Only when supplied by the release | 29F040, 39SF040, or 49F040-compatible flash |

The ROM file is not a substitute for the ATmega image, and the ATmega image is not a substitute for the ROM file. They program different devices and serve different address spaces.

A GROM-only cartridge may legitimately have no separate ROM image. A ROM/GROM cartridge that was released with both files requires both.

## 2. Program the ATmega1284P

1. Select **ATmega1284P** in the programmer software. Do not select ATmega128, ATmega1280, or another similarly named device.
2. Erase the device.
3. Load the supplied ATmega programmer image.
4. Configure the fuse bytes as documented for the image.
5. Program flash and fuses.
6. Read the device back and verify it against the source image.
7. Install the ATmega1284P in the correct orientation.

## 3. ATmega1284P fuse settings

Use the following fuse bytes for the standard UberGROM firmware:

| Fuse byte | Value |
|---|---:|
| Extended | `FF` |
| High | `D8` |
| Low | `C2` |

These values are the project-maintainer-confirmed production settings and match the supplied programmer screenshot. Programmer software varies in how it labels, masks, or displays unused fuse bits, so confirm that the programmer's decoded options correspond to the intended configuration rather than relying only on the displayed hexadecimal summary.

The intended configuration is:

- **Extended `FF`** — brown-out detection disabled.
- **High `D8`** — 4096-word/8192-byte boot section selected and reset directed to the boot section.
- **Low `C2`** — calibrated internal 8 MHz RC oscillator, clock divide-by-8 disabled, with the startup-delay selection used by known working cartridges.

The older `F8/D8/C2` value published in the AtariAge start-here post should be treated as a transcription error in the extended fuse. The correct extended fuse is `FF`.

After programming, read all three fuse bytes back from the ATmega1284P and verify `FF/D8/C2` before installing it in the cartridge.

## 4. Program the optional ROM flash

When a 512 KiB ROM image is supplied:

1. Select the exact installed flash device or a programmer-supported compatible device.
2. Erase the chip.
3. Load the 512 KiB image without byte swapping or bank reversal.
4. Program the image.
5. Verify the complete chip.
6. Install it in the PLCC socket in the correct orientation.

The UberGROM board's 74LS378 banking is non-inverted. A ROM image prepared for an older inverted 74LS379 board may have its 8 KiB banks in reverse physical order and must be converted before use. Do not reverse a release image unless its documentation explicitly identifies it as an inverted image.

## 5. First power-on checks

- Confirm the ATmega and ROM flash orientations.
- Confirm JP8 is closed so the cartridge receives the console reset signal.
- Use the normal JP1/JP3 positions documented for the board revision.
- Leave the UberGROM write-protect jumper open while configuration changes are required.
- Power on while holding **Space** when recovery/GROMCFG access is needed.

If a release contains both an ATmega image and a ROM image but only the GROM menu appears, verify the ROM chip separately. If no cartridge entry appears, verify the ATmega image, fuse settings, orientation, reset jumper, and GROM configuration.
