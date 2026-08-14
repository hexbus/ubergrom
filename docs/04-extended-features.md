# UberGROM extended features

The UberGROM firmware exposes memory and peripherals through ordinary TI GROM reads and writes.

The firmware and reference test code are authored by Mike Brent/Tursi. The current upstream repository is:

- https://github.com/tursilion/ubergrom

The `gromtest` directory contains the TI-side reference tests for EEPROM, RAM, GPIO, ADC, UART, FlashCtl, and timer:

- https://github.com/tursilion/ubergrom/tree/main/gromtest

The examples below are intentionally small explanations of those interfaces. For implementation behavior, use the released source and `gromtest` as the reference.

## Configuration described in this chapter

Unless otherwise stated, the tables and sizes in this chapter describe the **ATmega1284P build used on the UberGROM cartridge board**:

- 128 KiB ATmega program Flash total;
- 120 KiB available as fifteen 8 KiB physical GROM Flash pages;
- 8 KiB boot/firmware section;
- 16 KiB SRAM total, with 15 KiB exposed as UberGROM RAM (8 KiB + approximately 7 KiB);
- 4 KiB EEPROM;
- four PCB GPIO pins;
- four ADC inputs;
- UART0 exposed on JP5; and
- the firmware timer derived from the AVR clock.

Other AVR ports/builds may have different capacities or mappings.

## Device mapping byte

A mapping byte uses:

- high nibble = device type;
- low nibble = device page, when the device is pageable.

| ID | High nibble | Device | Pageable on ATmega1284P build |
|---:|---:|---|---|
| 0 | `>0` | RAM | Yes, two exposed pages |
| 1 | `>1` | GROM Flash | Yes, 15 pages (`0–E`) |
| 2 | `>2` | EEPROM | No |
| 3 | `>3` | GPIO | No, four PCB pins |
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

## Common access pattern

Tursi's test code demonstrates the basic pattern used by all of these devices:

1. map the desired device into a logical GROM slot;
2. write the 16-bit GROM address through the selected base's write-address port; and
3. read or write bytes through that base's GROM data port.

For base *n*:

```text
Read data     = >9800 + (n × 4)
Read address  = >9802 + (n × 4)
Write data    = >9C00 + (n × 4)
Write address = >9C02 + (n × 4)
```

Most peripheral examples are therefore variations on ordinary GROM reads and writes.

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

## GPIO — four physical pins

Map GPIO with `>30`.

| Offset | Access | Meaning |
|---:|---|---|
| `>0020` | Write | direction: `0=input`, `1=output` |
| `>0021–>1FFF` | Read/write | pin state; on input pins, written 1 enables pull-up |

Bit assignment on this PCB:

```text
bit 0 = GPIO0
bit 1 = GPIO1
bit 2 = GPIO2
bit 3 = GPIO3
```

All four reset as inputs with pull-ups disabled.

The `gromtest` GPIO test maps device `>30` into slot `>6000`, writes the direction byte at GROM `>6020`, and reads/writes pin state at `>6021`. That is the simplest model to follow for your own GPIO code.

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

The implementation documentation gives approximately 104 µs per conversion and approximately 200 µs for the first conversion after power-up.

`gromtest` demonstrates a useful multi-base technique: map ADC0–ADC3 into the same `>6000` slot on four consecutive GROM bases, then read GROM `>6020` through each base. The GROM address stays the same while the base chooses the ADC channel.

## UART

JP5 exposes UART0 at **5 V TTL logic levels**. It is not ±RS-232 voltage level.

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
| `>A024` | Read | bytes available in receive buffer |
| `>A025` | Read | free entries in transmit buffer |
| `>A100–>AFFF` | Write | transmit-byte window |
| `>B000–>BFFF` | Read | receive-byte window |

### Buffers and flow control

The ATmega1284P firmware allocates **256-byte RX and TX arrays**. Because the implementation uses a circular buffer with one position reserved to distinguish full from empty, the maximum simultaneously queued payload is effectively 255 bytes.

There is no automatic external flow-control protocol exposed by the cartridge. Software must monitor the status/count registers and arrange any required flow control with the device on the other end. At high incoming data rates, the TI may not drain the receive buffer quickly enough; an overrun condition is reported and additional characters can be lost.

This is why the practical maximum serial speed depends on both baud rate and application service time, not only on what the AVR UART itself can clock.

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

Write the LSB first and MSB second.

### Example based on `gromtest`: 57.6 kbps, 8-N-1, 2× mode

The reference test maps UART as `>50`, writes line-format value `>23`, then writes divisor bytes `>10, >00`. Before transmitting, it polls status bit `>02` for room in the transmit buffer; received data is read only after status indicates data is available.

For production code, also monitor `>A024`/`>A025`, provide a timeout where appropriate, and implement application-level flow control if the remote sender can outrun the TI.

## Timer

Map the timer with `>70`.

The firmware provides a free-running 16-bit timer nominally around **7812.5 Hz**. It is derived from the ATmega's internal oscillator, so it is not a precision crystal timebase; however, each AVR's calibrated RC oscillator is factory tuned and should normally be reasonably close to the nominal rate.

Read successive values and subtract them with 16-bit wraparound to measure elapsed time. `gromtest` contains the reference timer test.

## RAM

The ATmega1284P firmware exposes two RAM pages from SRAM:

- one full 8 KiB page; and
- one approximately 7 KiB page, with the remainder reserved for firmware operation.

RAM is volatile. `gromtest` maps and exercises both pages.

## EEPROM

Map EEPROM with `>20` for ordinary byte access.

The 4 KiB EEPROM serves two purposes:

1. low protected configuration/mapping area; and
2. application/user storage such as configuration, saves, or high scores.

The ATmega1284P EEPROM is rated for approximately **100,000 erase/write cycles per location**. It is appropriate for persistent settings and save data, but not as a live high-frequency bank-switch register. Avoid rewriting unchanged values and use integrity checks for important persistent structures.

Historically, Tursi implemented a RAM-backed mapping approach in the separate MPD work for a use case that needed runtime GROM banking; that change was not backported to the standard UberGROM firmware because normal UberGROM applications did not need it.

### JP4 distribution lock and EEPROM

JP4 was specifically intended as a **distribution lock**. When closed, the firmware rejects persistent writes to EEPROM addresses below `>0102`, protecting the mapping/configuration area. User EEPROM beginning at `>0102` remains writable so a distributed cartridge can still save normal application data.

## Flash controller (FlashCtl)

Map FlashCtl with `>60`.

FlashCtl provides controlled writes to the **120 KiB GROM-content portion of the ATmega program Flash**. It is used by GROMCFG and is exercised by `gromtest`.

FlashCtl is appropriate for cartridge creation, testing, and infrequent updates. It is not intended to behave like RAM or frequently rewritten save storage: Flash erase/program operations are relatively slow, and the ATmega1284P Flash endurance is approximately **10,000 erase/write cycles**.

### JP4 and FlashCtl

With JP4 closed, FlashCtl reports write-protected status (`2`) and refuses erase/program operations. `gromtest` explicitly tests that distribution-lock behavior before exercising Flash.

## Reference test program

The current `gromtest` menu includes tests for:

```text
EEPROM
RAM
GPIO
ADC
UART
FLASH
Timer
```

Use the source as the primary example for actual TI-side reads/writes. The goal of this chapter is to explain what the operations mean, not to create a separate competing implementation.
