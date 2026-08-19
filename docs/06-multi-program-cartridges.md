# Building multi-program UberGROM cartridges

One of the most useful features of the UberGROM board is that a single physical cartridge does not have to behave like a single software title.

A cartridge can combine:

- several independent GPL/GROM programs;
- one GPL/GROM menu that launches several programs stored in the bank-switched U2 ROM;
- additional independent GROM-resident programs that contribute their own entries to the TI selection screen; and
- software mapped on additional GROM bases when two programs need the same logical GROM slot.

This chapter explains the distinction between **GROM slots**, **GROM bases**, **physical UberGROM pages**, and the separate **U2 ROM banks**, then shows historical and working examples.

## Four address spaces to keep separate

### GROM slot

Within a GROM base, cartridge GROM space is divided into the familiar 8 KiB logical ranges:

```text
>6000  >8000  >A000  >C000  >E000
```

The first three logical GROM ranges, `>0000`, `>2000`, and `>4000`, are occupied by the console GROMs and are not normal cartridge slots.

A title may have been assembled specifically for one of these logical addresses. Moving its bytes to another slot does **not** automatically relocate absolute GPL/GROM references inside the program.

### GROM base

A GROM base is the CPU port set used to access GROM:

```text
base 0  read data >9800   read address >9802   write data >9C00   write address >9C02
base 1  read data >9804   read address >9806   write data >9C04   write address >9C06
...
base 15 read data >983C   read address >983E   write data >9C3C   write address >9C3E
```

UberGROM can provide distinct mappings on sixteen bases. This gives a second dimension beyond the five cartridge GROM slots.

### Physical UberGROM page

The ATmega1284P implementation has fifteen physical 8 KiB GROM Flash pages. GROMCFG maps those physical pages into logical base/slot combinations.

The physical page number does not have to match the logical GROM address.

### U2 ROM bank

The separate 512 KiB U2 device contains sixty-four 8 KiB CPU-ROM banks at `>6000–>7FFF`. These are selected through the 74LS378 and are independent of the ATmega GROM mapping.

A GPL/GROM program can therefore act only as a menu/launcher while the application itself executes from U2.

## Historical example: Milton Bradley Games

The Milton Bradley multi-game cartridge is an excellent historical example of several self-contained GROM programs coexisting in one cartridge.

A reference `mbgamesg.bin` image examined during preparation of this documentation contains valid `>AA` cartridge headers at the following logical GROM slots:

| Logical GROM slot | Program-list entry |
|---:|---|
| `>6000` | `MILTON BRADLEY GAMES` |
| `>8000` | `CONNECT FOUR` |
| `>A000` | `HANGMAN` |
| `>C000` | `YAHTZEE` |
| `>E000` | `ZERO-ZAP` |

The important point is that Connect Four, Hangman, Yahtzee, and Zero-Zap are not merely data files called by one monolithic application. Each image contains its own cartridge header and program-list entry at the logical GROM location for which it was built.

That means the individual game GROMs can be treated as independent cartridge programs. If the four game GROMs are placed together at their expected slots, the TI can discover four program entries while building the cartridge selection list.

> Historical documentation sometimes loosely refers to `>8000`, `>A000`, and similar addresses as different "GROM bases." In this reference, those are called **GROM slots**. A **GROM base** means the CPU port set at `>9800`, `>9804`, and so on.

The Milton Bradley arrangement is useful because it demonstrates the idea without any UberGROM-specific launcher: multiple independent GROM headers can coexist and each can contribute its own menu entry.

The proprietary Milton Bradley cartridge image is **not redistributed** with this repository; the layout is documented only as a historical example.

A source-free header/layout breakdown is included at [`../examples/mb-games-layout/`](../examples/mb-games-layout/).

## Working UberGROM example: one GPL GROM launches two banked-ROM programs

The Phoenix + Tacticon Chess cartridge provides a tested modern example of a different technique.

The file [`../examples/gpl-multi-program-menu/gromhead.g`](../examples/gpl-multi-program-menu/gromhead.g) is a small dedicated GPL/GROM launcher. It is assembled for logical GROM slot `>8000` and contributes two entries to the TI selection screen:

```text
PHOENIX CHESS
TACTICON
```

The corresponding programs live in U2 ROM rather than in the GROM itself:

```text
PHOENIX CHESS  -> bank select >6000 -> ROM entry >6054
TACTICON       -> bank select >6058 -> ROM entry >6024
```

The GPL entry writes the required bank select and ROM entry address into scratchpad. Shared GPL code then creates the following two-instruction TMS9900 trampoline in scratchpad:

```asm
       CLR  @bank_select
       B    @rom_entry
```

and transfers control to it with `XML >F0`.

Because the actual bank-select write executes from scratchpad rather than from U2 ROM, the complete `>6000–>7FFF` cartridge window can change safely.

This is a practical pattern for a cartridge that contains several CPU-ROM applications: a very small GROM can provide the TI menu while U2 stores the much larger programs.

## Adding an independent GROM title to the Chess launcher

The Chess launcher does not have to know about every program in the cartridge.

For example, Hangman is historically associated with logical GROM slot `>A000`. It can coexist with the Chess launcher at `>8000` while U2 contains Phoenix and Tacticon:

| GROM base | Logical slot / U2 resource | Contents | Menu entries |
|---:|---:|---|---|
| base 0 (`>9800`) | GROM `>8000` | Chess GPL launcher | `PHOENIX CHESS`, `TACTICON` |
| base 0 (`>9800`) | GROM `>A000` | Hangman GROM image | `HANGMAN` |
| separate U2 | banks 0–43 | Phoenix ROM | launched by Chess GPL |
| separate U2 | banks 44–51 | Tacticon ROM | launched by Chess GPL |

The resulting TI selection screen can therefore contain three choices even though the cartridge uses two different storage technologies:

```text
PHOENIX CHESS
TACTICON
HANGMAN
```

The key architectural idea is that **the TI builds the selection list from the cartridge headers it discovers**. A separate GROM program can contribute its own menu entry; it does not need to be manually added to the Chess launcher's program list.

## Same base, different slots versus different GROM bases

There are two useful ways to combine independent GROM programs.

### Different slots in the same base

This is the Milton Bradley style:

```text
base 0
  >8000  CONNECT FOUR
  >A000  HANGMAN
  >C000  YAHTZEE
  >E000  ZERO-ZAP
```

It works well when each program already expects a different logical GROM slot or has been properly relocated for that slot.

### Same slot on different bases

If two independent cartridges both expect to live at `>6000`, UberGROM's multiple-base support may allow each to retain that logical slot while being mapped on a different GROM base:

```text
base 0 / >6000  program A
base 1 / >6000  program B
```

This can avoid changing the program's internal GROM address layout. It still must be tested, however, because software may make assumptions about the GROM base or directly access particular GROM CPU ports.

## Compatibility is not automatic

Many GPL/GROM titles are flexible enough to work when combined with other programs, but there is no rule that every cartridge can be moved freely.

Potential incompatibilities include:

- absolute GPL/GROM addresses that assume a particular logical slot such as `>6000`;
- code that directly accesses a particular GROM CPU base rather than using the environment established by the console;
- self-modifying or unusual GROM-address logic;
- ROM/GROM cartridges that also require CPU ROM at `>6000–>7FFF`;
- titles that depend on a particular ROM mapper or ROM bank state; and
- interactions that appear only after `QUIT`, warm reset, or returning from another program.

Some titles have been reported by users as less tolerant of relocation than others. Treat such reports as a reason to test, not as a compatibility guarantee or permanent blacklist.

For an existing cartridge image, prefer this order:

1. keep the title in its original logical GROM slot when practical;
2. if that slot conflicts with another title, try the same slot on another UberGROM base;
3. relocate the GROM image only when necessary and verify the relocated image carefully; and
4. for GROM+ROM titles, reproduce the required ROM behavior as well as the GROM mapping.

## A useful collection-wide experiment

A systematic test of the TI cartridge library would be valuable community documentation. For each title, record at least:

| Title | GROM only or GROM+ROM | Original GROM slot(s) | Alternate slot tested | Alternate GROM base tested | Result | ROM dependency / mapper | Emulator tested | Hardware tested | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Example | GROM only | `>6000` | `>8000` | base 1 | TBD | none | TBD | TBD | |

Useful test cases include:

- cold power-up;
- selecting the program from the TI title screen;
- returning with `QUIT` and selecting it again;
- running after another program on the same cartridge changed the U2 bank latch;
- emulator testing; and
- final verification on real UberGROM hardware.

A compatibility result should identify exactly what was tested. "Works at another base" and "works at another slot" are different claims.

## GROMCFG mapping example

A mixed cartridge might be planned as:

| GROM base | Slot | Device | Physical page | Purpose |
|---:|---:|---|---:|---|
| base 0 (`>9800`) | `>8000` | GROM | page 0 | Chess GPL launcher |
| base 0 (`>9800`) | `>A000` | GROM | page 1 | independent GROM title |
| base 15 (`>983C`) | `>A000` | UART | — | optional serial interface |
| base 15 (`>983C`) | `>E000` | FlashCtl | — | development/configuration only |

The exact physical page numbers are arbitrary; what matters is that the intended bytes are mapped into the logical base/slot expected by the software.

## Related examples and references

- [GPL multi-program / banked-ROM launcher](../examples/gpl-multi-program-menu/)
- [Programming with GROMCFG](02-programming-with-gromcfg.md)
- [512 KiB ROM bank switching](03-rom-bank-switching.md)
- [UberGROM extended features](04-extended-features.md)
