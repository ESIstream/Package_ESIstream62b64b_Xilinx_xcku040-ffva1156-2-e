library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity two_flop_synchronizer is
  port(
    clk       : in  std_logic;
    reg_async : in  std_logic;
    reg_sync  : out std_logic
    );
end two_flop_synchronizer;

architecture rtl of two_flop_synchronizer is
  --
  signal sig_meta                 : std_logic;
  signal sigb                    : std_logic;
  attribute ASYNC_REG             : string;
  attribute ASYNC_REG of sig_meta : signal is "TRUE";
  attribute ASYNC_REG of sigb     : signal is "TRUE";
  --
begin

  P_2FF : process(clk)
  begin
    if rising_edge(clk) then
      sig_meta <= reg_async;  -- metastable
      sigb     <= sig_meta;   -- stable
    end if;
  end process;
  reg_sync <= sigb;
end rtl;
