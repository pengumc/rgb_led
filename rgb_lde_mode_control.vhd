--- @file rgb_led_mode_control
-- handles the blinking and color cycling
-- cycle statmachine outputs the current color.
-- led_mux creates rgb values for color based on generics

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY rgb_led_mode_control IS
  GENERIC (
    CYCLE_TICKS   : positive := 1000; -- number of clk_3K90625_ena ticks that one color lasts
    COLOR_NONE    : std_logic_vector(23 downto 0) := X"000000";
    COLOR_RED     : std_logic_vector(23 downto 0) := X"FF0000";
    COLOR_GREEN   : std_logic_vector(23 downto 0) := X"00FF00";
    COLOR_BLUE    : std_logic_vector(23 downto 0) := X"0000FF";
    COLOR_CYAN    : std_logic_vector(23 downto 0) := X"00FFFF";
    COLOR_YELLOW  : std_logic_vector(23 downto 0) := X"FFFF00";
    COLOR_MAGENTA : std_logic_vector(23 downto 0) := X"FF00FF";
    COLOR_WHITE   : std_logic_vector(23 downto 0) := X"FFFFFF"
  );
  PORT (
    reset_a         : IN std_logic;
    clk             : IN std_logic;
    clk_3K90625_ena : IN std_logic;
    mode            : IN std_logic_vector(15 downto 0); -- mode & c3 & c2 & c1
    led_out         : OUT std_logic(23 downto 0) -- b & g & r
  );
END ENTITY;

ARCHITECTURE rtl OF rgb_led_mode_control IS
  TYPE state_t IS (OFF, COLOR1, COLOR2, COLOR3);
  SIGNAL state        : state_t;
  SIGNAL count        : integer range 0 to CYCLE_TICKS;
  SIGNAL tick         : std_logic;  -- high when count reached CYCLE_TICKS
  SIGNAL clk_ena_prev : std_logic;  -- rising edge detect for clk_3K90625_ena
  ALIAS c1            : std_logic_vector(2 downto 0) := mode(2 downto 0);
  ALIAS c2            : std_logic_vector(2 downto 0) := mode(5 downto 3);
  ALIAS c3            : std_logic_vector(2 downto 0) := mode(8 downto 6);
  ALIAS cmode         : std_logic_vector(6 downto 0) := mode(15 downto 9);
  -- 0 = off
  -- 1 = c1
  -- 2 = c1 off
  -- 3 = c1 c2
  -- 4 = c1 c2 off
  -- 5 = c1 c2 c3
  -- 6 = c1 c2 c3 off
  CONSTANT CMODE_OFF          : std_logic_vector(6 downto 0) := "000000"; -- 0
  CONSTANT CMODE_C1           : std_logic_vector(6 downto 0) := "000001"; -- 1
  CONSTANT CMODE_C1_OFF       : std_logic_vector(6 downto 0) := "000010"; -- 2
  CONSTANT CMODE_C1_C2        : std_logic_vector(6 downto 0) := "000011"; -- 3
  CONSTANT CMODE_C1_C2_OFF    : std_logic_vector(6 downto 0) := "000100"; -- 4
  CONSTANT CMODE_C1_C2_C3     : std_logic_vector(6 downto 0) := "000101"; -- 5
  CONSTANT CMODE_C1_C2_C3_OFF : std_logic_vector(6 downto 0) := "000110"; -- 6
  SIGNAL sel                  : integer range 0 to 7;
  SIGNAL led_mux_out          : std_logic_vector(23 downto 0);
BEGIN

  led_mux_proc: PROCESS(clk, reset_a) 
  BEGIN
    IF (reset_a = '1') THEN
      led_mux_out <= (others=>'0');
    ELSIF (rising_edge(clk)) THEN
      CASE sel IS
        WHEN 0 => led_mux_out <= COLOR_NONE;
        WHEN 1 => led_mux_out <= COLOR_RED;
        WHEN 2 => led_mux_out <= COLOR_GREEN;
        WHEN 3 => led_mux_out <= COLOR_BLUE;
        WHEN 4 => led_mux_out <= COLOR_CYAN;
        WHEN 5 => led_mux_out <= COLOR_MAGENTA;
        WHEN 6 => led_mux_out <= COLOR_YELLOW;
        WHEN 7 => led_mux_out <= COLOR_WHITE;
        WHEN OTHERS => led_mux_out <= COLOR_NONE;
      END CASE;
    END IF;
  END PROCESS;

  main_proc: PROCESS(clk, reset_a) 
  BEGIN
    IF (reset_a = '1') THEN
      count        <= 0;
      tick         <= '0';
      clk_ena_prev <= '0';
      state        <= OFF;
    ELSIF (rising_edge(clk))
      clk_ena_prev <= clk_3K90625_ena;
      -- counting
      IF (clk_ena_prev = '0' AND clk_3K90625_ena = '1') THEN
        IF (count >= CYCLE_TICKS) THEN
          count <= 0;
          tick <= '1';
        ELSE
          count <= count + 1;
          tick <= '0';
        END IF;
      END IF;

      -- states
      CASE state IS
        -- OFF
        WHEN OFF =>
          IF (tick = '1') THEN
            IF (cmode > CMODE_OFF) THEN
              state <= COLOR1;
            END IF;
          END IF;

        -- COLOR 1
        -- on to COLOR2, remain as COLOR1, or back to OFF
        WHEN COLOR1 =>
          IF (tick = '1') THEN
            IF (cmode = CMODE_OFF OR cmode = CMODE_C1_OFF) THEN
              state <= OFF;
            ELSIF (cmode >= CMODE_C1_C2) THEN
              state <= COLOR2;
            END IF;
          END IF;

        -- COLOR 2
        -- on to COLOR3, back to COLOR1, or back to OFF
        WHEN COLOR2 =>
          IF (tick = '1') THEN
            IF (cmode = CMODE_OFF OR cmode = CMODE_C1_C2_OFF) THEN
              state <= OFF;
            ELSIF (cmode >= CMODE_C1_C2_C3) THEN
              state <= COLOR3;
            ELSE
              state <= COLOR1;
            END IF;
          END IF;

        -- COLOR 3
        -- back to OFF, or back to COLOR1
        WHEN COLOR3 =>
          IF (tick = '1') THEN
            IF (cmode = CMODE_OFF OR cmode = CMODE_C1_C2_C3_OFF) THEN
              state <= OFF;
            ELSIF (cmode => CMODE_C1_C2_C3) THEN
              state <= COLOR1;
            END IF;
          END IF;

        -- others
        WHEN OTHERS =>
          state <= OFF;
      END CASE;
    END IF:
  END IF;


  output_proc: PROCESS(state)
  BEGIN
    CASE state IS
      WHEN OFF =>
        sel <= 0;
      WHEN COLOR1 =>
        sel <= to_integer(unsigned(c1));
      WHEN COLOR2 =>
        sel <= to_integer(unsigned(c2));
      WHEN COLOR3 =>
        sel <= to_integer(unsigned(c3));
      WHEN OTHERS =>
        sel <= 0;
    END CASE;
  END PROCESS:

END ARCHITECTURE;


