library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;


entity tx_scrambling is
  port (
    clk           : in  std_logic;
    prbs_pi       : in  std_logic_vector(61 downto 0);
    toggle_ena    : in  std_logic;
    force_prbs_pi : in  std_logic;
    data_pi       : in  std_logic_vector(61 downto 0);
    data_po       : out std_logic_vector(63 downto 0)
    );
end tx_scrambling;

architecture rtl of tx_scrambling is

  signal data_d  : std_logic_vector(61 downto 0);
  signal data_t  : std_logic_vector(61 downto 0);
  signal clk_bit : std_logic := '0';

begin

  process(clk)
  begin
    if rising_edge(clk) then
      clk_bit <= not clk_bit;
      data_t  <= data_pi;
    end if;
  end process;

  data_d <= prbs_pi when (force_prbs_pi = '1')  -- PRBS ONLY
            else data_t xor prbs_pi;            -- DATA xor PRBS (mode fonctionnel)

  data_po <= data_d & b"10" when toggle_ena = '0' else data_d & clk_bit & '0';
  -- si toggle_ena = 0 alors le clock bit est a 1 (et non 0), et ceci pour des raisons de
  -- de run length du parity bit.

end rtl;
