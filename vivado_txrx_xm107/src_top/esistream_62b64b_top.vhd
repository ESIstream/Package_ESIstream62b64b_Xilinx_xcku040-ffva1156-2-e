-------------------------------------------------------------------------------
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute
-- this software, either in source code form or as a compiled bitstream, for 
-- any purpose, commercial or non-commercial, and by any means.
--
-- In jurisdictions that recognize copyright laws, the author or authors of 
-- this software dedicate any and all copyright interest in the software to 
-- the public domain. We make this dedication for the benefit of the public at
-- large and to the detriment of our heirs and successors. We intend this 
-- dedication to be an overt act of relinquishment in perpetuity of all present
-- and future rights to this software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- THIS DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES. 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.esistream6264_pkg.all;


entity esistream_62b64b_top is
  generic (
    GEN_ILA              : boolean                       := true;
    SYSRESET_INIT        : std_logic_vector(11 downto 0) := x"FFF";
    NB_LANES             : natural                       := 11;
    COMMA                : std_logic_vector(63 downto 0) := x"ACF0FF00FFFF0000";
    SYNC_DEBOUNCER_WIDTH : natural                       := 24);
  port (
    refclk_n     : in  std_logic;
    refclk_p     : in  std_logic;
    rxp          : in  std_logic_vector(10 downto 0);
    rxn          : in  std_logic_vector(10 downto 0);
    txp          : out std_logic_vector(10 downto 0);
    txn          : out std_logic_vector(10 downto 0);
    --
    CLK_125MHZ_P : in  std_logic;
    CLK_125MHZ_N : in  std_logic;
    GPIO_LED     : out std_logic_vector(7 downto 0);
    GPIO_DIP_SW  : in  std_logic_vector(3 downto 0);
    GPIO_SW_N    : in  std_logic;
    GPIO_SW_S    : in  std_logic;
    GPIO_SW_C    : in  std_logic;
    GPIO_SW_W    : in  std_logic;
    GPIO_SW_E    : in  std_logic;
    UART_RX      : out std_logic;
    UART_TX      : in  std_logic
    );

end esistream_62b64b_top;

architecture rtl of esistream_62b64b_top is
  --
  signal xm107            : std_logic                             := '1';  -- high if the protocole is used with the loop-back card
  --
  signal syslock          : std_logic;
  signal rst_pll          : std_logic;
  signal rst_esi_n        : std_logic;
  signal sysclk           : std_logic;
  signal tx_frame_clk     : std_logic;
  signal rx_frame_clk     : std_logic;
  signal sync_re          : std_logic;
  signal sync_deb         : std_logic;
  signal tx_data          : type_62_array(NB_LANES-1 downto 0);
  signal frame_out        : type_deser_width_array(NB_LANES-1 downto 0);
  signal frame_pip        : type_deser_width_array(NB_LANES-1 downto 0);
  signal frame_ila        : type_deser_width_array(NB_LANES-1 downto 0);
  signal frame_chk        : type_deser_width_array(NB_LANES-1 downto 0);
  signal lanes_ready_t    : std_logic;
  signal lanes_on         : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  -- user interface
  signal d_ctrl           : std_logic_vector(1 downto 0)          := (others => '0');
  signal prbs_en          : std_logic                             := '0';
  signal db_en            : std_logic                             := '0';
  signal cb_en            : std_logic                             := '1';
  signal ip_ready         : std_logic                             := '0';
  signal lanes_ready      : std_logic                             := '0';
  signal be_status        : std_logic                             := '0';
  signal cb_status        : std_logic                             := '0';
  signal valid_status     : std_logic                             := '0';
  signal sync             : std_logic                             := '0';
  signal rst_esi          : std_logic                             := '0';
  signal rst_sys          : std_logic                             := '0';
  --
  signal sysreset         : std_logic                             := '1';
  signal sysresetn        : std_logic                             := '0';
  --
  signal uart_ready       : std_logic                             := '0';
  signal reg_0            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_1            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_2            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_3            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_4            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_5            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_6            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_7            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_8            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_9            : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_10           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_11           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_12           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_13           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_14           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_15           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_16           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_17           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_18           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_19           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_4_os         : std_logic                             := '0';
  signal reg_5_os         : std_logic                             := '0';
  signal reg_6_os         : std_logic                             := '0';
  signal reg_7_os         : std_logic                             := '0';
  signal reg_10_os        : std_logic                             := '0';
  signal reg_12_os        : std_logic                             := '0';
  --
  signal ila_trigger      : std_logic                             := '0';
  signal ila_trigger_init : std_logic_vector(15 downto 0)         := (others => '0');
  signal sync_req         : std_logic                             := '0';
begin
  --
  prbs_en     <= GPIO_DIP_SW(0);
  db_en       <= GPIO_DIP_SW(1);
  cb_en       <= GPIO_DIP_SW(2);
  d_ctrl(1)   <= GPIO_DIP_SW(3);
  --
  GPIO_LED(0) <= syslock;
  GPIO_LED(1) <= ip_ready;
  GPIO_LED(2) <= lanes_ready;
  GPIO_LED(3) <= cb_status;
  GPIO_LED(4) <= be_status;
  GPIO_LED(5) <= valid_status;
  GPIO_LED(6) <= '0';
  GPIO_LED(7) <= uart_ready;
  --
  rst_esi     <= GPIO_SW_C;
  rst_sys     <= GPIO_SW_W;
  sync        <= GPIO_SW_E or sync_req;
  --
  --=========================
  rst_esi_n   <= not rst_esi;
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
  --
  sysreset_1 : entity work.sysreset
    generic map (
      RST_CNTR_INIT => SYSRESET_INIT)
    port map (
      syslock => syslock,
      sysclk  => sysclk,
      reset   => sysreset,
      resetn  => sysresetn);

  rst_pll <= not syslock;

  data_gen_1 : entity work.data_gen
    generic map (
      NB_LANES => NB_LANES)
    port map (
      clk     => tx_frame_clk,
      rst_sys => rst_esi,
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
      cb_en        => cb_en,
      prbs_en      => prbs_en,
      db_en        => db_en,
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

  process(rx_frame_clk)
  begin
    if rising_edge(rx_frame_clk) then
      frame_pip <= frame_out;
      frame_chk <= frame_pip;
      frame_ila <= frame_pip;
    end if;
  end process;

  --------------------------------------------------------------------------------------------
  -- Check reveived data
  --------------------------------------------------------------------------------------------
  txrx_frame_checking_1 : entity work.txrx_frame_checking
    generic map (
      NB_LANES => NB_LANES
      )
    port map (
      rst          => rst_esi,
      clk          => rx_frame_clk,
      d_ctrl       => d_ctrl,
      lanes_on     => lanes_on,
      frame_out    => frame_chk,
      lanes_ready  => lanes_ready_t,
      be_status    => be_status,
      cb_status    => cb_status,
      valid_status => valid_status
      );

  --------------------------------------------------------------------------------------------
  -- ILA data
  --------------------------------------------------------------------------------------------
  gen_ila_hdl : if GEN_ILA = true generate
    ila_data_0 : entity work.ila_data
      port map (
        clk       => rx_frame_clk,
        probe0    => frame_ila(3)(63 downto 2),
        probe1    => frame_ila(4)(63 downto 2),
        probe2    => frame_ila(5)(63 downto 2),
        probe3    => frame_ila(6)(63 downto 2),
        probe4    => frame_ila(7)(63 downto 2),
        probe5    => frame_ila(8)(63 downto 2),
        probe6    => frame_ila(9)(63 downto 2),
        probe7    => frame_ila(10)(63 downto 2),
        probe8(0) => ila_trigger);
  end generate gen_ila_hdl;

  --------------------------------------------------------------------------------------------
  -- UART 8 bit 115200 and Register map
  --------------------------------------------------------------------------------------------
  uart_top_1 : entity work.uart_top
    port map (
      clk        => sysclk,
      rstn       => sysresetn,
      tx         => UART_RX,
      rx         => UART_TX,
      uart_ready => uart_ready,
      reg_0      => reg_0,
      reg_1      => reg_1,
      reg_2      => reg_2,
      reg_3      => reg_3,
      reg_4      => reg_4,
      reg_5      => reg_5,
      reg_6      => reg_6,
      reg_7      => reg_7,
      reg_8      => reg_8,
      reg_9      => reg_9,
      reg_10     => reg_10,
      reg_11     => reg_11,
      reg_12     => reg_12,
      reg_13     => reg_13,
      reg_14     => reg_14,
      reg_15     => reg_15,
      reg_16     => reg_16,
      reg_17     => reg_17,
      reg_18     => reg_18,
      reg_19     => reg_19,
      reg_4_os   => reg_4_os,
      reg_5_os   => reg_5_os,
      reg_6_os   => reg_6_os,
      reg_7_os   => reg_7_os,
      reg_10_os  => reg_10_os,
      reg_12_os  => reg_12_os);

  sync_req    <= reg_0(0);
  ila_trigger <= reg_5_os;
  reg_8(0)    <= prbs_en;
  reg_8(1)    <= db_en;
  reg_8(2)    <= cb_en;
  reg_8(3)    <= d_ctrl(0);
  reg_8(4)    <= d_ctrl(1);

end rtl;
