# UberGROM extended features

The UberGROM firmware exposes memory and peripherals through ordinary TI GROM reads and writes.

Unless otherwise noted, the device map and capacities in this chapter describe the **ATmega1284P configuration used on the production UberGROM cartridge board**. Other AVR ports may expose different capacities or pin assignments.

The firmware and reference test code are authored by Mike Brent/Tursi. The current upstream repository is:

- https://github.com/tursilion/ubergrom

The `gromtest` directory is particularly valuable because it contains working TI-side tests for EEPROM, RAM, GPIO, ADC, UART, FlashCtl, and timer:

- https://github.com/tursilion/ubergrom/tree/main/gromtest

The examples in this chapter explain the interface. When there is any doubt about exact behavior, compare against the released source and `gromtest`.

## Device mapping byte

A mapping byte uses:

- high nibble = device type;
- low nibble = device page, when the device is pageable.

| ID | High nibble | Device | Pageable |
|---:|---:|---|---|
| 0 | `>0` | RAM | Yes |
| 1 | `>1` | GROM Flash | Yes, 15 pages |
| 2 | `>2` | EEPROM | No |
| 3 | `>3` | GPIO | No |
| 4 | `>4` | ADC | Yes, 4 channels |
| 5 | `>5` | UART | No |
| 6 | `>6` | Flash controller | No |
| 7 | `>7` | Timer | No |

Examples:

```text
>12 = GROM physical page 2
>30 = GPIO
>43 = ADC channel/page 3
>50 = UART
>60 = FlashCtl
>70 = timer
```

Peripheral register blocks intentionally begin away from the start of the logical GROM slot so they do not resemble a cartridge header.

## The common programming pattern

Tursi's test code demonstrates the core operation clearly:

1. write the 16-bit GROM address through the chosen base's write-address port;
2. read or write bytes through that base's data port.

For base *n*:

```text
Read data     = >9800 + (n × 4)
Read address  = >9802 + (n × 4)
Write data    = >9C00 + (n × 4)
Write address = >9C02 + (n × 4)
```

Most extended-feature examples differ mainly in the GROM address being accessed and the device mapped into that slot.

## TMS9900 helper for base 15

```asm
UGRD   EQU  >983C
UGRA   EQU  >983E
UGWD   EQU  >9C3C
UGWA   EQU  >9C3E

* R0 = 16-bit GROM address. Destroys R1.
SETGADDR
       MOV  R0,R1
       MOVB R1,@UGWA        ; high address byte
       SWPB R1
       MOVB R1,@UGWA        ; low address byte
       RT
```

Remember that `MOVB` uses the high byte of a TMS9900 register.

## GPIO — four physical pins on this PCB

The final cartridge PCB routes **four GPIO pins**. Tursi's `gromtest` likewise treats only the low four bits as valid.

Map GPIO with `>30`.

| Offset | Access | Meaning |
|---:|---|---|
| `>0020` | Write | direction: `0=input`, `1=output` |
| `>0021–>1FFF` | Read/write | pin state; on input pins, written 1 enables pull-up |

Bit assignment:

```text
bit 0 = GPIO0
bit 1 = GPIO1
bit 2 = GPIO2
bit 3 = GPIO3
```

All four reset as inputs with pull-ups disabled.

Tursi's test application repeatedly reads the GPIO state and displays the four low bits, and also exercises output behavior. That code should be treated as the first reference when building a hardware example.

## ADC

There are four analog input channels exposed on JP7.

Map ADC pages with:

```text
>40 = ADC0
>41 = ADC1
>42 = ADC2
>43 = ADC3
```

Reads from the mapped peripheral range trigger a conversion and return an 8-bit value:

```text
0   ≈ low end of input range
255 ≈ high end of input range
```

The original implementation documentation gives approximately 104 µs per conversion and approximately 200 µs for the first conversion after power-up.

`gromtest` contains a live ADC display example and is the best executable reference for the raw interface.

### Contributed ADC application: Fred Kaal digitizer

Fred Kaal (F.G. Kaal) contributed a practical TMS9900/TI BASIC example that reads two ADC channels and uses them as joint sensors for a two-link mechanical digitizer. His assembly routine sets the GROM address to peripheral offset `>0020`, reads the 8-bit ADC result, and assigns the values to TI BASIC variables.

The example as written expects base 0 with ADC channel 0 mapped at slot `>8000` (`>40`) and ADC channel 1 mapped at slot `>A000` (`>41`). See [`examples/adc-digitizer-fg-kaal`](../examples/adc-digitizer-fg-kaal/) for the contributed source and mapping notes.

## UART

JP5 exposes the ATmega UART at **5 V TTL logic levels**. It is not RS-232 voltage level.

A commonly used mapping is UART at base 15, slot `>A000`:

```text
base 15 read-data port = >983C
slot                   = >A000
mapping byte           = >50
```

Relative register map:

| GROM address | Access | Meaning |
|---:|---|---|
| `>A020` | Read | status |
| `>A021` | Read/write | line format and 2× mode |
| `>A022` | Read/write | baud divisor LSB |
| `>A023` | Read/write | baud divisor MSB; commits divisor |
| `>A024` | Read | bytes in receive buffer |
| `>A025` | Read | free entries in transmit buffer |
| `>A100–>AFFF` | Write | transmit-byte window |
| `>B000–>BFFF` | Read | receive-byte window |

### Status bits

| Mask | Meaning |
|---:|---|
| `>01` | receive byte available |
| `>02` | room in transmit buffer |
| `>04` | transmit buffer empty |
| `>10` | frame error |
| `>20` | receive overrun |
| `>40` | parity error |

### Line format

At offset `>0021`:

- bits 0–1 = character length (`00=5`, `01=6`, `10=7`, `11=8`);
- bits 2–3 = parity;
- bit 4 = one/two stop bits;
- bit 5 = double-speed mode.

8-N-1 normal speed is `>03`.

### Baud divisor

Normal mode:

```text
UBRR = floor(8,000,000 / (16 × baud) - 1)
```

Double-speed mode:

```text
UBRR = floor(8,000,000 / (8 × baud) - 1)
```

Write the LSB first and MSB second. For 9600 bps in normal mode, UBRR is 51 (`>0033`).

### Minimal 9600 8-N-1 setup

```asm
       LI   R0,>A021
       BL   @SETGADDR
       LI   R1,>0300
       MOVB R1,@UGWD

       LI   R0,>A022
       BL   @SETGADDR
       LI   R1,>3300
       MOVB R1,@UGWD        ; divisor LSB
       CLR  R1
       MOVB R1,@UGWD        ; divisor MSB, applies new divisor
```

For a production routine, check the buffer count/status before sending or receiving and provide a timeout.

The ATmega1284P firmware provides a **256-byte receive buffer**. It does not provide automatic hardware flow control, so sustained high-speed input still requires the TI-side application to drain the receive buffer promptly and implement whatever flow-control strategy the application needs.

Tursi's `gromtest` contains the complete reference UART test.

### Contributed UART application: Tim's TELCO patch

Tim (InsaneMultitasker) contributed a 2019 TELCO patch that shows a useful terminal-emulator architecture at 38.4K 8N1. It initializes the UART, transmits individual characters, polls the receive-count register at `>A024`, drains bytes from the receive window at `>B000`, and copies them into TELCO's larger 4 KiB RAM circular buffer.

That last step is particularly useful for terminal software: move incoming serial data out of the UberGROM receive buffer quickly, then let the display/keyboard processing consume the larger RAM buffer at its own pace. See [`examples/uart-telco-tim`](../examples/uart-telco-tim/).

## Timer

Map the timer with `>70`.

The firmware provides a free-running 16-bit timer at approximately 7812.5 Hz. It is derived from the AVR internal oscillator, but each AVR is factory calibrated, so the rate should normally be reasonably close rather than wildly variable. Read successive values and subtract them with 16-bit wraparound to measure elapsed time.

Tursi's `gromtest` includes a timer measurement test.

## RAM

The firmware exposes two RAM pages from the ATmega's SRAM:

- one full 8 KiB page;
- one approximately 7 KiB page, with the remainder reserved for firmware operation.

RAM is volatile and is not affected by JP4 write protection.

Tursi's test application maps and exercises both RAM pages.

## EEPROM

Map EEPROM with `>20` for ordinary byte access.

The 4 KiB EEPROM serves two different purposes:

1. low protected configuration/mapping area; and
2. application/user storage such as configuration, saves, or high scores.

EEPROM writes are much slower than RAM. The ATmega1284P EEPROM is rated for approximately **100,000 write/erase cycles** per cell, so avoid rewriting unchanged values or using EEPROM as live bank-switching storage. Use RAM for frequently changing state and reserve EEPROM for settings, saves, high scores, and other persistent data.

### JP4 protection scope

JP4 does **not** lock all EEPROM.

When JP4 is closed, the firmware rejects persistent EEPROM writes to addresses below `>0102`, protecting the mapping/configuration area. User EEPROM beginning at `>0102` remains writable.

The software configuration interface has its own unlock sequence as well; JP4 is an additional hardware gate for the protected portion.

## Flash controller (FlashCtl)

Map FlashCtl with `>60`.

FlashCtl provides controlled writes to the **120 KiB GROM-content portion of the ATmega program Flash**. It is used by GROMCFG and is also exercised by `gromtest`.

It is a legitimate feature for:

- building/configuring cartridges;
- tests;
- firmware-supported cartridge updates that happen infrequently.

It is **not** a good replacement for RAM or EEPROM for frequently changing application data. Flash erases are relatively slow and the implementation documentation rates Flash endurance at approximately 10,000 erase cycles.

### JP4 and FlashCtl

With JP4 closed, the firmware detects PC7 low and returns FlashCtl write-protected status (`2`) rather than erasing/programming Flash.

`gromtest` explicitly tests this by asking the user to apply write protect and verifying that FlashCtl reports the protected state.

## JP4 as the distribution lock

JP4 was specifically intended to let a finished cartridge be distributed with its UberGROM content and mapping locked while still allowing normal application storage. With JP4 closed:

- FlashCtl programming is blocked;
- protected configuration EEPROM `>0000–>0101` is blocked;
- RAM remains usable;
- user EEPROM beginning at `>0102` remains writable;
- the separate U2 ROM subsystem is unaffected.

This allows software to retain writable settings or save data without leaving the cartridge's GROM image and mapping open to ordinary TI-side reconfiguration.
## More examples

The repository's [`examples/`](../examples/) directory contains contributed application-level examples. Tursi's upstream [`gromtest`](https://github.com/tursilion/ubergrom/tree/main/gromtest) remains the authoritative reference test suite for the firmware interfaces themselves.

