library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package esistream6264_pkg is

  constant DESER_WIDTH : natural                       := 32;
  constant SER_WIDTH   : natural                       := 64;
  --constant NB_LANES  : natural                       := 11;
  --constant COMMA_PKG : std_logic_vector(63 downto 0) := x"ACF0FF00FFFF0000";  -- when DESER_WITH = 64-bit only
  constant COMMA_PKG   : std_logic_vector(63 downto 0) := x"00FFFF0000FFFF00"; -- when DESER_WIDTH = 32-bit
  
  type type_deser_width_array is array (natural range <>) of std_logic_vector(DESER_WIDTH-1 downto 0);
  type type_64_array is array (natural range <>) of std_logic_vector(64-1 downto 0);
  type type_63_array is array (natural range <>) of std_logic_vector(63-1 downto 0);
  type type_62_array is array (natural range <>) of std_logic_vector(62-1 downto 0);
  type type_32_array is array (natural range <>) of std_logic_vector(32-1 downto 0);
  type type_31_array is array (natural range <>) of std_logic_vector(31-1 downto 0);
  type type_9_array is array (natural range <>) of std_logic_vector(9-1 downto 0);
  type type_7_array is array (natural range <>) of std_logic_vector(7-1 downto 0);
  type type_4_array is array (natural range <>) of std_logic_vector(4-1 downto 0);
  type type_3_array is array (natural range <>) of std_logic_vector(3-1 downto 0);
  type type_2_array is array (natural range <>) of std_logic_vector(1 downto 0);
  type type_1_array is array (natural range <>) of std_logic_vector(0 downto 0);


  type type_62_array_unsigned is array (natural range <>) of unsigned (62-1 downto 0);
  type type_8_array_signed is array (natural range <>) of signed(8-1 downto 0);
  type type_array_int is array (natural range <>) of integer range 0 to 31;

  function f_lfsr(data_in : std_logic_vector(30 downto 0)) return std_logic_vector;
  function and1 (r        : std_logic_vector) return std_logic;
  function or1 (r         : std_logic_vector) return std_logic;
  function nor1 (r        : std_logic_vector) return std_logic;
  function sum1 (r        : type_8_array_signed) return signed;

end package esistream6264_pkg;


package body esistream6264_pkg is



  --============================================================================================= 
  -- The LFSR polynomial used is X31+X28+1.                                                                 
  -- The LFSR is based on a Fibonacci architecture working with steps of 28 bits shifts.                       
  -- The following equations characterize this LFSR:                                                            
  --=============================================================================================
  function f_lfsr(data_in : std_logic_vector(30 downto 0)) return std_logic_vector is
    variable v_lfsr : std_logic_vector(30 downto 0);
  begin
    v_lfsr(30) := data_in(27) xor data_in(30);
    v_lfsr(29) := data_in(26) xor data_in(29);
    v_lfsr(28) := data_in(25) xor data_in(28);
    v_lfsr(27) := data_in(24) xor data_in(27);
    v_lfsr(26) := data_in(23) xor data_in(26);
    v_lfsr(25) := data_in(22) xor data_in(25);
    v_lfsr(24) := data_in(21) xor data_in(24);
    v_lfsr(23) := data_in(20) xor data_in(23);
    v_lfsr(22) := data_in(19) xor data_in(22);
    v_lfsr(21) := data_in(18) xor data_in(21);
    v_lfsr(20) := data_in(17) xor data_in(20);
    v_lfsr(19) := data_in(16) xor data_in(19);
    v_lfsr(18) := data_in(15) xor data_in(18);
    v_lfsr(17) := data_in(14) xor data_in(17);
    v_lfsr(16) := data_in(13) xor data_in(16);
    v_lfsr(15) := data_in(12) xor data_in(15);
    v_lfsr(14) := data_in(11) xor data_in(14);
    v_lfsr(13) := data_in(10) xor data_in(13);
    v_lfsr(12) := data_in(9) xor data_in(12);
    v_lfsr(11) := data_in(8) xor data_in(11);
    v_lfsr(10) := data_in(7) xor data_in(10);
    v_lfsr(9)  := data_in(6) xor data_in(9);
    v_lfsr(8)  := data_in(5) xor data_in(8);
    v_lfsr(7)  := data_in(4) xor data_in(7);
    v_lfsr(6)  := data_in(3) xor data_in(6);
    v_lfsr(5)  := data_in(2) xor data_in(5);
    v_lfsr(4)  := data_in(1) xor data_in(4);
    v_lfsr(3)  := data_in(0) xor data_in(3);
    v_lfsr(2)  := data_in(27) xor data_in(30) xor data_in(2);
    v_lfsr(1)  := data_in(26) xor data_in(29) xor data_in(1);
    v_lfsr(0)  := data_in(25) xor data_in(28) xor data_in(0);
    return v_lfsr;
  end function f_lfsr;

--

  function and1(r : std_logic_vector) return std_logic is
    variable result : std_logic := '1';
  begin
    for i in r'range loop
      result := result and r(i);
    end loop;
    return result;
  end function and1;

--

  function or1(r : std_logic_vector) return std_logic is
    variable result : std_logic := '0';
  begin
    for i in r'range loop
      result := result or r(i);
    end loop;
    return result;
  end function or1;
--

  function nor1(r : std_logic_vector) return std_logic is
    variable result : std_logic := '0';
  begin
    for i in r'range loop
      result := result or r(i);
    end loop;
    return not result;
  end function nor1;

--

  function sum1(r : type_8_array_signed) return signed is
    variable result : signed(7 downto 0) := (others => '0');
  begin
    for i in r'range loop
      result := result + r(i);
    end loop;
    return result;
  end function sum1;

--

end package body esistream6264_pkg;
