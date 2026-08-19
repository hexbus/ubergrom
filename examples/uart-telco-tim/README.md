# UART example — TELCO UberGROM patch

**Contributor:** Tim / InsaneMultitasker  
**Original code date:** December 28, 2019  
**Application:** TELCO terminal emulator patch

Tim contributed this code as a real-world example of using the UberGROM UART in a terminal application. The original TI file is preserved unchanged as [`UBERS`](UBERS). A lightly normalized transcription of the relevant source is provided as [`telco_uart_excerpt.asm`](telco_uart_excerpt.asm) for convenient reading; use `UBERS` as the original contributed artifact.

## What the example demonstrates

The patch uses the common UART mapping at **GROM base 15, slot `>A000`**:

```text
base 15 read data     >983C
base 15 write data    >9C3C
base 15 write address >9C3E
UART slot             >A000
```

Its terminal architecture illustrates four useful operations:

1. initialize the UART for 38.4K, 8 data bits, no parity, 1 stop bit;
2. transmit one character through the UART transmit window;
3. poll the receive-count register and drain available characters from the UberGROM receive buffer;
4. copy those bytes into TELCO's larger 4 KiB RAM circular buffer so screen processing and keyboard handling can proceed without immediately overflowing the UART receive buffer.

### 38.4K configuration

The code writes `>23` to UART register `>A021`, selecting 8N1 with double-speed (`U2X`) enabled, then loads divisor `>0019` (25) through the baud registers.

At an 8 MHz AVR clock, that is the expected divisor for approximately 38.4 kbit/s in double-speed mode.

### Receive buffering

The routine reads the receive count at `>A024`, then switches the GROM address to the receive-data window at `>B000` and drains that many bytes into TELCO's circular buffer.

This is an important pattern for high-speed serial applications: the UberGROM UART has its own receive buffer, but application software still needs to service it promptly. Hardware flow control is not automatic, so a terminal program should manage flow control and/or provide a larger software buffer when sustained input is expected.

## Scope

This is application-specific historical code, not a minimal standalone UART library. It patches TELCO entry points and uses TELCO workspace/buffer addresses. The UART portions are useful as working examples of the access pattern.
