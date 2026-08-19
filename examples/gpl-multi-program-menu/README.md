# GPL menu launching multiple banked-ROM applications

This directory contains a **genericized GPL/GROM-side launcher pattern** derived from a tested two-application UberGROM implementation.

It demonstrates an important UberGROM design pattern: one GROM header can contribute multiple TI cartridge-menu entries while the corresponding applications live in the separate bank-switched U2 ROM. Additional self-contained GROM programs can occupy other logical GROM slots or other GROM bases and contribute their own menu entries independently.

Files:

- `gromhead.g` — generic GPL source showing the launcher pattern.
- `gromhead.gbc` — a matching generic raw GROM block using the sample values in `gromhead.g`.

> The **launcher technique** has been validated in a working two-application cartridge. The public source and binary here have deliberately generic menu names and sample U2 addresses. Change the bank selects and ROM entry points to match your own cartridge before using the example.

## What the launcher does

The example is assembled for logical GROM slot `>8000` and contributes two program-list entries:

```text
ROM APP1
ROM APP2
```

The sample mapping is intentionally simple:

```text
ROM APP1  -> bank select >6000 -> ROM entry >6100
ROM APP2  -> bank select >6002 -> ROM entry >6100
```

The two applications are therefore assumed, for illustration, to begin at the same CPU address in two different 8 KiB U2 banks. Real programs may use any valid bank select and entry address required by their layout.

Each GPL menu entry stores two values in scratchpad:

```text
>8304  bank select
>8308  ROM entry address
```

Shared GPL code then builds this TMS9900 sequence in scratchpad:

```asm
       CLR  @bank_select
       B    @rom_entry
```

and transfers control to it with `XML >F0`.

The bank-select write therefore executes from scratchpad rather than from U2. That is important because selecting a bank immediately changes the complete CPU cartridge window at `>6000–>7FFF`.

## Adapting the example

For each U2-resident application, change:

1. the menu text;
2. the bank select (`>6000 + bank × 2`); and
3. the CPU entry address in the selected bank.

Add more GPL program-list entries by chaining them in the usual TI cartridge-header format and routing each entry through the same shared scratchpad launcher.

## Adding a separate GROM-resident program

The GPL launcher does **not** have to contain every menu choice on the cartridge. A separate GROM image with its own valid `>AA` cartridge header and program list can be mapped into another compatible GROM slot and discovered independently by the TI.

For example:

| GROM base | Logical slot | Contents | Menu entries contributed |
|---:|---:|---|---|
| base 0 (`>9800`) | `>8000` | GPL multi-ROM launcher | two U2 applications |
| base 0 (`>9800`) | `>A000` | independent GROM program | its own program entry |

U2 independently contains the ROM banks launched by the GPL entries. The resulting TI selection screen can therefore contain three choices even though only two of them are listed in the `>8000` GPL program list.

If an independent GROM cartridge needs a slot already in use, UberGROM's multiple-base support may allow it to keep its expected logical GROM address on another base. Compatibility still has to be tested because some software assumes a particular slot, GROM base, ROM window, or mapper state.

## Program-list launcher versus power-up link

This example is a **program-list launcher**, not a GPL power-up-link example. Its power-up pointer is zero:

```asm
       DATA >0000        * no power-up routine in this example
```

A GPL power-up link can be used for a different purpose: establishing a known U2 ROM bank before normal cartridge startup. Do not confuse that mechanism with the menu launcher shown here.

See [`../../docs/06-multi-program-cartridges.md`](../../docs/06-multi-program-cartridges.md) for the broader discussion of GROM slots, multiple GROM bases, the historical Gamevision demonstration cartridge, and compatibility testing.
