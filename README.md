# rgb_led
VHDL pwm driver for rgb_led

generics for defining all colors as 24 bits values.

direct software control, off by default, can be overriden in by firmware.

clk_1M_ena is divided down to 256 for the 3906.5 pwm period

data mode? that's just direct software control? for now. Maybe a rom with some msg's?

# normal mode
one mode(3 downto 0) control solid on / blink for all simple colors.

- 0 disabled
- 1 red
- 2 green
- 3 blue
- 4 orange
- 5 cyan
- 6 purple
- 7 white
- 8 red blink
- 9 blue blnk
- A green blink
- B orange blink
- C cyan blink
- D purple blink
- E white blink
- F off


# double and triple mode
With this mode enabled the led will cycle through 2 or 3 colors with an optional off state at the end.

color_1 / 2 / 3
- 0 set normal mode if both are 0
- 1 red
- 2 green
- 3 blue
- 4 orange
- 5 cyan
- 6 purple
- 7 white

mode port indicates color and wether an off is inserted in the color chain.
For Instance (1) red will have red as first color, and no off inserted

cycle speed is a generic.

