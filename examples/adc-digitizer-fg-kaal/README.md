# ADC example — two-link digitizer

**Contributor:** Fred Kaal / F.G. Kaal  
**Latest test code:** April 2017  
**Concept:** two-link mechanical digitizer based on an earlier 1985 design

Fred contributed a TMS9900 assembly routine that reads two UberGROM ADC inputs and assigns the results to TI BASIC variables. The accompanying BASIC program converts the two measured joint positions into X/Y coordinates for a mechanical two-link digitizer.

Included files:

- [`Adcread.a99`](Adcread.a99) — assembly source;
- [`ADCTEST`](ADCTEST) — original TI BASIC program file supplied with the example;
- [`adctest.bas.txt`](adctest.bas.txt) — readable transcription of the BASIC listing.

The magazine-page scans from the original historical project are intentionally not redistributed here; this directory focuses on Fred's UberGROM application code.

## Required mapping

The source is written for **GROM base 0** and expects two logical slots to expose ADC pages:

```text
>8000 slot -> ADC page/channel 0  (mapping byte >40)
>A000 slot -> ADC page/channel 1  (mapping byte >41)
```

The routine adds peripheral offset `>0020`, so the actual conversion reads occur at logical GROM addresses `>8020` and `>A020`.

If you choose different GROM bases or slots, update the equates in `Adcread.a99` accordingly.

## Read pattern

The core `UGADCR` routine is deliberately small:

```asm
UGADCR  EQU $
         AI   R0,>0020       Set ADC address (offset >0020 of base)
         MOVB R0,@ADC#WA
         SWPB R0
         MOVB R0,@ADC#WA
         MOVB @ADC#RD,R0
         SRL  R0,8
         B    *R11
```

The caller passes a logical ADC slot address in `R0`. The routine sets the GROM address, reads one byte from the selected UberGROM base, and returns an integer value from 0–255.

## TI BASIC integration

`ADCRD` reads ADC0 and ADC1, converts each integer to TI floating-point format, and assigns the two results to BASIC variables through `NUMASG`.

The supplied BASIC program then calibrates the two ADC ranges into linkage angles and calculates the end-point X/Y position.

## Requirements

Fred's source notes that it requires **BSCSUP** and uses `XMLLNK`/`NUMASG` to integrate with TI BASIC. It is therefore a complete application example rather than a standalone ADC driver.
