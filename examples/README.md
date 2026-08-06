# Example-program plan

Reference-grade documentation requires buildable and testable examples, not isolated snippets.

Planned examples:

1. `bank16k/` — two-bank ROM cartridge with identical headers and a RAM trampoline.
2. `bank64k/` — eight-bank code/data example with generated cross-bank symbols.
3. `uart-echo/` — UART at base 15 / slot `>A000`, 9600 8-N-1.
4. `gpio-demo/` — configure input, pull-up, and output.
5. `adc-meter/` — read one ADC page and display its 0–255 value.
6. `timer-demo/` — measure an interval with wrap-safe subtraction.
7. `eeprom-save/` — save a small record only when changed and verify with CRC.

Each directory should contain assembly source, build script, expected binary hashes, mapping worksheet, and test procedure.
