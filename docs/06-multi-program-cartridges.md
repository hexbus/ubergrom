# Building multi-program UberGROM cartridges

One of the most useful features of the UberGROM board is that a single physical cartridge does not have to behave like a single software title.

A cartridge can combine:

- several independent GPL/GROM programs;
- one GPL/GROM menu that launches several programs stored in the bank-switched U2 ROM;
- additional independent GROM-resident programs that contribute their own entries to the TI selection screen; and
- software mapped on additional GROM bases when two programs need the same logical GROM slot.

This chapter separates **GROM slots**, **GROM bases**, **physical UberGROM pages**, and the independent **U2 ROM banks**, then shows a historical TI-era example and a genericized modern launcher pattern.

## Four address spaces to keep separate

### GROM slot

Within a GROM base, cartridge GROM space is divided into these 8 KiB logical ranges:

```text
>6000  >8000  >A000  >C000  >E000
```

The first three logical GROM ranges, `>0000`, `>2000`, and `>4000`, are occupied by the console GROMs and are not normal cartridge slots.

A program may have been assembled specifically for one of these logical addresses. Moving its bytes to another slot does **not** automatically relocate absolute GPL/GROM references inside the program.

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

## Historical example: Milton Bradley Gamevision Demonstration Cartridge

The **Milton Bradley Gamevision Demonstration Cartridge** (MB 4961) is a particularly useful historical example. It dates from the 1979 TI-99/4 launch period and was intended as an in-store/dealer demonstration cartridge rather than a normal retail release. It showcased Milton Bradley's Gamevision software line and was not widely distributed to consumers.

The demonstration cartridge includes a demo/menu program plus four Gamevision titles that were also distributed as individual cartridges: **Connect Four, Hangman, Yahtzee, and Zero-Zap**.

A reference `mbgamesg.bin` image examined while preparing this documentation contains valid `>AA` cartridge headers at these logical GROM slots:

| Logical GROM slot | Program-list entry |
|---:|---|
| `>6000` | `MILTON BRADLEY GAMES` |
| `>8000` | `CONNECT FOUR` |
| `>A000` | `HANGMAN` |
| `>C000` | `YAHTZEE` |
| `>E000` | `ZERO-ZAP` |

The key point is that the four games are not merely data files hidden behind one monolithic program. Each has its own cartridge header and program-list entry at the logical GROM location for which it was built.

That means the four individual game GROMs can stand on their own. If those four GROM images are placed together at their expected logical slots, the TI can discover four separate program entries while building the cartridge selection list:

```text
>8000  CONNECT FOUR
>A000  HANGMAN
>C000  YAHTZEE
>E000  ZERO-ZAP
```

This is an excellent demonstration of **multiple independent GROM programs sharing one cartridge without requiring one master launcher to own every menu entry**.

> Historical discussions sometimes loosely call `>8000`, `>A000`, and similar addresses different "GROM bases." In this reference, those are **GROM slots**. A **GROM base** means the CPU port set beginning at `>9800`, `>9804`, and so on.

The proprietary Gamevision image is **not redistributed** with this repository; only its layout is documented as a historical example.

A source-free header/layout breakdown is included at [`../examples/mb-games-layout/`](../examples/mb-games-layout/).

Historical references:

- https://www.videogamehouse.net/gamemain/cartsfh/gamevisiondemo/
- https://www.ti994.com/1979/cartridges/

## Generic example: one GPL GROM launches two banked-ROM applications

A tested two-application design provides a modern example of a different technique. For publication, the source in [`../examples/gpl-multi-program-menu/`](../examples/gpl-multi-program-menu/) has been genericized so it does not identify the original applications.

The example maps a small GPL launcher at logical GROM slot `>8000`. Its header contributes two TI menu entries and launches the corresponding applications from U2 through a scratchpad-resident bank-switch trampoline.

The public example uses illustrative names and addresses:

```text
ROM APP1  -> bank select >6000 -> ROM entry >6100
ROM APP2  -> bank select >6002 -> ROM entry >6100
```

Each GPL menu entry stores the required bank select and ROM entry address in scratchpad. Shared GPL code then constructs:

```asm
       CLR  @bank_select
       B    @rom_entry
```

and transfers control to that scratchpad sequence with `XML >F0`.

Because the bank-select write executes from scratchpad rather than from U2 ROM, the complete `>6000–>7FFF` cartridge window can change safely.

This is a practical pattern for a cartridge containing several CPU-ROM applications: a very small GROM can provide the TI menu while U2 stores the larger programs.

## Add an independent GROM program without adding it to the GPL menu

The GPL launcher does not have to know about every program on the cartridge.

A separate self-contained GROM program may occupy another compatible logical GROM slot and contribute its own menu entry without being added to the `>8000` GPL program list:

| GROM base | Logical slot / resource | Contents | Menu entries |
|---:|---:|---|---|
| base 0 (`>9800`) | GROM `>8000` | GPL multi-ROM launcher | two U2 applications |
| base 0 (`>9800`) | GROM `>A000` | independent GROM image | its own program entry |
| separate U2 | assigned banks | application ROM code | launched by the GPL entries |

The TI selection screen can therefore contain three choices even though the `>8000` launcher itself contains only two program-list entries.

The architectural idea is simple: **the TI builds the selection list from the cartridge headers it discovers**. An independent GROM program contributes its own program entry; it does not have to be inserted into another GROM's program list.

## Same base, different slots versus different GROM bases

There are two useful ways to combine independent GROM programs.

### Different slots in the same base

The Gamevision demonstration cartridge illustrates this approach:

```text
base 0
  >8000  CONNECT FOUR
  >A000  HANGMAN
  >C000  YAHTZEE
  >E000  ZERO-ZAP
```

It works well when each program already expects a different logical GROM slot or has been correctly relocated for that slot.

### Same slot on different bases

If two independent cartridges both expect to live at `>6000`, UberGROM's multiple-base support may allow each to retain that logical slot while being mapped on a different GROM base:

```text
base 0 / >6000  program A
base 1 / >6000  program B
```

This can avoid changing the program's internal GROM address layout. It still must be tested because software may make assumptions about the GROM base or directly access particular GROM CPU ports.

## Compatibility is not automatic

Many GPL/GROM titles are flexible enough to work when combined with other programs, but there is no rule that every cartridge can be moved freely.

Potential incompatibilities include:

- absolute GPL/GROM addresses that assume a particular logical slot such as `>6000`;
- code that directly accesses a particular GROM CPU base rather than using the environment established by the console;
- self-modifying or unusual GROM-address logic;
- GROM+ROM cartridges that also require CPU ROM at `>6000–>7FFF`;
- titles that depend on a particular ROM mapper or ROM bank state; and
- interactions that appear only after `QUIT`, warm reset, or returning from another program.

Community experience suggests that many GROM-only titles are tolerant of alternate locations, while some are not. Treat that as a reason to experiment and record results rather than as a compatibility guarantee.

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
| base 0 (`>9800`) | `>8000` | GROM | page 0 | GPL multi-ROM launcher |
| base 0 (`>9800`) | `>A000` | GROM | page 1 | independent GROM program |
| base 15 (`>983C`) | `>A000` | UART | — | optional serial interface |
| base 15 (`>983C`) | `>E000` | FlashCtl | — | development/configuration only |

The exact physical page numbers are arbitrary; what matters is that the intended bytes are mapped into the logical base/slot expected by the software.

## Related examples and references

- [GPL multi-program / banked-ROM launcher](../examples/gpl-multi-program-menu/)
- [Historical Gamevision GROM layout](../examples/mb-games-layout/)
- [Programming with GROMCFG](02-programming-with-gromcfg.md)
- [512 KiB ROM bank switching](03-rom-bank-switching.md)
- [UberGROM extended features](04-extended-features.md)
