# UberGROM extended features

The ATmega firmware exposes devices through normal TI GROM accesses. A mapping byte contains:

- high nibble: device type;
- low nibble: device page, where applicable.

| ID | Mapping high nibble | Device | Pageable |
|---:|---:|---|---|
| 0 | `>0` | RAM | Yes, two pages |
| 1 | `>1` | GROM flash | Yes, fifteen pages |
| 2 | `>2` | EEPROM | No |
| 3 | `>3` | GPIO | No |
| 4 | `>4` | ADC | Yes, four channels/pages |
| 5 | `>5` | UART | No |
| 6 | `>6` | Flash controller | No |
| 7 | `>7` | Timer | No |

Example: mapping byte `>12` maps GROM page 2. Mapping byte `>50` maps the UART.

Peripheral registers begin at offset `>0020` within a mapped slot so that they do not resemble a cartridge header at the start of a slot.

## GROM port helpers in TMS9900 assembly

The following examples use base 15:

```asm
UGRD   EQU  >983C           ; read data
UGRA   EQU  >983E           ; read address
UGWD   EQU  >9C3C           ; write data
UGWA   EQU  >9C3E           ; write address

* R0 = GROM address. Destroys R1.
SETGADDR
       MOV  R0,R1
       MOVB R1,@UGWA        ; high byte
       SWPB R1
       MOVB R1,@UGWA        ; low byte
       RT
```

`MOVB` uses the high byte of a TMS9900 register. Preserve that convention when adapting the routines.

## UART

The community compatibility convention maps the UART at:

```text
base 15: CPU read-data port >983C
slot >A000
mapping byte >50
```

With that mapping, the UART registers are:

| GROM address | Access | Meaning |
|---:|---|---|
| `>A020` | Read | Status |
| `>A021` | Read/write | line format and 2× mode |
| `>A022` | Read/write | baud divisor LSB |
| `>A023` | Read/write | baud divisor MSB; writing commits divisor |
| `>A024` | Read | bytes available in receive buffer |
| `>A025` | Read | free bytes in transmit buffer |
| `>A100–>AFFF` | Write | transmit-byte window |
| `>B000–>BFFF` | Read | receive-byte window |

### Status bits at `>A020`

| Bit | Mask | Meaning |
|---:|---:|---|
| 0 | `>01` | at least one receive byte available |
| 1 | `>02` | room for at least one transmit byte |
| 2 | `>04` | transmit buffer empty |
| 4 | `>10` | frame error |
| 5 | `>20` | receive overrun |
| 6 | `>40` | parity error |

### Line-format byte at `>A021`

| Bits | Meaning |
|---|---|
| 0–1 | word length: `00=5`, `01=6`, `10=7`, `11=8` bits |
| 2–3 | parity: `00/01=none`, `10=even`, `11=odd` |
| 4 | `0=1` stop bit, `1=2` stop bits |
| 5 | double-speed mode |

Thus 8-N-1 without double-speed is `>03`.

### Baud divisor

Normal mode:

```text
UBRR = round_down(8,000,000 / (16 × baud) - 1)
```

Double-speed mode:

```text
UBRR = round_down(8,000,000 / (8 × baud) - 1)
```

Write the LSB to `>A022` first, then the MSB to `>A023`. The firmware commits the new divisor when the MSB is written.

For 9600 bps in normal mode, `UBRR=51` (`>0033`).

### Configure 9600 bps, 8-N-1

```asm
UARTCFG
       LI   R0,>A021
       BL   @SETGADDR
       LI   R1,>0300        ; MOVB writes high byte: >03
       MOVB R1,@UGWD

       LI   R0,>A022
       BL   @SETGADDR
       LI   R1,>3300        ; divisor LSB >33
       MOVB R1,@UGWD
       CLR  R1              ; divisor MSB >00; commits divisor
       MOVB R1,@UGWD
       RT
```

### Send one byte

Input: character in the high byte of `R1`.

```asm
UARTPUT
       MOV  R1,R2
WAITTX LI   R0,>A025
       BL   @SETGADDR
       MOVB @UGRD,R3
       JEQ  WAITTX          ; high byte zero means no free entries

       LI   R0,>A100
       BL   @SETGADDR
       MOVB R2,@UGWD
       RT
```

### Receive one byte

Returns the byte in the high byte of `R1`.

```asm
UARTGET
WAITRX LI   R0,>A024
       BL   @SETGADDR
       MOVB @UGRD,R1
       JEQ  WAITRX

       LI   R0,>B000
       BL   @SETGADDR
       MOVB @UGRD,R1
       RT
```

These are intentionally blocking examples. Production software should define timeouts, inspect error bits, and transfer multiple bytes per address setup where practical.

JP5 is 5 V TTL UART, not RS-232 voltage levels. Use a suitable level translator for a PC serial port and verify the voltage tolerance of Bluetooth or USB-UART modules.

## GPIO

Map GPIO with `>30`. Registers are relative to the selected slot:

| Offset | Access | Meaning |
|---:|---|---|
| `>0020` | Write | direction bits, `0=input`, `1=output` |
| `>0021–>1FFF` | Read/write | pin state; writes to inputs control pull-ups |

The least-significant bit represents GPIO0. All pins reset as inputs with pull-ups disabled.

Example uses include buttons, LEDs through appropriate resistors/drivers, simple control lines, and external device handshaking. The board manual and schematic must be used to confirm the actual number of routed GPIO pins on the specific board revision before publishing a wiring example.

## ADC

Map ADC device page 0–3 using `>40–>43`. Each page selects one analog channel. Reads from offsets `>0020–>1FFF` trigger a conversion and return an 8-bit result:

```text
0   ≈ 0 V
255 ≈ 5 V
```

Allow approximately 104 microseconds per conversion and approximately 200 microseconds for the first conversion after power-up. Inputs must remain within the electrical limits of the ATmega and cartridge board.

## Timer

Map the timer with `>70`. It is a free-running 16-bit counter clocked at approximately 7812.5 Hz, subject to the internal oscillator tolerance. It provides finer resolution than the VDP interrupt and does not need to be reset to measure elapsed intervals; subtract successive unsigned readings and allow for wraparound.

## EEPROM

Map EEPROM with `>20` for ordinary byte access. EEPROM is nonvolatile but has finite endurance and relatively slow writes. Use it for configuration, high scores, and occasional saved state—not for per-frame bank switching or streaming data. Validate persistent records with a checksum or CRC and avoid rewriting bytes whose values have not changed.

The fixed configuration window is at base 15, GROM `>F800–>FFFF`. Configuration writes require the firmware unlock sequence and mirrored/inverted bytes; normal applications should use GROMCFG unless they specifically need runtime reconfiguration.

## Flash controller

The FlashCtl device (`>60`) writes the ATmega's GROM flash. It exposes a 256-byte write buffer and erase/program commands. This is the mechanism used by GROMCFG. Flash has limited erase endurance; it is for cartridge creation or infrequent updates, not routine application storage.
