# UberGROM Cartridge Reference

> **Technical reference draft.** This documentation is being rebuilt from the final PCB/schematic, the original board manual, released UberGROM source, GROMSim/GROMCFG material, AtariAge design discussions, known-good cartridge images, and current designer review. Items still requiring confirmation are kept in [`docs/VALIDATION-LEDGER.md`](docs/VALIDATION-LEDGER.md) rather than presented as fact.

The UberGROM cartridge board combines two **independent** cartridge resources:

1. **ATmega1284P UberGROM subsystem** — emulates TI GROM/GRAM and exposes EEPROM, GPIO, ADC, UART, FlashCtl, timer, and RAM through the TI GROM interface.
2. **512 KiB bank-switched ROM subsystem** — a separate 512 KiB flash device divided into sixty-four non-inverted 8 KiB banks selected by a 74LS378 latch.

There is no firmware programming path between these two subsystems. The ATmega does not program the external U2 ROM, and the U2 ROM bank hardware does not program or configure the ATmega.

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
| Build a cartridge containing several independent GROM and/or ROM programs | [Multi-program cartridges](docs/06-multi-program-cartridges.md) |
| See contributed GPL, UART, and ADC application examples | [Examples](examples/README.md) |
| Identify jumpers, ISP pins, and board subsystems | [Hardware reference](docs/05-hardware-reference.md) |
| Review open questions and resolved corrections | [Validation ledger](docs/VALIDATION-LEDGER.md) |

## What files may be supplied with a cartridge

For a **blank ATmega1284P**, the UberGROM program Flash is not enough by itself: the 4 KiB EEPROM contains the mapping/configuration that makes the cartridge content useful. A complete blank-chip release should therefore provide the ATmega content in one of these forms:

- **one combined 132 KiB image** containing 128 KiB program Flash followed by 4 KiB EEPROM; or
- **two separate images**: 128 KiB program Flash plus the matching 4 KiB EEPROM image.

If the cartridge also uses the external U2 ROM, its 512 KiB ROM image is supplied in addition to the ATmega image(s). A GROM-only cartridge legitimately has no U2 image.

A lone 128 KiB ATmega Flash file is best treated as an **update artifact for an already configured cartridge**, unless the release explicitly explains how the required EEPROM configuration will be created.

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

The 74LS378 has **no guaranteed power-up bank**, so released software must establish the bank it expects instead of assuming a particular cold-start state.

For hardware testing, Tursi's [BankTest](https://github.com/tursilion/banktest) can identify the bank observed on a particular cold power-up and marks it with `*`. In practical experience many parts tend to start at one end of the bank range, often the first or last bank, but that observation is not a design guarantee.

For reliable software:

- a ROM-only design should provide a valid startup/header path in every possible bank and make the first program instruction select the canonical bank; or
- a ROM/GROM design may use a **GROM power-up link** to establish the desired ROM bank before ROM execution.

Also remember that **QUIT is a software reset and does not reset the ROM latch**. A program may return to the console with any ROM bank still selected unless its startup path deliberately establishes the expected bank.

## Primary sources

- Hardware/documentation repository: https://github.com/hexbus/ubergrom
- Tursi's UberGROM firmware and test software: https://github.com/tursilion/ubergrom
- Mega UberGROM thread: https://forums.atariage.com/topic/305712-the-mega-ubergrom-thread-start-here/
- Bank-switching discussion: https://forums.atariage.com/topic/345895-bank-switching/
- Tursi BankTest: https://github.com/tursilion/banktest
- Multi-bank ROM discussion: https://forums.atariage.com/topic/350614-rom-cartridge-with-multiple-banks/
- Banked-cartridge conventions: https://forums.atariage.com/topic/364796-code-conventions-for-bank-switched-cartridges/
- Bank-image construction help: https://forums.atariage.com/topic/326457-bank-switch-cartridge-files-help/
- ATmega1284P manufacturer documentation: https://www.microchip.com/en-us/product/atmega1284p


## Multi-program cartridges

A genericized launcher derived from a tested two-application implementation demonstrates how one GPL/GROM header can contribute multiple menu entries that launch different banked applications in U2, while other mapped GROMs independently contribute additional menu entries. The 1979 **Milton Bradley Gamevision Demonstration Cartridge** provides a complementary historical example: its demo/menu and independently headed Gamevision titles occupy several logical GROM slots on one cartridge.

See [Building multi-program UberGROM cartridges](docs/06-multi-program-cartridges.md) and [`examples/gpl-multi-program-menu/`](examples/gpl-multi-program-menu/).
