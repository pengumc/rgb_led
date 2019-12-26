--- @file rgb_led_pwm.vhd
-- Does pwm for three leds.
-- Also outputs the clk_3K90625_ena

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY rgb_led_pwm IS
  PORT (
    reset_a         : IN std_logic;
    clk             : IN std_logic;
    clk_1M_ena      : IN std_logic;
    clk_3K90625_ena : OUT std_logic;
    rgb_in          : IN std_logic_vector(23 downto 0); -- r & g & b
    red             : OUT std_logic;
    green           : OUT std_logic;
    blue            : OUT std_logic
  );
END ENTITY;

ARCHITECTURE rtl OF rgb_led_pwm IS
  SIGNAL count           : integer range 0 to 255;
  SIGNAL clk_1M_ena_prev : std_logic;
BEGIN

  -- counting and clk dividing
  count_proc: PROCESS(clk, reset_a)
  BEGIN
    IF (reset_a = '1') THEN
      count           <= 0;
      clk_1M_ena_prev <= '0';
      clk_3K90625_ena <= '0';
    ELSIF (rising_edge(clk)) THEN
      IF (clk_1M_ena_prev = '0' AND clk_1M_ena = '1') THEN
        IF (count = 254) THEN
          clk_3K90625_ena <= '1';
          count <= 0;
        ELSE
          clk_3K90625_ena <= '0';
          count <= count + 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  -- pwm comparison
  pwm_proc: PROCESS(clk, reset_a)
  BEGIN
    IF (reset_a = '1') THEN
      red   <= '0';
      green <= '0';
      blue  <= '0';
    ELSE
      -- red
      IF (to_integer(unsigned(rgb_in(23 downto 16))) >= count) THEN
        red <= '1';
      ELSE
        red <= '0';
      END IF;

      -- green
      IF (to_integer(unsigned(rgb_in(15 downto 8))) >= count) THEN
        green <= '1';
      ELSE
        green <= '0';
      END IF;

      -- blue
      IF (to_integer(unsigned(rgb_in(7 downto 0))) >= count) THEN
        blue <= '1';
      ELSE
        blue <= '0';
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;
