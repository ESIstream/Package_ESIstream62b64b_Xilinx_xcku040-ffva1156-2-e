library work;
use work.esistream6264_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity rx_frame_alignment is
  generic (
    COMMA : std_logic_vector(63 downto 0));
  port (
    clk              : in  std_logic;
    sync             : in  std_logic;
    rst              : in  std_logic;
    din              : in  std_logic_vector(DESER_WIDTH-1 downto 0);  -- Input misaligned frames 
    aligned_data     : out std_logic_vector(DESER_WIDTH-1 downto 0);  -- Output aligned frames
    aligned_data_rdy : out std_logic                                  -- Indicates that frame alignment is done
    );
end entity rx_frame_alignment;

architecture rtl of rx_frame_alignment is
  --
  function f_comma_len return natural is
    variable v_rtn : natural;
  begin
    if COMMA(31 downto 0) = COMMA(63 downto 32) then
      v_rtn := COMMA'length/2-1;
    else
      v_rtn := COMMA'length-1;
    end if;
    return v_rtn;
  end function f_comma_len;
  --
  --constant comma_length : natural := 32-1;
  --
  signal data_buf           : std_logic_vector(2*DESER_WIDTH-1 downto 0) := (others => '0');              -- buffer used to get aligned data
  signal busy               : std_logic                                  := '0';                          -- If '1' frame alignment in progress
  signal comp_in_comma_32   : type_32_array(f_comma_len downto 0)        := (others => (others => '0'));  -- array with all the possible shifts
  signal comp_in_comma_64   : type_64_array(f_comma_len downto 0)        := (others => (others => '0'));  -- array with all the possible shifts
  signal bitslip            : integer range 0 to f_comma_len             := 0;                            -- number of bit slip to align frames
  signal bitslip_t          : std_logic_vector(f_comma_len downto 0)     := (others => '0');              -- Temp bitslip
  signal bitslip_tt         : std_logic_vector(f_comma_len downto 0)     := (others => '0');              -- Temp bitslip
  signal shift              : std_logic                                  := '0';                          -- If '1' the offset is bitslip + 32
  signal aligned_data_t     : std_logic_vector(DESER_WIDTH-1 downto 0)   := (others => '0');
  signal aligned_data_rdy_t : std_logic                                  := '0';

begin

  gen_comma : for i in f_comma_len downto 0 generate

    gen_comma_1 : if COMMA(31 downto 0) = x"FF0000FF" generate
      process(clk)
      begin
        if rising_edge(clk) then
          comp_in_comma_32(i) <= data_buf(i+f_comma_len downto i);
          bitslip_t(i)        <= and1(comp_in_comma_32(i)(7 downto 0))
                          and and1(comp_in_comma_32(i)(31 downto 24))
                          and nor1(comp_in_comma_32(i)(23 downto 8));
          bitslip_tt(i) <= bitslip_t(i);
        end if;
      end process;
    end generate gen_comma_1;

    gen_comma_2 : if COMMA(31 downto 0) = x"00FFFF00" generate
      process(clk)
      begin
        if rising_edge(clk) then
          comp_in_comma_32(i) <= data_buf(i+f_comma_len downto i);
          bitslip_t(i)        <= nor1(comp_in_comma_32(i)(7 downto 0))
                          and nor1(comp_in_comma_32(i)(31 downto 24))
                          and and1(comp_in_comma_32(i)(23 downto 8));
          bitslip_tt(i) <= bitslip_t(i);
        end if;
      end process;
    end generate gen_comma_2;

    gen_comma_3 : if COMMA(63 downto 0) = x"ACF0FF00FFFF0000" generate
      process(clk)
      begin
        if rising_edge(clk) then
          comp_in_comma_64(i) <= data_buf(i+f_comma_len downto i);
          bitslip_t(i)        <= nor1(comp_in_comma_64(i)(62)&comp_in_comma_64(i)(60))
                          and nor1(comp_in_comma_64(i)(57 downto 56))
                          and nor1(comp_in_comma_64(i)(51 downto 48))
                          and nor1(comp_in_comma_64(i)(39 downto 32))
                          and nor1(comp_in_comma_64(i)(15 downto 0))
                          and and1(comp_in_comma_64(i)(63)&comp_in_comma_64(i)(61))
                          and and1(comp_in_comma_64(i)(59 downto 58))
                          and and1(comp_in_comma_64(i)(55 downto 52))
                          and and1(comp_in_comma_64(i)(47 downto 40))
                          and and1(comp_in_comma_64(i)(31 downto 16));
        end if;
      end process;
    end generate gen_comma_3;
  end generate gen_comma;

  gen_bitslip_1 : if COMMA(31 downto 0) = x"FF0000FF" or COMMA(31 downto 0) = x"00FFFF00" generate
    find_bitslip_proc : process(clk)
    begin
      if rising_edge(clk) then
        if sync = '1' or rst = '1' then
          bitslip <= 0;
          busy    <= '1';
        elsif busy = '1' then
          for i in f_comma_len downto 0 loop
            if bitslip_t(i) = '1' and bitslip_tt(i) = '1' then
              bitslip <= i;
              busy    <= '0';
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_bitslip_1;

  gen_bitslip_2 : if COMMA(63 downto 0) = x"ACF0FF00FFFF0000" generate
    find_bitslip_proc : process(clk)
    begin
      if rising_edge(clk) then
        if sync = '1' or rst = '1' then
          bitslip <= 0;
          busy    <= '1';
        elsif busy = '1' then
          for i in f_comma_len downto 0 loop
            if bitslip_t(i) = '1' then
              bitslip <= i;
              busy    <= '0';
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_bitslip_2;

  align_data_proc_64_3 : if DESER_WIDTH = 64 and COMMA(63 downto 0) = x"ACF0FF00FFFF0000" generate
    process(clk)
    begin
      if rising_edge(clk) then
        data_buf(64*2-1 downto 64) <= din;
        data_buf(64-1 downto 0)    <= data_buf(64*2-1 downto 64);
        if sync = '1' or rst = '1' then
          aligned_data_rdy_t <= '0';
        elsif busy = '0' and aligned_data_rdy_t = '0' and data_buf(63+bitslip downto 0+bitslip) /= COMMA then  -- first frame of PAS
          aligned_data_rdy_t <= '1';
          if data_buf(31+bitslip downto bitslip) /= COMMA(31 downto 0) then
            shift          <= '0';                                                                             -- offset = bitslip       
            aligned_data_t <= data_buf(63+bitslip downto bitslip);
          else
            shift          <= '1';                                                                             -- offset = bitslip + 32  
            aligned_data_t <= data_buf(95+bitslip downto 32+bitslip);
          end if;

        -- else
        elsif aligned_data_rdy_t = '1' then
          if shift = '0' then
            aligned_data_t <= data_buf(63+bitslip downto bitslip);
          else
            aligned_data_t <= data_buf(95+bitslip downto 32+bitslip);
          end if;

        end if;
      end if;
    end process;
  end generate align_data_proc_64_3;

  align_data_proc_64 : if DESER_WIDTH = 64 and COMMA(31 downto 0) = COMMA(63 downto 32) generate
    process(clk)
    begin
      if rising_edge(clk) then
        data_buf(64*2-1 downto 64) <= din;
        data_buf(64-1 downto 0)    <= data_buf(64*2-1 downto 64);
        if sync = '1' or rst = '1' then
          aligned_data_rdy_t <= '0';
        elsif busy = '0' and aligned_data_rdy_t = '0' and data_buf(63+bitslip downto 32+bitslip) /= COMMA(31 downto 0) then  -- first frame of PAS
          aligned_data_rdy_t <= '1';
          if data_buf(31+bitslip downto bitslip) /= COMMA(31 downto 0) then
            shift          <= '0';                                                                                           -- offset = bitslip       
            aligned_data_t <= data_buf(63+bitslip downto bitslip);
          else
            shift          <= '1';                                                                                           -- offset = bitslip + 32  
            aligned_data_t <= data_buf(95+bitslip downto 32+bitslip);
          end if;

        -- else
        elsif aligned_data_rdy_t = '1' then
          if shift = '0' then
            aligned_data_t <= data_buf(63+bitslip downto bitslip);
          else
            aligned_data_t <= data_buf(95+bitslip downto 32+bitslip);
          end if;

        end if;
      end if;
    end process;
  end generate align_data_proc_64;

  align_data_proc_32 : if DESER_WIDTH = 32 and COMMA(31 downto 0) = COMMA(63 downto 32) generate
    process(clk)
    begin
      if rising_edge(clk) then
        data_buf(63 downto 32) <= din;
        data_buf(31 downto 0)  <= data_buf(63 downto 32);
        if sync = '1' or rst = '1' then
          aligned_data_rdy_t <= '0';
        elsif busy = '0' and data_buf(31+bitslip downto bitslip) /= COMMA(31 downto 0) then
          aligned_data_rdy_t <= '1';
        end if;
      end if;
    end process;
    --
    process(clk)
    begin
      if rising_edge(clk) then
        aligned_data_t <= data_buf(31+bitslip downto bitslip);
      end if;
    end process;
  end generate align_data_proc_32;

  aligned_data_rdy <= aligned_data_rdy_t;
  aligned_data     <= aligned_data_t;

end architecture rtl;
