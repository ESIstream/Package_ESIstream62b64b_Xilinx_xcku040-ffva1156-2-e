library ieee;
use ieee.std_logic_1164.all;

library work;
use work.esistream6264_pkg.all;


entity esistream_62b64b_top is
  generic (
    NB_LANES             : natural                       := 11;
    COMMA                : std_logic_vector(63 downto 0) := x"AC0F99FF0000FFFF";
    SYNC_DEBOUNCER_WIDTH : natural                       := 24);
  port (
    CLK_125MHZ_P : in  std_logic;
    CLK_125MHZ_N : in  std_logic;
    sync         : in  std_logic;
    rst_esi      : in  std_logic;
    rst_sys      : in  std_logic;
    refclk_n     : in  std_logic;
    refclk_p     : in  std_logic;
    rxp          : in  std_logic_vector(10 downto 0);
    rxn          : in  std_logic_vector(10 downto 0);
    txp          : out std_logic_vector(10 downto 0);
    txn          : out std_logic_vector(10 downto 0);

    d_ctrl       : in  std_logic_vector(1 downto 0);
    prbs_ena     : in  std_logic;
    dc_ena       : in  std_logic;
    ip_ready     : out std_logic;
    lanes_ready  : out std_logic;
    be_status    : out std_logic;
    cb_status    : out std_logic;
    valid_status : out std_logic
    );

end esistream_62b64b_top;

architecture rtl of esistream_62b64b_top is

  signal toggle_ena : std_logic := '1';
  signal xm107      : std_logic := '1';  -- high if the protocole is used with the loop-back card

  signal syslock       : std_logic;
  signal rst_pll       : std_logic;
  signal rst_esi_n     : std_logic;
  signal sysclk        : std_logic;
  signal tx_frame_clk  : std_logic;
  signal rx_frame_clk  : std_logic;
  signal sync_re       : std_logic;
  signal sync_deb      : std_logic;
  signal tx_data       : type_62_array(NB_LANES-1 downto 0);
  signal frame_out     : type_deser_width_array(NB_LANES-1 downto 0);
  signal lanes_ready_t : std_logic;
  signal lanes_on      : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');

begin

  --=========================
  rst_esi_n <= not rst_esi;
  --========================

  lanes_on <= X"FF" & "000" when xm107 = '1' else (others => '1');  -- xm107 has only 8 available serial links

  i_pll_sys : entity work.clk_wiz_0
    port map (
      clk_out1  => sysclk,
      reset     => rst_sys,
      locked    => syslock,
      clk_in1_p => CLK_125MHZ_P,
      clk_in1_n => CLK_125MHZ_N
      );

  rst_pll <= not syslock;

--

  data_gen_1 : entity work.data_gen
    generic map (
      NB_LANES => NB_LANES)
    port map (
      clk     => tx_frame_clk,
      rst_sys => rst_esi,  --rst_sys,
      d_ctrl  => d_ctrl,
      tx_data => tx_data
      );
--

  debouncer_1 : entity work.debouncer
    generic map (
      WIDTH => SYNC_DEBOUNCER_WIDTH)
    port map (
      clk   => tx_frame_clk,
      deb_i => sync,
      deb_o => sync_deb);

  risingedge_1 : entity work.risingedge
    port map (
      rst => rst_esi,
      clk => tx_frame_clk,
      d   => sync_deb,
      re  => sync_re
      );
--

  esistream_tx_rx_1 : entity work.esistream_tx_rx
    generic map (
      NB_LANES => NB_LANES,
      COMMA    => COMMA)
    port map (
      sync         => sync_re,
      rst_esi_n    => rst_esi_n,
      toggle_ena   => toggle_ena,
      prbs_ena     => prbs_ena,
      dc_ena       => dc_ena,
      data_in      => tx_data,
      rst_pll      => rst_pll,
      sysclk       => sysclk,
      refclk_n     => refclk_n,
      refclk_p     => refclk_p,
      rxp          => rxp,
      rxn          => rxn,
      txp          => txp,
      txn          => txn,
      tx_frame_clk => tx_frame_clk,
      rx_frame_clk => rx_frame_clk,
      frame_out    => frame_out,
      ip_ready     => ip_ready,
      lanes_ready  => lanes_ready_t,
      lanes_on     => lanes_on
      );

  lanes_ready <= lanes_ready_t;

  txrx_frame_checking_1 : entity work.txrx_frame_checking
    generic map (
      NB_LANES => NB_LANES
      )
    port map (
      rst          => rst_esi,
      clk          => rx_frame_clk,
      d_ctrl       => d_ctrl,
      lanes_on     => lanes_on,
      frame_out    => frame_out,
      lanes_ready  => lanes_ready_t,
      be_status    => be_status,
      cb_status    => cb_status,
      valid_status => valid_status
      );

end rtl;
