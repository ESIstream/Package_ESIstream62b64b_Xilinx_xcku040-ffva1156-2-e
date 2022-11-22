library IEEE;
use ieee.std_logic_1164.all;

library work;
use work.esistream6264_pkg.all;

entity tx_lfsr is
  port (
    clk             : in  std_logic;
    force_prbs      : in  std_logic;
    prbs_init_value : in  std_logic_vector(30 downto 0);
    prbs_ena        : in  std_logic;
    prbs_po         : out std_logic_vector(61 downto 0)
    );
end entity tx_lfsr;


architecture rtl of tx_lfsr is

  signal lfsr_out_t : std_logic_vector(61 downto 0) := (others => '0');
  signal prbs_buf   : std_logic_vector(1 downto 0)  := (others => '0');

begin

  prbs_buf(0) <= force_prbs;

  process(clk)
  begin
    if rising_edge(clk) then
      prbs_buf(1) <= prbs_buf(0);
    end if;
  end process;


  process(clk)
  begin
    if rising_edge(clk) then
      if prbs_buf = "01" then  -- rising edge of prbs_init_value
        lfsr_out_t <= f_lfsr(prbs_init_value) & prbs_init_value;
      else
        lfsr_out_t(30 downto 0)  <= f_lfsr(lfsr_out_t(61 downto 31));
        lfsr_out_t(61 downto 31) <= f_lfsr(f_lfsr(lfsr_out_t(61 downto 31)));
      end if;
    end if;
  end process;

  prbs_po <= lfsr_out_t when prbs_ena = '1' else (others => '0');

end architecture rtl;
