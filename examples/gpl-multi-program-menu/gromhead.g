* ---------------------------------------------------------------------------
* UberGROM GPL menu / banked-ROM launcher
*
* Genericized from a tested two-application UberGROM implementation.
* The GROM contains the cartridge menu; the applications execute from U2 ROM.
*
* The sample bank selects and ROM entry addresses below are illustrative.
* Change them to match the layout of your own U2 image.
* ---------------------------------------------------------------------------
       GROM >8000
       AORG >0000

* Standard GROM cartridge header
       DATA >AA01
       DATA >0100
       DATA >0000        * no power-up routine in this example
       DATA MENU1        * first program-list entry

* Application 1: sample ROM bank 0, entry >6100
MENU1  DATA MENU2,ONE_START
       STRI "ROM APP1"

* Application 2: sample ROM bank 1, entry >6100
MENU2  DATA >0000,TWO_START
       STRI "ROM APP2"

ONE_START
       DST  >6000,@>8304 * bank 0 select
       DST  >6100,@>8308 * ROM entry point
       BR   COMMON
       BR   COMMON       * DST does not change the condition bits

TWO_START
       DST  >6002,@>8304 * bank 1 select
       DST  >6100,@>8308 * ROM entry point
                         * fall through to COMMON

* Build a two-instruction TMS9900 trampoline in scratchpad:
*     CLR  @bank-select
*     B    @ROM-entry
COMMON
       DST  >04E0,@>8302 * CLR @ opcode
       DST  >0460,@>8306 * B @ opcode
       XML  >F0          * transfer to the scratchpad assembly sequence

       EXIT
