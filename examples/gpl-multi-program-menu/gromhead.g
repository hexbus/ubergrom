* ---------------------------------------------------------------------------
* UberGROM GPL menu / banked-ROM launcher
*
* Working example from the Phoenix + Tacticon Chess UberGROM integration.
* The GROM contains the cartridge menu; the two programs execute from U2 ROM.
* ---------------------------------------------------------------------------
       GROM >8000
       AORG >0000

* Standard GROM cartridge header
       DATA >AA01
       DATA >0100
       DATA >0000        * no power-up routine in this example
       DATA MENU1        * first program-list entry

* Program 1: ROM bank 0, entry >6054
MENU1  DATA MENU2,ONE_START
       STRI "PHOENIX CHESS"

* Program 2: ROM bank 44, entry >6024
MENU2  DATA >0000,TWO_START
       STRI "TACTICON"

ONE_START
       DST  >6000,@>8304 * bank 0 select
       DST  >6054,@>8308 * ROM entry point
       BR   COMMON
       BR   COMMON       * DST does not change the condition bits

TWO_START
       DST  >6058,@>8304 * bank 44 select
       DST  >6024,@>8308 * ROM entry point
                         * fall through to COMMON

* Build a two-instruction TMS9900 trampoline in scratchpad:
*     CLR  @bank-select
*     B    @ROM-entry
COMMON
       DST  >04E0,@>8302 * CLR @ opcode
       DST  >0460,@>8306 * B @ opcode
       XML  >F0          * transfer to the scratchpad assembly sequence

       EXIT
