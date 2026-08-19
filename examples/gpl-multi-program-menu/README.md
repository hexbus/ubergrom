# GPL menu launching multiple banked-ROM programs

This is a working GPL/GROM-side launcher from the Phoenix + Tacticon Chess UberGROM integration.

It demonstrates an important UberGROM design pattern: **one cartridge can expose several independent programs even when they are stored in different places.** The GROM side can supply menu entries and launchers, while U2 holds one or more bank-switched ROM applications. Additional ordinary GROM programs can occupy other GROM slots or bases and be discovered by the TI's cartridge scan as separate menu entries.

Files:

- `gromhead.g` — cleaned GPL source for the working Chess launcher.
- `gromhead.gbc` — the assembled 70-byte output used for testing.

## What the Chess launcher does

The example is assembled for logical GROM slot `>8000`:

```text
GROM >8000
AORG >0000
```

Its cartridge header points to a two-entry GPL program list:

```text
PHOENIX CHESS  -> bank select >6000 -> ROM entry >6054
TACTICON       -> bank select >6058 -> ROM entry >6024
```

On this board, `>6000` selects U2 bank 0 and `>6058` selects U2 bank 44.

GPL does not execute the bank change directly from U2 ROM. Instead, each menu entry places the required bank select and ROM entry address into scratchpad. `COMMON` then builds this tiny TMS9900 sequence there:

```asm
       CLR  @bank_select
       B    @rom_entry
```

and transfers control to it with `XML >F0`. Because the actual bank-select write executes from scratchpad RAM, changing the complete `>6000–>7FFF` cartridge ROM window is safe.

## Adding a third, GROM-resident program

The Chess launcher does **not** need to contain every menu choice on the cartridge. A separate GROM image with its own valid cartridge header/program list can be mapped into another cartridge GROM location and the console can discover it independently.

A useful example is a GROM-only title such as Hangman. Do not redistribute proprietary cartridge images unless you have permission; this is a mapping example only.

### Simplest layout: another slot in the same base

If the additional GROM image is already built for logical GROM `>6000`, leave it there and place the Chess launcher at `>8000`:

| GROM base | Logical slot | Contents | Menu entries contributed |
|---:|---:|---|---|
| base 0 (`>9800`) | `>6000` | GROM-only program, e.g. Hangman | `HANGMAN` |
| base 0 (`>9800`) | `>8000` | Chess GPL launcher | `PHOENIX CHESS`, `TACTICON` |

U2 independently contains the actual Phoenix and Tacticon ROM banks.

The result is one physical cartridge with **three discoverable program choices**: one program executing from GROM and two programs executing from bank-switched U2 ROM.

The physical UberGROM Flash page numbers do not have to match the logical GROM numbers. GROMCFG maps a physical page to the required base/slot.

### Using another GROM base

UberGROM can also expose different mappings on multiple GROM bases. A **base** is the CPU port set (`>9800`, `>9804`, ...); a **slot** is one of the cartridge GROM address ranges (`>6000`, `>8000`, `>A000`, `>C000`, `>E000`) within that base.

This can be useful when two independent GROM images both expect to live at the same logical slot. Instead of relocating one image, they may be mapped at the same slot on different enabled bases, provided the cartridge is configured and tested for multiple-base operation.

For example:

| GROM base | Logical slot | Contents |
|---:|---:|---|
| base 0 (`>9800`) | `>8000` | Chess GPL launcher |
| base 1 (`>9804`) | `>6000` | another GROM cartridge image built for `>6000` |

The UberGROM hardware/firmware supports sixteen bases, and the TI cartridge selection scan checks the available bases when building its selection list. This is one of the features that makes UberGROM more than simply a replacement for one physical GROM chip.

## Important: mapping is not relocation

Mapping a physical UberGROM page into a different logical slot changes **where the bytes appear**; it does not rewrite absolute GPL/GROM addresses stored inside the image.

If an existing GROM cartridge was assembled for `>6000`, the safest arrangement is to keep it at `>6000`—either in a free slot on the current base or on another enabled GROM base. If you move an address-dependent GROM image to a different slot such as `>A000`, it may require relocation.

## Why this example matters

This example shows three separate concepts working together:

1. **GROM can provide the cartridge menu without containing the ROM application itself.**
2. **One GPL header can contribute multiple menu entries that launch different U2 ROM banks.**
3. **Other GROM images can independently contribute their own menu entries from another slot or base.**

That means an UberGROM cartridge can be assembled as a collection of ROM programs, GROM programs, or a mixture of both rather than being limited to one title.

## Adapting this launcher for another U2 multi-ROM cartridge

The working Chess source is intentionally small enough to use as a pattern for other cartridges.

For each ROM-resident menu entry, change only the application-specific values:

```text
menu text
bank select
ROM entry address
```

The shared `COMMON` routine remains the same: it builds `CLR @bank_select / B @rom_entry` in scratchpad and transfers to it with `XML >F0`.

If more ROM programs are added, extend the GPL program-list chain with another menu entry and another small setup block that places its bank select and entry address in scratchpad before branching to `COMMON`.

The example has **no GPL power-up link**; its header's power-up pointer is zero. It demonstrates program-list launching, not automatic bank initialization during the console power-up scan. A tested power-up-link example should remain a separate example when one is available.

## Combining this launcher with ordinary GROM cartridges

The launcher can share the cartridge with independent GROM-resident programs. A useful historical comparison is the Milton Bradley multi-game cartridge, whose individual game images occupy different logical GROM slots and contain their own cartridge headers/program-list entries.

For example, the Chess launcher at `>8000` can coexist with a self-contained GROM title at `>A000`; the TI can discover the GROM program independently while the Chess header contributes its two U2 launch entries.

See [`../../docs/06-multi-program-cartridges.md`](../../docs/06-multi-program-cartridges.md) for the complete discussion of slots, bases, the Milton Bradley example, and compatibility testing.
