library work;
use work.esistream6264_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rx_esistream is
  generic (
    NB_LANES    : natural;
    DESER_WIDTH : natural;
    COMMA       : std_logic_vector(63 downto 0));
  port (
    rst_xcvr      : out std_logic;                                          -- Reset of the XCVR
    rx_rstdone    : in  std_logic_vector(NB_LANES-1 downto 0);              -- Reset done of RX XCVR part
    xcvr_pll_lock : in  std_logic_vector(NB_LANES-1 downto 0);              -- PLL locked from XCVR part
    rx_usrclk     : in  std_logic;                                          -- RX User Clock from XCVR
    xcvr_data_rx  : in  std_logic_vector(DESER_WIDTH*NB_LANES-1 downto 0);  -- RX User data from RX XCVR part

    prbs_en     : in  std_logic;
    sync_in     : in  std_logic;                                    -- active high synchronization pulse input
    clk_acq     : in  std_logic;                                    -- acquisition clock, output buffer read port clock, should be same frequency and no phase drift with receive clock (default: clk_acq should take rx_clk).
    frame_out   : out type_deser_width_array(NB_LANES-1 downto 0);  -- decoded output frame: disparity bit (0) + clk bit (1) + data (63 downto 2) (descrambling and disparity processed)  
    ip_ready    : out std_logic;                                    -- active high ip ready output (transceiver pll locked and transceiver reset done)
    lanes_ready : out std_logic;                                    -- active high lanes ready output, indicates all lanes are synchronized (alignement and prbs initialization done)
    lanes_on    : in  std_logic_vector(NB_LANES-1 downto 0)
    );
end entity rx_esistream;

architecture rtl of rx_esistream is

  signal lane_ready_t  : std_logic_vector(NB_LANES-1 downto 0)       := (others => '0');
  signal lanes_ready_t : std_logic                                   := '0';
  signal rst_esi       : std_logic                                   := '0';
  signal sync_esi      : std_logic                                   := '0';
  signal xcvr_data     : type_deser_width_array(NB_LANES-1 downto 0) := (others => (others => '0'));


begin

  --============================================================================================================================
  -- Instantiate RX Control module
  --============================================================================================================================
  i_rx_control : entity work.rx_control
    generic map(
      NB_LANES => NB_LANES)
    port map(
      clk_acq   => clk_acq,        -- IN  - clk_acq
      rx_usrclk => rx_usrclk,      -- IN  - rx_usrclk
      pll_lock  => xcvr_pll_lock,  -- IN     
      rst_done  => rx_rstdone,     -- IN     
      sync_in   => sync_in,        -- IN  - clk_acq domain
      sync_esi  => sync_esi,       -- OUT - rx_usrclk domain
      rst_esi   => rst_esi,        -- OUT - rx_usrclk domain
      rst_xcvr  => rst_xcvr,       -- OUT - rx_usrclk domain
      ip_ready  => ip_ready        -- OUT - rx_usrclk domain
      );


  --============================================================================================================================
  -- Instantiate rx_lane_decoding
  --============================================================================================================================
  lane_decoding_gen : for index in 0 to (NB_LANES - 1) generate
  begin

    rx_lane_decoding_1 : entity work.rx_lane_decoding
      generic map (
        COMMA => COMMA)
      port map (
        clk        => rx_usrclk,            -- rx_usrclk
        clk_acq    => clk_acq,              -- clk_acq
        frame_in   => xcvr_data(index),     -- rx_usrclk domain
        sync       => sync_esi,             -- rx_usrclk domain
        rst_esi    => rst_esi,              -- rx_usrclk domain
        prbs_ena   => prbs_en,
        read_fifo  => lanes_ready_t,
        lane_ready => lane_ready_t(index),  -- clk_acq domain
        frame_out  => frame_out(index)      -- clk_acq domain
        );
  end generate;

  --=================================================================================================================
  -- Assignements output 
  --=================================================================================================================
  process(clk_acq)
  begin
    if rising_edge(clk_acq) then
      lanes_ready_t <= and1((lane_ready_t and lanes_on) xnor lanes_on); lanes_ready_t <= and1((lane_ready_t and lanes_on) xnor lanes_on);
      lanes_ready   <= lanes_ready_t;
    end if;
  end process;

  --=================================================================================================================
  -- Transceiver User interface
  --=================================================================================================================
  gen_xcvr_data : for idx in 0 to NB_LANES-1 generate
    xcvr_data(idx) <= xcvr_data_rx(DESER_WIDTH*idx + (DESER_WIDTH-1) downto DESER_WIDTH*idx);  -- rx_usrclk domain
  end generate gen_xcvr_data;

end architecture rtl;
