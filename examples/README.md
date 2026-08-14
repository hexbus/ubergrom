# Example-program plan

Reference-grade documentation should prefer buildable/testable examples over isolated snippets.

Planned examples:

1. `bank16k/` — two-bank ROM cartridge showing the common startup-header pattern and a scratchpad RAM trampoline.
2. `bank64k/` — eight-bank code/data example with explicitly tracked bank/address targets; generated equates may be added as an optional build convenience.
3. `grom-powerup-bank0/` — tested GPL/GROM power-up link that establishes ROM bank 0 before ROM startup.
4. `uart-echo/` — small annotated example derived from Tursi's `gromtest`, including buffer/status handling and application flow control.
5. `gpio-demo/` — four-pin GPIO example derived from `gromtest`.
6. `adc-meter/` — four-base ADC example derived from `gromtest`.
7. `timer-demo/` — timer measurement example derived from `gromtest`.
8. `eeprom-save/` — persistent user-EEPROM example that avoids unnecessary rewrites.

For UberGROM peripherals, Tursi's current `gromtest` remains the implementation reference. Any smaller examples added here should explain or adapt those access patterns rather than establish a competing interface.

Each directory should contain source, build instructions, expected output/binary hash where practical, mapping notes, and a real-hardware test procedure.
