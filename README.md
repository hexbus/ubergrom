# UberGROM Cartridge Reference

> **Technical reference draft.** This documentation is being rebuilt from the final PCB/schematic, the original board manual, released UberGROM source, GROMSim/GROMCFG material, AtariAge design discussions, known-good cartridge images, and current designer review. Items still requiring confirmation are kept in [`docs/VALIDATION-LEDGER.md`](docs/VALIDATION-LEDGER.md) rather than presented as fact.

The UberGROM cartridge board combines two **independent** cartridge resources:

1. **ATmega1284P UberGROM subsystem** — emulates TI GROM/GRAM and exposes EEPROM, GPIO, ADC, UART, FlashCtl, timer, and RAM through the TI GROM interface.
2. **512 KiB bank-switched ROM subsystem** — a separate 512 KiB flash device divided into sixty-four non-inverted 8 KiB banks selected by a 74LS378 latch.

There is no firmware programming path between these two subsystems. The ATmega does not program the external U2 ROM, and the U2 ROM bank hardware does not program or configure the ATmega.

For normal operation, **JP1 stays at 1-2 (U2 write disabled)**. The board does not currently provide a complete in-circuit programming path for U2; ROM bank switching uses TI write cycles only to clock the 74LS378 bank latch.

## Software authorship and project scope

The **UberGROM AVR firmware and associated software are Mike Brent/Tursi's code**. The authoritative upstream source and its license are maintained in Tursi's repository:

- https://github.com/tursilion/ubergrom

This repository documents the cartridge hardware, image formats, configuration process, ROM banking, and use of the released UberGROM software. It does **not** claim ownership of, relicense, or make Tursi responsible for maintaining this documentation.

The cartridge hardware was a collaborative project involving **James "Jim" Fetzner (Ksarul), Jon Guidry (acadiel/hexbus), and Mike Brent (Tursi)**, with contributions and review from the TI community. Individual software retains the authorship and license stated in its source.

## Start here

| Goal | Documentation |
|---|---|
| Burn an existing GROM or ROM/GROM cartridge image | [Burning prebuilt images](docs/01-burning-prebuilt-images.md) |
| Load or construct GROM content on a TI using GROMCFG | [Programming with GROMCFG](docs/02-programming-with-gromcfg.md) |
| Build a 16 KiB–512 KiB bank-switched ROM program | [ROM bank switching](docs/03-rom-bank-switching.md) |
| Use UART, GPIO, ADC, timer, RAM, EEPROM, or FlashCtl | [Extended features](docs/04-extended-features.md) |
| Identify jumpers, ISP pins, and board subsystems | [Hardware reference](docs/05-hardware-reference.md) |
| Review open questions and resolved corrections | [Validation ledger](docs/VALIDATION-LEDGER.md) |

## What files may be supplied with a cartridge

A complete release for programming a **blank ATmega1284P** must include both the ATmega Flash contents **and** the 4 KiB EEPROM configuration that tells UberGROM what is mapped where. Package those as either:

- **one 132 KiB combined ATmega image** (128 KiB Flash + 4 KiB EEPROM), or
- **two ATmega files**: 128 KiB Flash plus a separate 4 KiB EEPROM image.

If the cartridge also uses the separate U2 ROM, include its ROM image as well. A 128 KiB ATmega Flash-only file is useful as an **update image** when an already-configured EEPROM is intentionally being preserved, but it is not a complete blank-chip release by itself.

See [Burning prebuilt images](docs/01-burning-prebuilt-images.md) before programming a device.

## Capacity at a glance

| Resource | Capacity | Organization |
|---|---:|---|
| External cartridge ROM | 512 KiB | 64 × 8 KiB banks at CPU `>6000–>7FFF` |
| ATmega Flash used for emulated GROM | 120 KiB | 15 × 8 KiB physical GROM pages |
| ATmega boot/firmware section | 8 KiB | final 8 KiB of the 128 KiB ATmega Flash |
| SRAM exposed by UberGROM | 15 KiB | one 8 KiB page and one 7 KiB page |
| ATmega EEPROM | 4 KiB | mapping/configuration plus application storage |
| Logical GROM bases | 16 | CPU read-data ports `>9800, >9804, ... >983C` |

**Logical mapping space is not physical storage capacity.** The firmware can map devices into many logical base/slot combinations, but the ATmega1284P still contains only fifteen physical 8 KiB GROM pages.

## ROM bank selection summary

This board uses a **non-inverted 74LS378 address-selected mapper**. Bank *n* is selected by a write to:

```text
>6000 + (n × 2), where n = 0 through 63
```

Examples:

```asm
       CLR  @>6000          ; bank 0
       CLR  @>6002          ; bank 1
       CLR  @>6004          ; bank 2
       CLR  @>6006          ; bank 3
       ...
       CLR  @>607E          ; bank 63
```

On this board, **the data value written is immaterial**. The write address supplies the six bank bits. `CLR` is merely a convenient way to cause the write.

The complete `>6000–>7FFF` window changes immediately. Code must therefore switch while executing from RAM or use an identical transition sequence at the same address in the source and destination banks.


## Critical ROM startup rule

The 74LS378 has **no guaranteed power-up bank**. Software must not depend on a particular startup bank.

That does not mean an individual cartridge cannot be characterized. Tursi's [BankTest](https://github.com/tursilion/banktest) utility tests all banks and, in version 2 and later, places an asterisk (`*`) next to the bank detected at cold power-up. In practical experience with these boards, the first or last ROM bank is commonly observed, but that is an empirical observation only—not a specification or a safe assumption for released software.

For reliable hardware:

- a ROM-only design should provide a valid startup/header path in **every possible bank**, normally by placing a small header/canonical-bank stub in every bank; or
- a ROM/GROM design may use a **GROM power-up link** to establish the desired ROM bank before ROM execution.

Also remember that **QUIT is a software reset and does not reset the ROM latch**. BankTest's startup-bank indication is therefore meaningful only immediately after an actual power cycle, before other software has changed the latch. A program may return to the console with any ROM bank still selected unless the software deliberately canonicalizes it or a GROM power-up path does so.

## Primary sources

- Hardware/documentation repository: https://github.com/hexbus/ubergrom
- Tursi's UberGROM firmware and test software: https://github.com/tursilion/ubergrom
- Tursi's BankTest utility: https://github.com/tursilion/banktest
- Mega UberGROM thread: https://forums.atariage.com/topic/305712-the-mega-ubergrom-thread-start-here/
- Bank-switching discussion: https://forums.atariage.com/topic/345895-bank-switching/
- Multi-bank ROM discussion: https://forums.atariage.com/topic/350614-rom-cartridge-with-multiple-banks/
- Banked-cartridge conventions: https://forums.atariage.com/topic/364796-code-conventions-for-bank-switched-cartridges/
- Bank-image construction help: https://forums.atariage.com/topic/326457-bank-switch-cartridge-files-help/
- ATmega1284P manufacturer documentation: https://www.microchip.com/en-us/product/atmega1284p
