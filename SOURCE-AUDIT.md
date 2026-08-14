# Source audit

## Source hierarchy

Use the strongest source available for each type of claim:

1. **Released source code** for firmware behavior and register implementation.
2. **Final PCB/schematic/silkscreen** for physical routing, jumpers, and headers.
3. **ATmega1284P manufacturer datasheet** for MCU memory/fuse/electrical behavior.
4. **Known-good programmer images and verified readbacks** for release image layout/practice.
5. **Designer statements/review** for design intent and historical clarification.
6. **Original board manual** after separating finished text from appended development correspondence.
7. **AtariAge/community threads** for development history, examples, and conventions.

## Software ownership boundary

The UberGROM AVR firmware and associated software are **Mike Brent/Tursi's code**, with the license and distribution terms stated in his source.

Authoritative upstream:

- https://github.com/tursilion/ubergrom

The hexbus documentation can explain how that software is used on the jointly developed cartridge board, but must not:

- imply that hexbus owns Tursi's code;
- silently relicense or redistribute modified source contrary to its license;
- describe Jon or another documentation editor as the maintainer of Tursi's software;
- imply that Tursi is responsible for maintaining the hardware documentation.

Hardware/design credit should remain separate from software authorship.

## Designer-review corrections incorporated

### ATmega fuses

Do not publish only `FF/D8/C2`. Also publish what each programmed/unprogrammed bit is intended to do so the software can be ported to another suitable AVR without copying ATmega1284P-specific fuse bytes.

For newly programmed ATmega1284P devices, use `FC/D8/C2` as the recommended setting: it selects approximately 4.3 V brown-out detection. Jon's established `FF/D8/C2` boards remain a known-working BOD-disabled configuration, but disabled BOD is no longer the preferred new-build recommendation.

### JP4

Earlier draft text incorrectly said JP4 was unimplemented.

Released source proves that it is implemented:

- `eeprom.c` checks PC7 before committing configuration-area EEPROM writes;
- `flash.c` checks PC7 before FlashCtl writes and reports write-protected status.

Document the **limited scope** accurately rather than calling it a blanket lock.

### GPIO

Final board: four GPIO pins. Tursi's `gromtest` handles four low bits.

### 74LS378 startup

The 74LS378 does not guarantee a power-up bank. The documentation may describe **measured behavior** when it is clearly labeled empirical: Tursi's BankTest identifies the bank selected on a particular cold power-up, and practical experience commonly finds the first or last bank on these cartridge boards. Never present that observation as a guaranteed device characteristic or make released software depend on it.

BankTest source/reference: https://github.com/tursilion/banktest

Do not forget `QUIT`: it does not hardware-reset the latch, so a detected startup bank is meaningful only immediately after a real power cycle.

### Extended features

Use Tursi's current `gromtest` as the executable reference for UART, GPIO, ADC, timer, RAM, EEPROM, and FlashCtl.

### FlashCtl

Do not label it development-disposable-only. It is a real configuration/update feature, but not a high-frequency storage mechanism.

## U2 versus U3 programming separation

The U2 ROM and U3 ATmega are independent programming domains.

- U2 bank selection is controlled by the 74LS378 address-selected latch.
- U3 GROM Flash/configuration is controlled through Tursi's UberGROM firmware.
- JP1/JP3 are U2-side signal routing. JP1 is not a supported in-circuit-programming control: the current board has no complete in-circuit U2 programming path, and JP1 should remain at 1-2 (U2 write disabled) during normal operation.
- JP4 is U3-side firmware write protection.

Do not imply an ATmega-to-U2 programming connection. Do not imply that moving JP1 enables in-circuit U2 programming. Explain that bank selection uses TI write cycles to clock the 74LS378 while U2 itself remains write-disabled.

## Assembly-example policy

- Explain the bank-selection equation directly.
- State that the write data value is immaterial on this board.
- Prefer assembler-generated transition code copied into scratchpad over hand-entered opcode constants.
- Test complete example cartridges on real hardware before calling them reference builds.


## Complete-release image policy

Do not present a 128 KiB ATmega Flash image by itself as a complete blank-chip cartridge release. The EEPROM map is required to make the intended GROM/peripheral mapping available. A complete ATmega package is either:

- one combined 132 KiB Flash+EEPROM image; or
- separate 128 KiB Flash and 4 KiB EEPROM images.

A Flash-only image is valid when explicitly described as an update that preserves an already-configured EEPROM. Add the separate U2 ROM image when the cartridge uses U2.

## ROM image construction/editorial policy

- Use **bank select** terminology.
- Prefer `>FF` for unused Flash padding.
- Do not imply that generated cross-bank symbol tables or automatic linkers are required; they are optional build conveniences.
- For an every-bank ROM header, put the canonical-bank write as the first instruction at the common startup address so the next instruction is fetched from the canonical bank.
- Mention the GROM/GPL power-up-link option for ROM/GROM cartridges, but do not publish an exact GPL snippet until assembled/tested.

## Extended-feature reference policy

State explicitly that the sizes/table describe the ATmega1284P build. Use `gromtest` as the implementation example. Document:

- 256-byte allocated UART RX/TX buffers with ring-buffer capacity considerations and software flow control;
- factory-calibrated internal oscillator expectation for the timer;
- EEPROM endurance approximately 100,000 cycles;
- Flash endurance approximately 10,000 cycles;
- JP4 as a distribution lock, not merely a generic write-protect jumper.
