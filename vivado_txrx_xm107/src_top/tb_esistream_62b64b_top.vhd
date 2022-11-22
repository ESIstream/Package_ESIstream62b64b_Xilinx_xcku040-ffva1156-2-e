library work;
use work.esistream6264_pkg.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;



entity tb_esistream_62b64b_top is
end tb_esistream_62b64b_top;

architecture Behavioral of tb_esistream_62b64b_top is

  constant NB_LANES       : natural                       := 11;
  constant COMMA          : std_logic_vector(63 downto 0) := x"ACF0FF00FFFF0000"; --x"00FFFF0000FFFF00";
  constant clk125_period  : time                          := 8 ns;
  constant clk1875_period : time                          := 5.333 ns;
  signal CLK_125MHZ_P     : std_logic                     := '1';
  signal CLK_125MHZ_N     : std_logic                     := '0';
  signal sync             : std_logic                     := '0';
  signal rst_esi          : std_logic                     := '0';
  signal rst_sys          : std_logic                     := '0';
  signal refclk_n         : std_logic                     := '0';
  signal refclk_p         : std_logic                     := '1';

  signal txp : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal txn : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');

  signal d_ctrl       : std_logic_vector(1 downto 0) := "01";
  signal prbs_ena     : std_logic                    := '1';
  signal dc_ena       : std_logic                    := '1';
  signal ip_ready     : std_logic                    := '0';
  signal lanes_ready  : std_logic                    := '0';
  signal be_status    : std_logic                    := '0';
  signal cb_status    : std_logic                    := '0';
  signal valid_status : std_logic                    := '0';


begin

  esistream_62b64b_top_1 : entity work.esistream_62b64b_top
    generic map(
      NB_LANES             => NB_LANES,
      COMMA                => COMMA,
      SYNC_DEBOUNCER_WIDTH => 2)
    port map (
      CLK_125MHZ_P => CLK_125MHZ_P,
      CLK_125MHZ_N => CLK_125MHZ_N,
      sync         => sync,
      rst_esi      => rst_esi,
      rst_sys      => rst_sys,
      refclk_n     => refclk_n,
      refclk_p     => refclk_p,
      rxp          => txp,
      rxn          => txn,
      txp          => txp,
      txn          => txn,
      ip_ready     => ip_ready,
      lanes_ready  => lanes_ready,
      d_ctrl       => d_ctrl,
      prbs_ena     => prbs_ena,
      dc_ena       => dc_ena,
      be_status    => be_status,
      cb_status    => cb_status,
      valid_status => valid_status
      );



  clk125_process : process
  begin
    CLK_125MHZ_P <= '1';
    CLK_125MHZ_N <= '0';
    wait for clk125_period/2;
    CLK_125MHZ_P <= '0';
    CLK_125MHZ_N <= '1';
    wait for clk125_period/2;
  end process;

  clk1875_process : process
  begin
    refclk_p <= '1';
    refclk_n <= '0';
    wait for clk1875_period/2;
    refclk_p <= '0';
    refclk_n <= '1';
    wait for clk1875_period/2;
  end process;


  stimulus_process : process
  begin
    wait for 1 us;

    rst_sys <= '1';
    wait for 10*clk1875_period;
    rst_sys <= '0';
    wait for 600*clk1875_period;

    rst_esi <= '1';
    wait for 10*clk1875_period;
    rst_esi <= '0';
    wait until rising_edge(ip_ready);  -- 3 us;

    wait for 100 ns;
    sync <= '1';
    wait for 100 ns;
    sync <= '0';

    wait for 3 us;

    wait for 100 ns;
    sync <= '1';
    wait for 100 ns;
    sync <= '0';

    wait for 3 us;
    wait;
  end process;


end behavioral;
