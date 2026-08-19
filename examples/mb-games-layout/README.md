# Historical example: Milton Bradley multi-GROM layout

This directory documents the **layout only** of a Milton Bradley multi-game GROM image examined while preparing the UberGROM reference. The proprietary game image is not included.

The example is useful because it shows that several self-contained TI GROM cartridge programs can coexist in different logical GROM slots and independently contribute entries to the TI cartridge-selection screen.

## Verified header layout

The reference image contains a standard `>AA` cartridge header at each of these logical GROM slots:

| File offset | Logical GROM slot | Program-list pointer | Program entry | Menu text |
|---:|---:|---:|---:|---|
| `>0000` | `>6000` | `>6013` | `>602C` | `MILTON BRADLEY GAMES` |
| `>2000` | `>8000` | `>8013` | `>8024` | `CONNECT FOUR` |
| `>4000` | `>A000` | `>A013` | `>A01F` | `HANGMAN` |
| `>6000` | `>C000` | `>C013` | `>C01F` | `YAHTZEE` |
| `>8000` | `>E000` | `>E013` | `>E020` | `ZERO-ZAP` |

The first bytes of each logical image begin with the same cartridge signature pattern:

```text
AA 01 ...
```

The program-list pointers and entry addresses are expressed in the logical GROM address range in which each game was assembled.

## Why this matters to UberGROM

Connect Four, Hangman, Yahtzee, and Zero-Zap are useful examples of programs that already expect different logical GROM slots. They can therefore coexist without one master GPL launcher having to contain all four program-list entries.

UberGROM generalizes this idea in two directions:

1. physical GROM Flash pages can be mapped into whichever logical slots the software expects; and
2. additional GROM **bases** can be used when independent programs need the same logical slot, subject to compatibility testing.

A logical slot such as `>8000` is not the same thing as a GROM base. In this documentation, **slot** means `>6000`, `>8000`, `>A000`, `>C000`, or `>E000`; **base** means the GROM CPU port set beginning at `>9800`, `>9804`, and so on.

See [Building multi-program UberGROM cartridges](../../docs/06-multi-program-cartridges.md) for the broader design and compatibility discussion.
