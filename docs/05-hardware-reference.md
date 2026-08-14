# Hardware reference

The most important hardware concept is that this cartridge contains **two independent programming domains**:

- **U2 external ROM domain** — U2 plus the 74LS378 ROM bank latch and associated ROM control routing.
- **U3 UberGROM domain** — ATmega1284P, its internal Flash/EEPROM/RAM, GROM interface, and peripherals.

There is no ATmega-to-U2 programming path. GROMCFG/FlashCtl cannot program U2, and the U2 ROM banking circuitry cannot alter ATmega memory.

![UberGROM PCB jumper/header layout](images/ubergrom-pcb-jumpers.jpg)

## Major devices

| Ref. | Device | Function |
|---|---|---|
| U1 | 74LS378 | six-bit non-inverting U2 ROM bank latch |
| U2 | 29F040/49F040-class 512 KiB flash | external CPU ROM at `>6000–>7FFF` |
| U3 | ATmega1284P | UberGROM firmware, GROM Flash, SRAM, EEPROM, and peripherals |

## Jumpers and headers at a glance

| Ref. | Domain | Purpose |
|---|---|---|
| JP1 | U2 ROM | U2 `WE` routing provision; **leave at 1-2 (write disabled)** in the current design |
| JP3 | U2 ROM | U2 `OE` routing; default silkscreen position is the normal ROM setting |
| JP4 | U3 UberGROM | hardware write-protect input used by released firmware |
| JP5 | U3 UberGROM | UART: GND / RXD0 / TXD0 |
| JP6 | U3 UberGROM | ATmega ISP/SPI development header |
| JP7 | U3 UberGROM | four ADC inputs plus ground |
| JP8 | board reset | reset/switch connection, normally closed |

### Do not cross the U2 and U3 descriptions

JP1/JP3 belong to the **external U2 ROM side only**. They do not control:

- ATmega EEPROM;
- ATmega GROM Flash;
- GROMCFG;
- FlashCtl;
- JP4 protection.

Likewise, JP4 belongs to the **ATmega/UberGROM side only** and does not protect or program U2.

There is currently **no complete in-circuit programming path for U2** on this board. JP1 must therefore not be documented as a way to program the 512 KiB external Flash in circuit. Program U2 externally with a device programmer.

## JP1 — U2 WE routing (leave at 1-2)

The PCB silkscreen identifies JP1 as **`U-2 WE`** and marks `1-2` as `+5V / Write Disable`. **For the current board and software, leave JP1 at 1-2.**

JP1 was provided as U2 write-enable routing, but the cartridge has no complete mechanism for programming the 512 KiB U2 Flash in circuit. Moving JP1 to the alternate position does **not** turn the cartridge into an in-circuit U2 programmer. U2 should be removed/programmed with an external programmer (or otherwise programmed outside this cartridge circuit).

The `1-2` write-disabled position is also important to the board's bank-switching architecture. This cartridge selects ROM banks by performing TI write cycles to addresses in the cartridge ROM space (`>6000`, `>6002`, and so on). Those cycles intentionally assert the console's write signal so the 74LS378 can latch the bank-select address bits. U2 itself is **not** supposed to be written during those bank-select cycles, so its `WE` input is held inactive in the normal `1-2` position.

In other words:

- TI write to `>6000 + bank×2` → clocks the **74LS378 bank latch**;
- U2 remains read-only during normal cartridge operation;
- the data value written during bank selection is immaterial on this board; and
- JP1 is **not** an UberGROM/ATmega write-protect control and has no connection to GROMCFG or FlashCtl.

Bank-selection writes such as `CLR @>6002` therefore change the selected U2 bank without programming U2 Flash.

## JP3 — U2 OE routing

JP3 is labeled **`U-2 OE`**. Use the PCB's documented default position for normal ROM operation.

JP3 is not a second UberGROM enable or write-protect jumper.

## JP4 — UberGROM distribution lock

JP4 is labeled **`U-3 Write Protect`** and is normally open. It was specifically designed as a **distribution lock**: configure/test the cartridge with JP4 open, then close it on a finished cartridge when the GROM Flash and mapping should no longer be modifiable through the TI-side UberGROM interfaces.

In Tursi's released firmware, closing JP4 grounds ATmega **PC7**. The firmware checks this input in two places:

### FlashCtl

If PC7 is low, FlashCtl:

- reports result code `2` (write protected); and
- rejects Flash erase/program operations.

This protects the 120 KiB emulated-GROM Flash area from writes through the UberGROM FlashCtl interface.

### EEPROM configuration

For persistent EEPROM writes, the firmware checks JP4 when the EEPROM address is below `>0102`.

With JP4 closed, persistent writes to:

```text
>0000–>0101
```

are rejected. This protects the mapping/configuration portion of EEPROM.

### Protection scope

JP4 protects the UberGROM GROM-Flash programming path and the low EEPROM mapping/configuration area. It intentionally leaves RAM and user EEPROM at `>0102` and above writable, so a distributed cartridge can still save settings, high scores, and other application data. JP4 is an ATmega/UberGROM-side control and is unrelated to U2.

### Practical use

- Leave JP4 **open** while using GROMCFG to create or modify the cartridge.
- After final configuration and testing, close JP4 if the GROM Flash and mapping should be locked against ordinary TI-side reconfiguration.
- Open it again whenever GROMCFG must modify protected content.

## JP5 — UART

The PCB labels JP5:

```text
GND / RXD0 / TXD0
```

It is normally open.

The UART uses **5 V TTL** logic. Do not connect it directly to a traditional ±RS-232 serial interface. Use an appropriate level converter or a serial adapter confirmed compatible with 5 V TTL signaling.

## JP6 — ATmega ISP/SPI header

JP6 exposes the development/programming signals used around the ATmega1284P.

![JP6 ISP/SPI header detail](images/jp6-isp-header.png)

| JP6 pin | Signal | ATmega1284P function |
|---:|---|---|
| 1 | `MISO` | PB6 / ISP MISO |
| 2 | `+5V` | target supply/reference |
| 3 | `SCK` | PB7 / ISP clock |
| 4 | `MOSI` | PB5 / ISP MOSI |
| 5 | `RSET*` | active-low RESET |
| 6 | `GND` | ground |
| 7 | `SS*` | PB4 / active-low SPI select |
| 8 | `GND` | ground |

### Normal AVR ISP signals

For ordinary AVR ISP programming, the essential signals are:

```text
MISO
MOSI
SCK
RSET*
VCC/reference
GND
```

`SS*` is exposed for SPI/development use and is not normally required by a standard AVR ISP operation.

### Connection cautions

- Remove the cartridge from the TI before ISP programming.
- Do not power the target simultaneously from the TI and an external programmer.
- Determine whether the programmer's VCC pin **supplies power** or is only a **target-voltage reference**.
- JP6 does not use the standard keyed 6-pin AVR ISP physical arrangement, so an adapter cable may be necessary.
- `RSET*` and `SS*` are active low.

A socketed ATmega may instead be removed and programmed directly in a universal programmer.

## JP7 — four ADC inputs

JP7 exposes:

```text
ADC0
ADC1
ADC2
ADC3
GND
```

These are the four analog channels used by the standard board/firmware combination.

Observe the ATmega electrical limits. The original UberGROM interface treats the conversion range as 0–5 V on this 5 V design.

## JP8 — reset connection

JP8 is normally closed and connects the board to the cartridge reset signal.

Opening it is for an external reset/switch arrangement, not normal cartridge operation.

## ROM and UberGROM writes are different operations

Three different “write” concepts exist and should never be conflated:

1. **ROM bank-select write** — TMS9900 writes to `>6000 + bank×2`; changes 74LS378 latch state only.
2. **UberGROM FlashCtl/EEPROM write** — TI GROM accesses handled by ATmega firmware; JP4 can block protected writes.
3. **Device programming** — an external programmer physically programs U2 or U3.

Keeping those three paths separate prevents most of the jumper/programming confusion in the older documentation.

## Source references

- UberGROM firmware by Mike Brent/Tursi: https://github.com/tursilion/ubergrom
- `eeprom.c`: hardware write-protect check for EEPROM configuration
- `flash.c`: hardware write-protect check and FlashCtl result code
- final PCB silkscreen and schematic for jumper labels
