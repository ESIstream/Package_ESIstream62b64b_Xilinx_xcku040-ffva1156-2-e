library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;


library WORK;
use WORK.esistream6264_pkg.all;

entity tx_disparity is
  generic (
    COMMA : std_logic_vector(63 downto 0));
  port (
    clk                : in  std_logic;
    dc_ena             : in  std_logic;
    reset_disparity_pi : in  std_logic;
    force_toggle_pi    : in  std_logic;
    force_flash_pi     : in  std_logic;
    data_pi            : in  std_logic_vector(63 downto 0);
    data_po            : out std_logic_vector(63 downto 0)
    );
end tx_disparity;


architecture rtl of tx_disparity is

--  constant cst_borne_max : signed(7 downto 0) := "01000000";  --  = +64
--  constant cst_borne_min : signed(7 downto 0) := "11000000";  --  = -64  

  signal zones             : type_4_array(15 downto 0);
  signal sum_zone          : type_8_array_signed(15 downto 0);
  signal running_disparity : signed(7 downto 0) := (others => '0');

--  signal new_disparity_D0 : signed(7 downto 0);
--  signal new_disparity_D1 : signed(7 downto 0);
  signal new_disparity     : signed(7 downto 0) := (others => '0');
  signal disparity_sav     : signed(7 downto 0) := (others => '0');
  signal reset_disparity_d : std_logic          := '0';
  signal dc_bit            : std_logic;

begin


-- The frame is divided in 16 zones of 4 bits
  process(clk, zones)
  begin
    if rising_edge(clk) then
      for i in 0 to 15 loop
        zones(i) <= data_pi(3+4*i downto 4*i);
      end loop;
    end if;
  end process;

-- sum_zone:
-- "0000" means sum_zone= -4 (surplus of 4 ZERO)
-- "0001" means sum_zone= -2 (surplus of 2 ZERO)
-- "0011" means sum_zone=  0 (ONE and ZERO balanced)
-- "0111" means sum_zone= +2 (surplus of 2 ONE)
-- "1111" means sum_zone= +4 (surplus of 4 ONE)


-- Every possible case for a zone:
-- "0000" =>   sum_zone = "111100" (-4) 
-- "0001" =>   sum_zone = "111110" (-2)
-- "0010" =>   sum_zone = "111110" (-2)    
-- "0011" =>   sum_zone = "000000" (+0)
-- "0100" =>   sum_zone = "111110" (-2)  
-- "0101" =>   sum_zone = "000000" (+0)
-- "0110" =>   sum_zone = "000000" (+0)  
-- "0111" =>   sum_zone = "000010" (+2)     
-- "1000" =>   sum_zone = "111110" (-2)  
-- "1001" =>   sum_zone = "000000" (+0) 
-- "1010" =>   sum_zone = "000000" (+0) 
-- "1011" =>   sum_zone = "000010" (+2)
-- "1110" =>   sum_zone = "000010" (+2)
-- "1101" =>   sum_zone = "000010" (+2)
-- "1111" =>   sum_zone = "000100" (+4)  


---------------------------------------------------------------
  process(clk, zones)
  begin
    if rising_edge(clk) then
      reset_disparity_d <= reset_disparity_pi;
      if reset_disparity_d = '1' or reset_disparity_pi = '1' then
        sum_zone <= (others => (others => '0'));
      else
        for idx in 0 to 15 loop
          case zones(idx) is
            when "0000" => sum_zone(idx) <= "11111100";  -- (-4)           
            when "0001" => sum_zone(idx) <= "11111110";  -- (-2)         
            when "0010" => sum_zone(idx) <= "11111110";  -- (-2)        
            when "0100" => sum_zone(idx) <= "11111110";  -- (-2) 
            when "1000" => sum_zone(idx) <= "11111110";  -- (-2)                                                           
            when "1110" => sum_zone(idx) <= "00000010";  --     (+2)
            when "1101" => sum_zone(idx) <= "00000010";  --     (+2)
            when "1011" => sum_zone(idx) <= "00000010";  --     (+2)
            when "0111" => sum_zone(idx) <= "00000010";  --     (+2)
            when "1111" => sum_zone(idx) <= "00000100";  --     (+4)
            when others => sum_zone(idx) <= "00000000";  -- (+0)    
          end case;
        end loop;
      end if;
    end if;
  end process;
---------------------------------------------------------------

  running_disparity <= sum1(sum_zone) when reset_disparity_pi = '0' else (others => '0');

  dc_bit <= '0' when running_disparity = "00000000" or disparity_sav = "00000000"  -- peut être pas utile
            else '1' when disparity_sav(disparity_sav'high) = running_disparity(running_disparity'high)
            else '0';

  new_disparity <= (others => '0') when reset_disparity_pi = '1'
                   else disparity_sav + running_disparity when dc_bit = '0'
                   else disparity_sav - running_disparity;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset_disparity_pi = '1' then
        disparity_sav <= (others => '0');
      else
        disparity_sav <= new_disparity;
      end if;
    end if;
  end process;


  -- new_disparity_D0 <= disparity_sav + running_disparity;
  -- new_disparity_D1 <= disparity_sav - running_disparity;  -- New disparity with dc_bit = 1
  --
  -- dc_bit <= '1' when ((new_disparity_D0 > cst_borne_max) or (new_disparity_D0 < cst_borne_min))
  --           else '0';
  --
  -- new_disparity <= new_disparity_D1 when dc_bit = '1'
  --                  else new_disparity_D0;

  -- process(clk)
  -- begin
  --   if rising_edge(clk) then
  --     if reset_disparity_pi = '1' then
  --       disparity_sav <= (others => '0');
  --     else
  --       disparity_sav <= new_disparity;
  --     end if;
  --   end if;
  -- end process;

  process(clk)
  begin
    if rising_edge(clk) then

      if force_toggle_pi = '1' then  -- between reset and sync
        data_po <= x"5555555555555555";

      elsif force_flash_pi = '1' then
        data_po <= COMMA;

      elsif dc_ena = '0' then  -- DC disable
        data_po <= data_pi;

      elsif (dc_bit = '0') then  -- mode FUNC DC=0
        data_po <= data_pi;
      else                       -- mode FUNC DC=1
        data_po <= (not data_pi);
      end if;

    end if;
  end process;


end rtl;
