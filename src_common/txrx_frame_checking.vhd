library work;
use work.esistream6264_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.math_real.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity txrx_frame_checking is
  generic(
    NB_LANES : natural);
  port (
    rst          : in  std_logic;                     -- Active high reset.
    clk          : in  std_logic;                     -- 
    d_ctrl       : in  std_logic_vector(1 downto 0);  --
    lanes_on     : in  std_logic_vector(NB_LANES-1 downto 0);
    frame_out    : in  type_deser_width_array(NB_LANES-1 downto 0);
    lanes_ready  : in  std_logic;
    be_status    : out std_logic;                     -- Active high, bit error detected.
    cb_status    : out std_logic;                     -- Active high, clock bit error detected.
    valid_status : out std_logic
    );
end entity txrx_frame_checking;

architecture rtl of txrx_frame_checking is

  type type_sum_array is array (natural range <>) of type_7_array(8-1 downto 0);
  constant RAMP_DATA_WIDTH               : natural                               := 62;
  --
  signal sum                             : type_sum_array(NB_LANES-1 downto 0)   := (others => (others => (others => '0')));
  signal step                            : std_logic_vector(6 downto 0)          := (others => '0');
  --
  signal data_check_per_ramp             : type_9_array(NB_LANES-1 downto 0)     := (others => (others => '0'));
  --signal data_check_vec                  : type_62_array(NB_LANES-1 downto 0)    := (others => (others => '0'));
  signal data_check_per_lane             : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal cb_check_per_lane               : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal cb_out_d                        : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  --
  signal clk_div                         : std_logic                             := '1';
  signal data_buf                        : type_64_array(NB_LANES-1 downto 0)    := (others => (others => '0'));
  signal data_out_62b                    : type_62_array(NB_LANES-1 downto 0)    := (others => (others => '0'));
  signal data_out_62b_d                  : type_62_array(NB_LANES-1 downto 0)    := (others => (others => '0'));
  signal lanes_ready_d                   : std_logic                             := '0';
  signal lanes_ready_buf                 : std_logic_vector(1 downto 0)          := "00";
  signal clk_init                        : std_logic                             := '0';
  --
  attribute MARK_DEBUG                   : string;
  attribute MARK_DEBUG of data_out_62b_d : signal is "true";
  attribute MARK_DEBUG of cb_status      : signal is "true";
  attribute MARK_DEBUG of be_status      : signal is "true";
--
begin

  lanes_assign_64 : if DESER_WIDTH = 64 generate
    process(clk)
    begin
      for i in 0 to NB_LANES-1 loop
        if rising_edge(clk) then
          data_out_62b(i)   <= frame_out(i)(DESER_WIDTH-1 downto 2);
          data_out_62b_d(i) <= data_out_62b(i);
          data_buf(i)       <= frame_out(i);
        end if;
      end loop;
    end process;
    clk_div <= '1';
  end generate lanes_assign_64;


  lanes_assign_32 : if DESER_WIDTH = 32 generate

    process(clk)
    begin
      if rising_edge(clk) then
        lanes_ready_buf(1) <= lanes_ready_buf(0);
        clk_div            <= not clk_div;
      end if;
    end process;

    lanes_ready_buf(0) <= lanes_ready;


    process(clk)
    begin
      for i in 0 to NB_LANES-1 loop
        if rising_edge(clk) then
          if lanes_ready_buf = "01" then                  -- first part of the first frame
            clk_init                 <= not clk_div;
            data_buf(i)(31 downto 0) <= frame_out(i);
          elsif lanes_ready_buf = "11" then               -- next frames
            if clk_div = clk_init then
              data_buf(i)(63 downto 32) <= frame_out(i);  -- second part of the frame
              data_out_62b_d(i)         <= data_out_62b(i);
            else
              data_buf(i)(31 downto 0) <= frame_out(i);   -- first part of the frame
              data_out_62b(i)          <= data_buf(i)(64-1 downto 2);
            end if;
          else
            data_out_62b(i)   <= (others => '0');
            data_out_62b_d(i) <= (others => '0');
          end if;
        end if;
      end loop;
    end process;

  end generate lanes_assign_32;

  p_step : process(clk)
  begin
    if rising_edge(clk) then
      if clk_div = '1' then
        if (d_ctrl(0) xor d_ctrl(1)) = '0' then
          step <= (others => '0');  -- just check data don't change, either all at x"000" or all at x"FFF". 
        else
          step <= (0 => '1', others => '0');
        end if;
      end if;
    end if;
  end process;

  delay_lanes_ready : entity work.delay2
    generic map (
      LATENCY => 10
      )
    port map (
      clk   => clk,
      rst   => rst,
      valid => clk_div,
      d     => lanes_ready,
      q     => lanes_ready_d
      );

  lanes_check_1 : for i in 0 to NB_LANES-1 generate

    p_check_data_0 : process(clk)
    begin
      if rising_edge(clk) then
        if clk_div = '1' then
          for j in 0 to 7 loop
            sum(i)(j) <= data_out_62b(i)(7*(j+1)-1+6 downto 7*j+6) + step;
          end loop;

          if lanes_on(i) = '0' or lanes_ready_d = '0' then
            data_check_per_ramp(i) <= (others => '0');
          else
            for j in 0 to 7 loop
              if data_out_62b(i)(7*(j+1)-1+6 downto 7*j+6) = sum(i)(j) then
                data_check_per_ramp(i)(j+1) <= '0';
              else
                data_check_per_ramp(i)(j+1) <= '1';
              end if;
            end loop;

            if data_out_62b(i)(5 downto 0) = data_out_62b_d(i)(5 downto 0) then  -- last bits are never changing
              data_check_per_ramp(i)(0) <= '0';
            else
              data_check_per_ramp(i)(0) <= '1';
            end if;
            --data_check_vec(i) <= (0 => data_check_per_lane(i), others => '0');
          end if;
          data_check_per_lane(i) <= or1(data_check_per_ramp(i));

        end if;
      end if;
    end process;


    p_check_clock_bit : process(clk)
    begin
      if rising_edge(clk) then
        if clk_div = '1' then
          cb_out_d(i) <= data_buf(i)(1);
          if lanes_on(i) = '0' or lanes_ready_d = '0' then
            cb_check_per_lane(i) <= '0';
          elsif (data_buf(i)(1) xor cb_out_d(i)) = '1' then
            cb_check_per_lane(i) <= '0';
          else
            cb_check_per_lane(i) <= '1';
          end if;
        end if;
      end if;
    end process;
  end generate lanes_check_1;

  p_bit_error_status : process(clk)
  begin
    if rising_edge(clk) then
      if clk_div = '1' then
        if rst = '1' or lanes_ready_d = '0' then
          be_status <= '0';
        elsif or1(data_check_per_lane) = '1' then
          be_status <= '1';
        end if;
      end if;
    end if;
  end process;

  p_clock_bit_status : process(clk)
  begin
    if rising_edge(clk) then
      if clk_div = '1' then
        if rst = '1' or lanes_ready_d = '0' then
          cb_status <= '0';
        elsif or1(cb_check_per_lane) = '1' then
          cb_status <= '1';
        end if;
      end if;
    end if;
  end process;

  valid_status <= lanes_ready_d;

end architecture rtl;
