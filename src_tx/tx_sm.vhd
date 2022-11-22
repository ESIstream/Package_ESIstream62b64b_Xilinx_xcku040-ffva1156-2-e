library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library WORK;
use WORK.esistream6264_pkg.all;

entity tx_sm is
  port (
    clk                : in  std_logic;
    sync               : in  std_logic;
    rst_esi_n          : in  std_logic;
    reset_disparity_po : out std_logic;
    force_flash_po     : out std_logic;
    force_prbs_po      : out std_logic;
    force_toggle_po    : out std_logic
    );
end tx_sm;



architecture rtl of tx_sm is
  --
  signal sm_esis_cpt      : unsigned(4 downto 0)         := (others => '0');
  signal reset_disparity  : std_logic                    := '0';
  signal force_flash      : std_logic                    := '0';
  signal force_prbs       : std_logic                    := '0';
  signal force_toggle     : std_logic                    := '0';
  signal reset_cpt        : std_logic                    := '0';
  signal sm_state_current : std_logic_vector(1 downto 0) := "11";
  signal sm_state_next    : std_logic_vector(1 downto 0) := "11";
  constant SM_WAIT_SYNC   : std_logic_vector(1 downto 0) := "00";
  constant SM_FLASH       : std_logic_vector(1 downto 0) := "01";
  constant SM_PRBS        : std_logic_vector(1 downto 0) := "10";
  constant SM_END         : std_logic_vector(1 downto 0) := "11";
  --
begin
------------------------------------------------------------------------------------------------------------
-- CURRENT STATE
------------------------------------------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if sync = '1' then
        sm_state_current <= SM_WAIT_SYNC;
      else
        sm_state_current <= sm_state_next;
      end if;
    end if;
  end process;

------------------------------------------------------------------------------------------------------------
-- NEXT STATE
-- STATE =  RESET  -> SYNC -> FLASH -> PRBS -> END
------------------------------------------------------------------------------------------------------------

  process(sm_state_current, sm_esis_cpt)
  begin
    case sm_state_current is
      when SM_WAIT_SYNC =>
        sm_state_next   <= SM_FLASH;
        reset_disparity <= '1';
        force_flash     <= '0';
        force_prbs      <= '0';
        force_toggle    <= '1';
        reset_cpt       <= '1';

      when SM_FLASH =>
        if (sm_esis_cpt = TO_UNSIGNED(31, 5)) then
          sm_state_next <= SM_PRBS;
        else
          sm_state_next <= SM_FLASH;
        end if;
        reset_disparity <= '1';
        force_flash     <= '1';
        force_prbs      <= '0';
        force_toggle    <= '0';
        reset_cpt       <= '0';

      when SM_PRBS =>
        if (sm_esis_cpt = TO_UNSIGNED(31, 5)) then
          sm_state_next <= SM_END;
        else
          sm_state_next <= SM_PRBS;
        end if;
        reset_disparity <= '0';
        force_flash     <= '0';
        force_prbs      <= '1';
        force_toggle    <= '0';
        reset_cpt       <= '0';

      when others =>
        sm_state_next   <= SM_END;
        reset_disparity <= '0';
        force_flash     <= '0';
        force_prbs      <= '0';
        force_toggle    <= '0';
        reset_cpt       <= '1';

    end case;
  end process;

------------------------------------------------------------------------------------------------------------
-- COMPTEUR de 1 -> 32
------------------------------------------------------------------------------------------------------------

  process(clk)
  begin
    if rising_edge(clk) then
      if (reset_cpt = '1') then
        sm_esis_cpt <= (others => '0');
      else
        sm_esis_cpt <= sm_esis_cpt + 1;
      end if;
    end if;
  end process;

------------------------------------------------------------------------------------------------------------
-- OUTPUT
------------------------------------------------------------------------------------------------------------
  force_prbs_po <= force_prbs;
  process(clk)
  begin
    if rising_edge(clk) then
      reset_disparity_po <= reset_disparity;
      force_flash_po     <= force_flash;
      force_toggle_po    <= force_toggle;
    end if;
  end process;

end rtl;
