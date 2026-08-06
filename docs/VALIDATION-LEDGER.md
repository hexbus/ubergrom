# Validation ledger

This ledger prevents unresolved historical statements from leaking into the user-facing manual as fact.

## ATmega1284P fuse bytes

**Status: resolved by project-maintainer confirmation.**

The standard UberGROM firmware uses:

- Extended: `FF`
- High: `D8`
- Low: `C2`

The supplied programmer screenshot matches these values. The older AtariAge value `F8/D8/C2` contains an incorrect extended-fuse byte and should be treated as a transcription error. The AVR Studio project value `FF/D8/E2` records a different startup-delay choice and is not the production setting to publish in the cartridge-programming instructions.

Retain the practical warning that individual programmer applications may display or mask unused fuse bits differently. The user should verify the decoded settings and perform a fuse readback after programming.

## ATmega programmer-image layout

**Status: resolved from released GROMSim documentation, formatter source, known-good images, and project-maintainer programming practice.**

- ATmega program Flash is 128 KiB and occupies unified programmer-buffer offsets `>00000–>1FFFF`.
- ATmega EEPROM is 4 KiB and occupies unified programmer-buffer offsets `>20000–>20FFF`.
- A combined Flash+EEPROM image is therefore 132 KiB (`>21000` bytes) and is loaded at `>00000` with **Include EEPROM** enabled.
- When supplied separately, load the 128 KiB Flash image at `>00000` and the 4 KiB EEPROM image at `>20000` without clearing the existing buffer, then enable **Include EEPROM**.
- The `>20000` position is a file/programmer-buffer convention; the AVR EEPROM itself is a separate address space beginning at EEPROM address `>0000`.
- A 128 KiB Flash-only file intentionally contains no EEPROM data. Do not append erased bytes or enable EEPROM programming unless erasing/replacing configuration and save data is intended.

Keep this format separate from GROMCFG's “Save Entire Device” format, which contains 120 KiB of GROM data plus 4 KiB of rearranged EEPROM and omits the final 8 KiB firmware section.

## GPIO count and pad assignment

The draft manual states four GPIO pins, while some historical text and video remarks are uncertain. Verify against the final PCB revision, schematic, and firmware routing. Publish examples only for physically routed pins.

## ROM chip compatibility

The repository currently names 39SF040, while historical boards and image instructions name 29F040 and 49F040. Confirm programmer and board compatibility details, voltage requirements, pin compatibility, and any manufacturer-specific exceptions before presenting a blanket supported-device list.

## Hand-assembled trampoline opcodes

The example in `03-rom-bank-switching.md` is conceptually correct but hand-encoded opcode constants must be assembled and tested with the target assembler before being promoted as a copy-and-run example. The final examples should include source, binary output, and a small test cartridge.

## Board power-up bank behavior

The 74LS378 lacks a guaranteed initialized state. Test multiple manufacturers/date codes and retain the conservative requirement for headers or equivalent recovery vectors in all banks.

## Extended-feature demonstrations

Create and test one minimal cartridge for each:

- UART echo/terminal at base 15, slot `>A000`;
- GPIO input/output;
- ADC live display;
- timer interval measurement;
- EEPROM save/restore with CRC;
- RAM page read/write;
- FlashCtl example limited to a disposable development device.

Each example should document mapping byte, base, slot, wiring, register addresses, build command, and expected output.

## Confirmed implementation limitation: JP4 write protect

**Status:** Confirmed by Jon Guidry for the current UberGROM implementation.

Although the PCB, schematic, and historical manual identify JP4 as an UberGROM write-protect input, current firmware does not implement the protective behavior. Documentation must not instruct users to open or close JP4 as though it currently protects GROM flash, EEPROM, save data, or ATmega program Flash. Any future claim that JP4 is functional must identify and verify the firmware revision that implements it.
