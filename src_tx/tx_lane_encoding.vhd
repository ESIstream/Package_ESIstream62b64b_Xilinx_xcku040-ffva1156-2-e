library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;


library WORK;
use WORK.esistream6264_pkg.all;


entity tx_lane_encoding is
  generic (
    COMMA : std_logic_vector(63 downto 0));
  port (
    clk : in std_logic;

    prbs_ena   : in std_logic;
    prbs_init  : in std_logic_vector(30 downto 0);
    toggle_ena : in std_logic;
    dc_ena     : in std_logic;

    reset_disparity_pi : in std_logic;
    force_toggle_pi    : in std_logic;
    force_prbs_pi      : in std_logic;
    force_flash_pi     : in std_logic;

    data_pi     : in  std_logic_vector(61 downto 0);
    data_po     : out std_logic_vector(63 downto 0)
    );

end tx_lane_encoding;


architecture rtl of tx_lane_encoding is

  signal prbs           : std_logic_vector(61 downto 0);
  signal scrambled_data : std_logic_vector(63 downto 0);

begin

-------------------------------------------------------------------------------
-- STEP 1 : Generate PRBS
-------------------------------------------------------------------------------
  tx_lfsr_1 : entity work.tx_lfsr
    port map (
      clk             => clk,
      force_prbs      => force_prbs_pi,
      prbs_init_value => prbs_init,
      prbs_ena        => prbs_ena,
      prbs_po         => prbs
      );


-------------------------------------------------------------------------------
-- STEP 2 : DATA XOR PRBS
-------------------------------------------------------------------------------

  tx_scrambling_1 : entity work.tx_scrambling
    port map (
      clk           => clk,
      prbs_pi       => prbs,
      toggle_ena    => toggle_ena,
      force_prbs_pi => force_prbs_pi,
      data_pi       => data_pi,
      data_po       => scrambled_data
      );

-------------------------------------------------------------------------------
-- STEP 3 : Calculate DISPARITY
-------------------------------------------------------------------------------
  tx_disparity_1 : entity work.tx_disparity
    generic map (
      COMMA => COMMA)
    port map (
      clk                => clk,
      dc_ena             => dc_ena,
      reset_disparity_pi => reset_disparity_pi,
      force_toggle_pi    => force_toggle_pi,
      force_flash_pi     => force_flash_pi,
      data_pi            => scrambled_data,
      data_po            => data_po
      );

end rtl;
