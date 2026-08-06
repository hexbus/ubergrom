# Source audit

## Highest-authority project sources

1. Final board schematic and PCB revision.
2. Tursi's released GROMSim firmware source and included UberGROM PDF.
3. Known-good cartridge images and fuse readbacks.
4. Original 512K ROM/GROM board manual, separating finished manual text from appended development correspondence.
5. AtariAge posts by the designers and experienced developers.
6. ATmega1284P manufacturer datasheet.

## Known current README defects

- JP1 and JP3 are described as duplicate cartridge-enable jumpers, contrary to the schematic/manual.
- The fuse triplet in the current repository README (`E2/D9/FF`, in low/high/extended order) does not match the project-maintainer-confirmed production setting: Extended `FF`, High `D8`, Low `C2`.
- Logical GROM mapping capacity is presented as though it were physical flash capacity.
- The 128 KiB Flash-only, separate 4 KiB EEPROM, combined 132 KiB Flash+EEPROM, separate 512 KiB cartridge ROM, and GROMCFG device-dump formats are not clearly distinguished.
- The current instructions do not explain the universal-programmer buffer convention: Flash at `>00000`, EEPROM at `>20000`, and **Include EEPROM** for a combined/programmed buffer.
- No executable UART/GPIO/ADC/timer examples are supplied.
- Bank selection lacks the formula `>6000 + bank×2`, startup-state warning, header convention, and safe transition pattern.
- The GROMCFG section delegates essential steps to a video instead of documenting them.

## Editorial policy

- Do not copy unresolved tracked-change correspondence into the manual.
- Every register table must be checked against released firmware source.
- Every assembly example must be assembled and tested.
- Every hardware statement must identify the applicable board revision.
- Historical alternatives such as inverted 74LS379 banking must be clearly labeled and kept separate from the current 74LS378 behavior.
