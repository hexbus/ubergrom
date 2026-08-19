# UberGROM examples

This directory collects practical TI-side examples contributed by UberGROM users.

These examples are **not replacements for Tursi's firmware source or test suite**. For the authoritative implementation tests for EEPROM, RAM, GPIO, ADC, UART, FlashCtl, and timer, see Tursi's upstream `gromtest` directory:

- https://github.com/tursilion/ubergrom/tree/main/gromtest

The examples here show how real applications have used those interfaces.

## Included contributions

| Directory | Contributor | Interface | What it demonstrates |
|---|---|---|---|
| [`uart-telco-tim`](uart-telco-tim/) | Tim / InsaneMultitasker | UART | 38.4K 8N1 terminal-style transmit, receive-count polling, draining the UberGROM receive FIFO into a larger RAM circular buffer |
| [`adc-digitizer-fg-kaal`](adc-digitizer-fg-kaal/) | Fred Kaal / F.G. Kaal | ADC | Reading two UberGROM ADC channels from TMS9900 assembly and returning the values to TI BASIC for a two-link digitizer |

## Contribution policy

When adding an example:

- preserve the original author's credit;
- identify the required GROM base/slot mapping;
- state any external library or hardware requirements;
- distinguish historical application-specific code from a minimal interface example;
- do not copy or modify Tursi's UberGROM firmware source into this repository without respecting its upstream license.
