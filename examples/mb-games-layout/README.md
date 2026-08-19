# Historical example: Milton Bradley Gamevision Demonstration Cartridge

This directory documents the **layout only** of the 1979 **Milton Bradley Gamevision Demonstration Cartridge** (MB 4961) examined while preparing the UberGROM reference. The proprietary cartridge image is not included.

This was not a normal retail multi-game release. It was created as an in-store/dealer demonstration cartridge for the TI-99/4 launch-era Gamevision line and was not widely distributed to consumers. A shopper could see the demonstration material and access the included Gamevision titles; the individual games were also sold as separate cartridges.

The layout is especially useful to UberGROM developers because it shows that several self-contained TI GROM cartridge programs can coexist in different logical GROM slots and independently contribute entries to the TI cartridge-selection screen.

Historical references:

- https://www.videogamehouse.net/gamemain/cartsfh/gamevisiondemo/
- https://www.ti994.com/1979/cartridges/

## Verified header layout

The reference image contains a standard `>AA` cartridge header at each of these logical GROM slots:

| File offset | Logical GROM slot | Program-list pointer | Program entry | Menu text |
|---:|---:|---:|---:|---|
| `>0000` | `>6000` | `>6013` | `>602C` | `MILTON BRADLEY GAMES` |
| `>2000` | `>8000` | `>8013` | `>8024` | `CONNECT FOUR` |
| `>4000` | `>A000` | `>A013` | `>A01F` | `HANGMAN` |
| `>6000` | `>C000` | `>C013` | `>C01F` | `YAHTZEE` |
| `>8000` | `>E000` | `>E013` | `>E020` | `ZERO-ZAP` |

The first bytes of each logical image begin with the standard cartridge signature pattern:

```text
AA 01 ...
```

The program-list pointers and entry addresses are expressed in the logical GROM address range in which each game was assembled.

## The four games can stand on their own

Connect Four, Hangman, Yahtzee, and Zero-Zap were individual Gamevision cartridges, and the corresponding images in the demonstration cartridge retain their own cartridge headers/program lists.

If those four GROM images are combined at their expected logical locations, the TI can discover four independent menu entries:

```text
>8000  CONNECT FOUR
>A000  HANGMAN
>C000  YAHTZEE
>E000  ZERO-ZAP
```

No new master GPL menu is required merely to make those four program headers visible.

## Why this matters to UberGROM

The Gamevision arrangement is a historical example of **different slots in one GROM base**. UberGROM generalizes the idea in two directions:

1. physical GROM Flash pages can be mapped into whichever logical slots the software expects; and
2. additional GROM **bases** can be used when independent programs need the same logical slot, subject to compatibility testing.

A logical slot such as `>8000` is not the same thing as a GROM base. In this documentation, **slot** means `>6000`, `>8000`, `>A000`, `>C000`, or `>E000`; **base** means the GROM CPU port set beginning at `>9800`, `>9804`, and so on.

See [Building multi-program UberGROM cartridges](../../docs/06-multi-program-cartridges.md) for the broader design and compatibility discussion.
