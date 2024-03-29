library work;
use work.esistream6264_pkg.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;



entity tb_esistream_62b64b_top is
end tb_esistream_62b64b_top;

architecture Behavioral of tb_esistream_62b64b_top is

  constant NB_LANES       : natural                       := 11;
  --constant COMMA          : std_logic_vector(63 downto 0) := x"ACF0FF00FFFF0000";  -- when DESER_WITH = 64-bit only
  --constant COMMA          : std_logic_vector(63 downto 0) := x"00FFFF0000FFFF00"; -- when DESER_WIDTH = 32-bit
  constant clk125_period  : time                          := 8 ns;
  constant clk1875_period : time                          := 5.000 ns; --5.333 ns;
  signal CLK_125MHZ_P     : std_logic                     := '1';
  signal CLK_125MHZ_N     : std_logic                     := '0';
  signal sync             : std_logic                     := '0';
  signal rst_esi          : std_logic                     := '0';
  signal rst_sys          : std_logic                     := '0';
  signal refclk_n         : std_logic                     := '0';
  signal refclk_p         : std_logic                     := '1';

  signal txp : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal txn : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');

  signal d_ctrl       : std_logic_vector(1 downto 0) := "10";
  signal prbs_en      : std_logic                    := '1';
  signal db_en        : std_logic                    := '1';
  signal cb_en        : std_logic                    := '1';
  signal ip_ready     : std_logic                    := '0';
  signal lanes_ready  : std_logic                    := '0';
  signal be_status    : std_logic                    := '0';
  signal cb_status    : std_logic                    := '0';
  signal valid_status : std_logic                    := '0';
  signal syslock      : std_logic                    := '0';
  signal led6, led7   : std_logic                    := '0';
  signal sws, swn     : std_logic                    := '0';

begin

  esistream_62b64b_top_1 : entity work.esistream_62b64b_top
    generic map(
      GEN_ILA              => false,
      SYSRESET_INIT        => x"00F",
      NB_LANES             => NB_LANES,
      COMMA                => COMMA_PKG,
      SYNC_DEBOUNCER_WIDTH => 2)
    port map (
      refclk_n       => refclk_n,
      refclk_p       => refclk_p,
      rxp            => txp,
      rxn            => txn,
      txp            => txp,
      txn            => txn,
      CLK_125MHZ_P   => CLK_125MHZ_P,
      CLK_125MHZ_N   => CLK_125MHZ_N,
      GPIO_LED(0)    => syslock,
      GPIO_LED(1)    => ip_ready,
      GPIO_LED(2)    => lanes_ready,
      GPIO_LED(3)    => cb_status,
      GPIO_LED(4)    => be_status,
      GPIO_LED(5)    => valid_status,
      GPIO_LED(6)    => led6,
      GPIO_LED(7)    => led7,
      GPIO_DIP_SW(0) => prbs_en,
      GPIO_DIP_SW(1) => db_en,
      GPIO_DIP_SW(2) => cb_en,
      GPIO_DIP_SW(3) => d_ctrl(1),
      GPIO_SW_N      => swn,
      GPIO_SW_S      => sws,
      GPIO_SW_C      => rst_esi,
      GPIO_SW_W      => rst_sys,
      GPIO_SW_E      => sync,
      UART_RX        => open,
      UART_TX        => '0'
      );

  CLK_125MHZ_P <= not CLK_125MHZ_P after 4 ns;
  CLK_125MHZ_N <= not CLK_125MHZ_N after 4 ns;
  --
  refclk_p <= not refclk_p after 2.5 ns;
  refclk_n <= not refclk_n after 2.5 ns;
  
  --clk125_process : process
  --begin
  --  CLK_125MHZ_P <= '1';
  --  CLK_125MHZ_N <= '0';
  --  wait for clk125_period/2;
  --  CLK_125MHZ_P <= '0';
  --  CLK_125MHZ_N <= '1';
  --  wait for clk125_period/2;
  --end process;
  -- 
  --clk1875_process : process
  --begin
  --  refclk_p <= '1';
  --  refclk_n <= '0';
  --  wait for clk1875_period/2;
  --  refclk_p <= '0';
  --  refclk_n <= '1';
  --  wait for clk1875_period/2;
  --end process;


  stimulus_process : process
  begin
    wait for 1 us;

    rst_sys <= '1';
    wait for 100 ns;
    
    rst_sys <= '0';
    wait for 500 ns;

    rst_esi <= '1';
    wait for 100 ns;
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

    wait for 10 us;
    wait;
  end process;


end behavioral;
