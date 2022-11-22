library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity delay2 is
  generic (
    LATENCY : integer := 1);
  port(
    clk   : in  std_logic;
    rst   : in  std_logic;
    valid : in  std_logic;
    d     : in  std_logic;
    q     : out std_logic);
end delay2;

architecture rtl of delay2 is
  signal sr : std_logic_vector(LATENCY downto 1) := (others => '0');
begin
  delay_p : process(clk)
  begin
    if rising_edge(clk) then
      if valid = '1' then
        if rst = '1' then
          sr <= (others => '0');
        else
          sr(1) <= d;
          for index in 2 to LATENCY loop
            sr(index) <= sr(index-1);
          end loop;
        end if;
      end if;
    end if;
  end process;
  q <= sr(LATENCY);
end rtl;
