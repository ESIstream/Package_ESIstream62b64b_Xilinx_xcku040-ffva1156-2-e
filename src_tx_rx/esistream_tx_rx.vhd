library ieee;
use ieee.std_logic_1164.all;

library work;
use work.esistream6264_pkg.all;


entity esistream_tx_rx is
  generic (
    NB_LANES : natural;
    COMMA    : std_logic_vector(63 downto 0));
  port (
    sync         : in  std_logic;
    rst_esi_n    : in  std_logic;
    cb_en        : in  std_logic;
    prbs_en      : in  std_logic;
    db_en        : in  std_logic;
    data_in      : in  type_62_array(NB_LANES-1 downto 0);
    --
    rst_pll      : in  std_logic;
    sysclk       : in  std_logic;
    refclk_n     : in  std_logic;
    refclk_p     : in  std_logic;
    rxp          : in  std_logic_vector(NB_LANES-1 downto 0);
    rxn          : in  std_logic_vector(NB_LANES-1 downto 0);
    txp          : out std_logic_vector(NB_LANES-1 downto 0);
    txn          : out std_logic_vector(NB_LANES-1 downto 0);
    tx_frame_clk : out std_logic;
    rx_frame_clk : out std_logic;
    --
    frame_out    : out type_deser_width_array(NB_LANES-1 downto 0);
    valid_out    : out std_logic;
    ip_ready     : out std_logic;
    lanes_ready  : out std_logic;
    lanes_on     : in  std_logic_vector(NB_LANES-1 downto 0)
    );

end esistream_tx_rx;

architecture rtl of esistream_tx_rx is

  signal data_tx_xcvr      : std_logic_vector(SER_WIDTH*NB_LANES-1 downto 0)   := (others => '0');
  signal rst_xcvr          : std_logic                                         := '0';
  signal rx_rstdone        : std_logic_vector(NB_LANES-1 downto 0)             := (others => '0');
  signal rx_frame_clk_t    : std_logic                                         := '1';
  signal rx_frame_clk_xcvr : std_logic                                         := '1';
  signal rx_usrclk         : std_logic                                         := '1';
  signal tx_usrclk         : std_logic                                         := '1';
  signal xcvr_pll_lock     : std_logic_vector(NB_LANES-1 downto 0)             := (others => '0');
  signal data_xcvr_rx      : std_logic_vector(DESER_WIDTH*NB_LANES-1 downto 0) := (others => '0');
  signal tx_ip_ready       : std_logic                                         := '0';
  signal rx_ip_ready       : std_logic                                         := '0';

begin

  --TX
  tx_esistream_1 : entity work.tx_esistream
    generic map (
      NB_LANES => NB_LANES,
      COMMA    => COMMA)
    port map (
      clk       => tx_usrclk,
      sync      => sync,
      rst_esi_n => rst_esi_n,
      cb_en     => cb_en,
      prbs_en   => prbs_en,
      db_en     => db_en,
      data_in   => data_in,
      data_out  => data_tx_xcvr
      );

  --XCVR
  xcvr_wrapper_1 : entity work.xcvr_wrapper
    generic map (
      NB_LANES    => NB_LANES,
      DESER_WIDTH => DESER_WIDTH,
      SER_WIDTH   => SER_WIDTH)
    port map (
      rst           => rst_pll,
      rst_xcvr      => rst_xcvr,
      sysclk        => sysclk,
      refclk_n      => refclk_n,
      refclk_p      => refclk_p,
      rxp           => rxp,
      rxn           => rxn,
      txp           => txp,
      txn           => txn,
      rx_rstdone    => rx_rstdone,
      rx_frame_clk  => rx_frame_clk_xcvr,
      tx_frame_clk  => tx_frame_clk,
      rx_usrclk     => rx_usrclk,
      tx_usrclk     => tx_usrclk,
      xcvr_pll_lock => xcvr_pll_lock,
      tx_ip_ready   => tx_ip_ready,
      data_in       => data_tx_xcvr,
      data_out      => data_xcvr_rx
      );
  ip_ready       <= tx_ip_ready and rx_ip_ready;
  
  rx_frame_clk   <= rx_usrclk;

  --RX
  rx_esistream_1 : entity work.rx_esistream
    generic map (
      NB_LANES    => NB_LANES,
      DESER_WIDTH => DESER_WIDTH,
      COMMA       => COMMA)
    port map (
      rst_xcvr      => rst_xcvr,
      rx_rstdone    => rx_rstdone,
      xcvr_pll_lock => xcvr_pll_lock,
      rx_usrclk     => rx_usrclk,
      xcvr_data_rx  => data_xcvr_rx,
      prbs_en       => prbs_en,
      sync_in       => sync,
      clk_acq       => rx_usrclk,
      frame_out     => frame_out,
      valid_out     => valid_out,
      ip_ready      => rx_ip_ready,
      lanes_ready   => lanes_ready,
      lanes_on      => lanes_on
      );

end rtl;
