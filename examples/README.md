# UberGROM examples

This directory collects practical TI-side examples and design patterns for UberGROM.

These examples are **not replacements for Tursi's firmware source or test suite**. For the authoritative implementation tests for EEPROM, RAM, GPIO, ADC, UART, FlashCtl, and timer, see Tursi's upstream `gromtest` directory:

- https://github.com/tursilion/ubergrom/tree/main/gromtest

## Included examples

| Directory | Source / contributor | Interface | What it demonstrates |
|---|---|---|---|
| [`gpl-multi-program-menu`](gpl-multi-program-menu/) | genericized from a tested two-application implementation | GPL + U2 banking | One GROM header contributing multiple TI menu entries and launching U2 applications through a scratchpad bank-switch trampoline |
| [`mb-games-layout`](mb-games-layout/) | historical layout analysis | GROM slots | 1979 Milton Bradley Gamevision dealer-demo layout with independently headed programs at several logical GROM slots |
| [`uart-telco-tim`](uart-telco-tim/) | Tim / InsaneMultitasker | UART | 38.4K 8N1 terminal-style transmit, receive-count polling, draining the UberGROM receive FIFO into a larger RAM circular buffer |
| [`adc-digitizer-fg-kaal`](adc-digitizer-fg-kaal/) | Fred Kaal / F.G. Kaal | ADC | Reading two UberGROM ADC channels from TMS9900 assembly and returning the values to TI BASIC for a two-link digitizer |

The GPL multi-program source has deliberately generic application names and U2 target addresses. The **technique** was validated in a working cartridge; adapt and test the public sample values for your own ROM layout.

## Contribution policy

When adding an example:

- preserve the original author's credit;
- identify the required GROM base/slot mapping;
- state any external library or hardware requirements;
- distinguish historical application-specific code from a minimal interface example;
- distinguish a tested implementation from a genericized or illustrative derivative; and
- do not copy or modify Tursi's UberGROM firmware source into this repository without respecting its upstream license.

## Examples requested / not yet included

Additional community examples have been requested but should not be documented as available until working source is contributed and reviewed:

- a practical **user EEPROM save/high-score** example showing persistent application storage without touching the protected mapping/configuration area; and
- an **UberHDX serial/UART** application example showing another real-world use of the UART interface.

When these are contributed, preserve the original author's source and attribution and document the required UberGROM base/slot mapping alongside the example.
