# UberGROM Cartridge Reference

> **Technical draft for review.** This documentation is being rebuilt from the original board manual, the [GROMSim](https://github.com/tursilion/ubergrom) source and documentation, the AtariAge development
[threads](https://github.com/hexbus/ubergrom/blob/main/README.md#primary-project-sources) , the board schematic, and working cartridge practice. Items that are not yet reconciled are isolated in [`docs/VALIDATION-LEDGER.md`](docs/VALIDATION-LEDGER.md) rather than presented as settled fact.

![IMG_3367](https://github.com/user-attachments/assets/81efbad9-1caf-4bbf-b794-7bbb3c35c5da)
![IMG_3368](https://github.com/user-attachments/assets/ae26573b-c1d6-400a-9539-089aa93326dd)
---

The UberGROM cartridge board combines two independent cartridge resources:

1. **ATmega1284P UberGROM subsystem** — emulates TI GROM/GRAM and exposes EEPROM, GPIO, ADC, UART, flash-controller, timer, and RAM devices through the TI GROM interface.
2. **512 KiB bank-switched ROM subsystem** — a separate 29F040/39SF040/49F040-compatible 512 KiB flash device divided into sixty-four non-inverted 8 KiB banks selected through a 74LS378 latch.

A cartridge image may therefore contain:

- a required **ATmega1284P image** (commonly described as a 132 KiB programmer image), and
- an optional **512 KiB ROM image**.

The ROM image is optional only in the sense that some cartridges are GROM-only. When a distributed cartridge image includes a ROM component, that ROM is part of the software and must also be programmed.

## Start here

| Goal | Documentation |
|---|---|
| Burn an existing cartridge image with an EPROM/MCU programmer | [Burning prebuilt images](docs/01-burning-prebuilt-images.md) |
| Load or construct GROM content on a TI using GROMCFG | [Programming with GROMCFG](docs/02-programming-with-gromcfg.md) |
| Build a 16 KiB–512 KiB assembly cartridge | [ROM bank switching](docs/03-rom-bank-switching.md) |
| Use UART, GPIO, ADC, timer, RAM, EEPROM, or flash control | [Extended features](docs/04-extended-features.md) |
| Assemble and configure the board | [Hardware reference](docs/05-hardware-reference.md) |
| See unresolved source conflicts and required tests | [Validation ledger](docs/VALIDATION-LEDGER.md) |

## Capacity at a glance

| Resource | Capacity | Organization |
|---|---:|---|
| Cartridge ROM flash | 512 KiB | 64 × 8 KiB banks, visible at CPU `>6000–>7FFF` |
| UberGROM flash available for GROM content | 120 KiB | 15 × 8 KiB physical pages |
| SRAM exposed by firmware | 15 KiB | one 8 KiB page and one 7 KiB page |
| EEPROM | 4 KiB | configuration plus application storage |
| Logical GROM bases | 16 | CPU read-data ports `>9800, >9804, ... >983C` |

**Logical address space is not physical capacity.** Sixteen bases provide many places where devices can be mapped, but the ATmega still contains only fifteen physical 8 KiB GROM pages.

## ROM bank selection summary

The 74LS378 design is **non-inverted**. Bank *n* is selected by writing to:

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

On this UberGROM board, the written data value is immaterial: the write address alone supplies the six bank-select bits to the 74LS378. The complete 8 KiB cartridge window changes immediately, so code must switch from RAM or use an identical transition stub at the same address in every participating bank. This rule is specific to this board's address-selected mapper; it must not be generalized to the Gigacart, whose bank-selection protocol also depends on the value written.

## Primary project sources

- Project repository: https://github.com/hexbus/ubergrom
- UberGROM software and GROMSim: http://harmlesslion.com/software/ubergrom
- Mega UberGROM thread: https://forums.atariage.com/topic/305712-the-mega-ubergrom-thread-start-here/
- Bank-switching discussion: https://forums.atariage.com/topic/345895-bank-switching/
- Multi-bank ROM discussion: https://forums.atariage.com/topic/350614-rom-cartridge-with-multiple-banks/
- Banked-cartridge conventions: https://forums.atariage.com/topic/364796-code-conventions-for-bank-switched-cartridges/
- Bank image construction help: https://forums.atariage.com/topic/326457-bank-switch-cartridge-files-help/
