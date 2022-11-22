library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ff_synchronizer_array is
  generic (
    REG_WIDTH : natural
    );
  port(
    clk       : in  std_logic;
    reg_async : in  std_logic_vector(REG_WIDTH-1 downto 0);
    reg_sync  : out std_logic_vector(REG_WIDTH-1 downto 0)
    );
end ff_synchronizer_array;

architecture rtl of ff_synchronizer_array is
begin
  gen_risingedge : for idx in 0 to REG_WIDTH-1 generate
    two_flop_synchronizer_1 : entity work.two_flop_synchronizer
      port map (
        clk       => clk,
        reg_async => reg_async(idx),
        reg_sync  => reg_sync(idx));
  end generate gen_risingedge;
end rtl;
