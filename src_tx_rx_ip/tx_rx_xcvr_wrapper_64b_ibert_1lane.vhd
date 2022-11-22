library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.esistream6264_pkg.all;

library unisim;
use unisim.vcomponents.all;


entity xcvr_wrapper is
  generic (
    NB_LANES    : natural := 11;                                -- number of lanes
    DESER_WIDTH : natural := 64;
    SER_WIDTH   : natural := 64
    );
  port (
    rst           : in  std_logic;                              -- Active high (A)synchronous reset
    rst_xcvr      : in  std_logic;                              -- Active high (A)synchronous reset
    sysclk        : in  std_logic;                              -- transceiver ip system clock
    refclk_n      : in  std_logic;                              -- transceiver ip reference clock
    refclk_p      : in  std_logic;                              -- transceiver ip reference clock
    rxp           : in  std_logic_vector(NB_LANES-1 downto 0);  -- lane serial input p
    rxn           : in  std_logic_vector(NB_LANES-1 downto 0);  -- lane Serial input n
    txp           : out std_logic_vector(NB_LANES-1 downto 0);  -- lane serial output p
    txn           : out std_logic_vector(NB_LANES-1 downto 0);  -- lane Serial output n
    rx_rstdone    : out std_logic_vector(NB_LANES-1 downto 0);  --  := (others => '0');
    rx_frame_clk  : out std_logic;
    tx_frame_clk  : out std_logic;
    rx_usrclk     : out std_logic;
    tx_usrclk     : out std_logic;
    xcvr_pll_lock : out std_logic_vector(NB_LANES-1 downto 0);
    tx_ip_ready   : out std_logic;
    data_in       : in  std_logic_vector(SER_WIDTH*NB_LANES-1 downto 0);
    data_out      : out std_logic_vector(DESER_WIDTH*NB_LANES-1 downto 0)
    );
end entity xcvr_wrapper;

architecture rtl of xcvr_wrapper is

  signal refclk            : std_logic                                                     := '0';
  signal tx_rstdone_single : std_logic                                                     := '0';
  signal rx_rstdone_single : std_logic                                                     := '0';
  signal qpll_lock         : std_logic_vector(integer(floor(real(NB_LANES)/4.0)) downto 0) := (others => '0');
  signal gtrefclk00_in     : std_logic_vector(integer(floor(real(NB_LANES)/4.0)) downto 0) := (others => '0');
  signal rx_usrclk_1       : std_logic_vector(0 downto 0)                                  := (others => '0');
  signal rx_usrclk_2       : std_logic_vector(0 downto 0)                                  := (others => '0');
  signal rx_usrclk_t       : std_logic                                                     := '0';
  signal rx_usrclk_11      : std_logic_vector(NB_LANES-1 downto 0)                         := (others => '0');
  signal tx_usrclk_1       : std_logic_vector(0 downto 0)                                  := (others => '0');
  signal tx_usrclk_2       : std_logic_vector(0 downto 0)                                  := (others => '0');
  signal refclk_div2       : std_logic                                                     := '0';
  signal odiv2             : std_logic                                                     := '0';
  signal bufggt_clr        : std_logic                                                     := '0';
  signal bufggt_ce         : std_logic                                                     := '0';
  -- eye scan signals : 
  signal drpaddr           : std_logic_vector(NB_LANES*9-1 downto 0)                       := (others => '0');
  signal drpen_array       : type_1_array(NB_LANES-1 downto 0)                             := (others => (others => '0'));
  signal drpdi             : std_logic_vector(NB_LANES*16-1 downto 0)                      := (others => '0');
  signal drpdo             : std_logic_vector(NB_LANES*16-1 downto 0)                      := (others => '0');
  signal drprdy_array      : type_1_array(NB_LANES-1 downto 0);
  signal drpwe_array       : type_1_array(NB_LANES-1 downto 0)                             := (others => (others => '0'));
  signal drpwe             : std_logic_vector(NB_LANES-1 downto 0)                         := (others => '0');
  signal drpen             : std_logic_vector(NB_LANES-1 downto 0)                         := (others => '0');
  signal drprdy            : std_logic_vector(NB_LANES-1 downto 0)                         := (others => '0');
  signal drpclk            : std_logic_vector(NB_LANES-1 downto 0)                         := (others => '0');
  signal eyescanreset      : std_logic_vector(NB_LANES-1 downto 0)                         := (others => '0');
  signal rxrate            : std_logic_vector(NB_LANES*3-1 downto 0)                       := (others => '0');
  signal txdiffctrl        : std_logic_vector(NB_LANES*4-1 downto 0)                       := (others => '1');  -- 1080 mV
  signal txprecursor       : std_logic_vector(NB_LANES*5-1 downto 0)                       := (others => '0');  -- 0.00 dB
  signal txpostcursor      : std_logic_vector(NB_LANES*5-1 downto 0)                       := "01000";          -- 1.94 dB / "01000" concatenate 1 times
  signal rxlpmen           : std_logic_vector(NB_LANES-1 downto 0)                         := (others => '0');
  signal tx_rst_xcvr       : std_logic                                                     := '0';
  signal rx_rst_xcvr       : std_logic                                                     := '0';
  signal qpll_lock_and1    : std_logic                                                     := '0';

begin
  --============================================================================================================================
  -- Assignments
  --============================================================================================================================
  rx_rst_xcvr   <= rst_xcvr;
  rx_rstdone    <= (others => rx_rstdone_single);
  xcvr_pll_lock <= (others => qpll_lock_and1);

  qpll_lock_and1 <= and1(qpll_lock);
  tx_rst_xcvr    <= not qpll_lock_and1;
  tx_ip_ready    <= qpll_lock_and1 and tx_rstdone_single;

  --============================================================================================================================
  -- Clock buffer for REFCLK
  --============================================================================================================================
  IBUFDS_GTE3_MGTREFCLK0_INST : IBUFDS_GTE3
    generic map(
      REFCLK_EN_TX_PATH  => '0',
      REFCLK_HROW_CK_SEL => "00",
      REFCLK_ICNTL_RX    => "00"
      )
    port map(
      I     => refclk_p,
      IB    => refclk_n,
      CEB   => '0',
      O     => refclk,
      ODIV2 => odiv2
      );
  gtrefclk00_in <= (others => refclk);

  --============================================================================================================================
  -- Clock buffer for ODIV2
  --============================================================================================================================
  BUFG_GT_SYNC_inst : BUFG_GT_SYNC
    port map (
      CESYNC  => bufggt_ce,   -- 1-bit output: Synchronized CE
      CLRSYNC => bufggt_clr,  -- 1-bit output: Synchronized CLR
      CE      => '1',         -- 1-bit input: Asynchronous enable
      CLK     => odiv2,       -- 1-bit input: Clock
      CLR     => '0'          -- 1-bit input: Asynchronous clear
      );

  BUFG_GT_inst : BUFG_GT
    port map (
      O       => refclk_div2,  -- 1-bit output: Buffer
      CE      => bufggt_ce,    -- 1-bit input: Buffer enable
      CEMASK  => '0',          -- 1-bit input: CE Mask
      CLR     => bufggt_clr,   -- 1-bit input: Asynchronous clear
      CLRMASK => '0',          -- 1-bit input: CLR Mask
      DIV     => "000",        -- 3-bit input: Dynamic divide Value
      I       => odiv2         -- 1-bit input: Buffer
      );

  --============================================================================================================================
  -- XCVR instance
  --============================================================================================================================
  -- GTH Transceivers
  gth_txrx_1lane_64b_1 : entity work.gth_txrx_1lane_64b
    port map(
      gtwiz_userclk_tx_reset_in(0)       => tx_rst_xcvr,
      gtwiz_userclk_tx_srcclk_out        => open,
      gtwiz_userclk_tx_usrclk_out        => tx_usrclk_1,
      gtwiz_userclk_tx_usrclk2_out       => tx_usrclk_2,
      gtwiz_userclk_tx_active_out        => open,
      gtwiz_userclk_rx_reset_in(0)       => rx_rst_xcvr,
      gtwiz_userclk_rx_srcclk_out        => open,
      gtwiz_userclk_rx_usrclk_out        => rx_usrclk_1,
      gtwiz_userclk_rx_usrclk2_out       => rx_usrclk_2,
      gtwiz_userclk_rx_active_out        => open,
      gtwiz_reset_clk_freerun_in(0)      => sysclk,
      gtwiz_reset_all_in(0)              => rst,
      gtwiz_reset_tx_pll_and_datapath_in => (others => '0'),
      gtwiz_reset_tx_datapath_in         => (others => '0'),
      gtwiz_reset_rx_pll_and_datapath_in => (others => '0'),
      gtwiz_reset_rx_datapath_in         => (others => '0'),
      gtwiz_reset_rx_cdr_stable_out      => open,
      gtwiz_reset_tx_done_out(0)         => tx_rstdone_single,
      gtwiz_reset_rx_done_out(0)         => rx_rstdone_single,
      gtwiz_userdata_tx_in               => data_in,
      gtwiz_userdata_rx_out              => data_out,
      gtrefclk00_in                      => gtrefclk00_in, --refclk,
      qpll0lock_out                      => qpll_lock,
      qpll0outclk_out                    => open,
      qpll0outrefclk_out                 => open,
      gthrxn_in                          => rxn,
      gthrxp_in                          => rxp,
      rxpd_in                            => (others => '0'),  -- RX part powered-on
      txpd_in                            => (others => '0'),  -- TX part power-down
      gthtxn_out                         => txn,
      gthtxp_out                         => txp,
      gtpowergood_out                    => open,
      rxpmaresetdone_out                 => open,
      txpmaresetdone_out                 => open,
      -- IBERT --
      drpaddr_in                         => drpaddr,
      drpclk_in                          => drpclk,
      drpdi_in                           => drpdi,
      drpen_in                           => drpen,
      drpwe_in                           => drpwe,
      eyescanreset_in                    => eyescanreset,
      rxlpmen_in                         => rxlpmen,
      rxrate_in                          => rxrate,
      txdiffctrl_in                      => txdiffctrl,
      txpostcursor_in                    => txpostcursor,
      txprecursor_in                     => txprecursor,
      drpdo_out                          => drpdo,
      drprdy_out                         => drprdy
      );
  --
  tx_usrclk    <= tx_usrclk_2(0);
  rx_usrclk    <= rx_usrclk_2(0);
  rx_usrclk_11 <= (others => rx_usrclk_2(0));

  rx_frame_clk <= refclk_div2;
  tx_frame_clk <= tx_usrclk_2(0);

  --============================================================================================================================
  -- IBERT instance
  --============================================================================================================================
  in_system_ibert_0_i : entity work.in_system_ibert_1lane
    port map(
      rxoutclk_i => rx_usrclk_11,
      clk        => sysclk,

      gt0_drpen_o   => drpen_array(0),
      gt0_drpwe_o   => drpwe_array(0),
      gt0_drpaddr_o => drpaddr(8 downto 0),
      gt0_drpdi_o   => drpdi(15 downto 0),
      gt0_drprdy_i  => drprdy_array(0),
      gt0_drpdo_i   => drpdo(15 downto 0),


      drpclk_o       => drpclk,
      eyescanreset_o => eyescanreset,
      rxrate_o       => rxrate,
      txdiffctrl_o   => txdiffctrl,
      txprecursor_o  => txprecursor,
      txpostcursor_o => txpostcursor,
      rxlpmen_o      => rxlpmen
      );

  gen_array_to_vec : for i in 0 to NB_LANES-1 generate
    drpen(i)  <= drpen_array(i)(0);
    drpwe(i)  <= drpwe_array(i)(0);
    drprdy(i) <= drprdy_array(i)(0);
  end generate gen_array_to_vec;


end architecture rtl;
