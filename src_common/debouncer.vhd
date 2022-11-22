library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
  generic(
    WIDTH : natural := 24);
  port (
    clk    : in  std_logic;
    deb_i  : in  std_logic := '1';
    deb_o  : out std_logic
    );
end debouncer;

architecture rtl of debouncer is

  signal cntr_v           : unsigned(WIDTH-1 downto 0) := (others => '0');
  signal deb_o_t          : std_logic                  := '0';
  constant CNTR_END_VALUE : unsigned(WIDTH-1 downto 0) := (others => '1');

begin

  p_cntr_v : process(clk)
  begin
    if rising_edge(clk) then
      if deb_i = '0' then
        cntr_v     <= (others => '0');
        deb_o_t    <= '0';
      else
        if cntr_v = CNTR_END_VALUE then
          cntr_v   <= CNTR_END_VALUE;
          deb_o_t  <= '1';
        else
          cntr_v   <= cntr_v+1;
          deb_o_t  <= '0';
        end if;
      end if;
    end if;
  end process;

  deb_o  <= deb_o_t;

end rtl;
