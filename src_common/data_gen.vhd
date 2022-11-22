library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.esistream6264_pkg.all;

entity data_gen is
  generic(
    NB_LANES : natural := 11
    );
  port (
    clk     : in  std_logic;
    rst_sys : in  std_logic;
    d_ctrl  : in  std_logic_vector(1 downto 0);  -- "00" all 0; "11" all 1; else 7 ramps+ of 8 bits & 6 '0'
    tx_data : out type_62_array(NB_LANES-1 downto 0)
    );
end entity data_gen;

architecture rtl of data_gen is

  signal ramp         : std_logic_vector(61 downto 0)      := (others => '0');
  signal ramp_11lanes : type_62_array(NB_LANES-1 downto 0) := (others => (others => '0'));
  signal cnt          : integer range 0 to 255             := 0;

begin

  cnt_process : process(clk)
  begin
    if rising_edge(clk) then
      if rst_sys = '1' or cnt = 255 then
        cnt <= 0;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      for i in 7 downto 0 loop
        ramp(7*(i+1)-1+6 downto 7*i+6) <= std_logic_vector(to_unsigned(cnt, 7));
      end loop;
    end if;
  end process;

  ramp(5 downto 0) <= (others => '0');


  ramp_11lanes <= (others => ramp);
  tx_data      <= (others => (others => '1')) when d_ctrl = "11" else
             (others => (others => '0')) when d_ctrl = "00" else
             ramp_11lanes;

end architecture rtl;
