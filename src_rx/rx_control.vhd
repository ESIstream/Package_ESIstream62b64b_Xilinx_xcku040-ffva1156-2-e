library work;
use work.esistream6264_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rx_control is
  generic(
    NB_LANES : natural);
  port (
    clk_acq   : in  std_logic;
    rx_usrclk : in  std_logic;
    pll_lock  : in  std_logic_vector(NB_LANES-1 downto 0);  -- Indicates whether GTH CPLL is locked
    rst_done  : in  std_logic_vector(NB_LANES-1 downto 0);  -- Indicates that GTH is ready
    sync_in   : in  std_logic;                              -- Pulse start synchronization demand
    sync_esi  : out std_logic;
    rst_esi   : out std_logic;                              -- Reset logic FPGA, active high
    rst_xcvr  : out std_logic;                              -- Reset GTH, active high
    ip_ready  : out std_logic                               -- Indicates that IP is ready if driven high
    );
end entity rx_control;

architecture rtl of rx_control is

  signal lock       : std_logic                    := '0';
  signal lock_sr    : std_logic_vector(1 downto 0) := (others => '0');
  signal sync_sr    : std_logic_vector(3 downto 0) := (others => '0');
  signal sync_esi_t : std_logic                    := '0';
  signal rst_esi_t  : std_logic                    := '0';

begin

  -- clk_acq domain
  process(clk_acq)
  begin
    if rising_edge(clk_acq) then
      -- Increase sync width to avoid false prbs_status value due to bad logic reset after a new sync.
      sync_sr(0)          <= sync_in;
      sync_sr(3 downto 1) <= sync_sr(2 downto 0);
      sync_esi_t          <= or1(sync_sr);
    end if;
  end process;

  -- rx_usrclk domain

  ff_synchronizer_array_1 : entity work.ff_synchronizer_array
    generic map (
      REG_WIDTH => 1)
    port map (
      clk          => rx_usrclk,
      reg_async(0) => sync_esi_t,  -- acq_clk domain
      reg_sync(0)  => sync_esi     -- clk domain rx_usrclk
      );

  lock     <= and1(pll_lock);
  ip_ready <= and1(rst_done) and lock;
  rst_xcvr <= not lock;

  p_transceiver_pll_lock : process(rx_usrclk)
  begin
    if rising_edge(rx_usrclk) then
      lock_sr(0) <= lock;
      lock_sr(1) <= lock_sr(0);
    end if;
  end process;
   
  p_lock_rising_edge : process(rx_usrclk)
  begin
    if rising_edge(rx_usrclk) then
      rst_esi <= lock_sr(0) and not lock_sr(1);
    end if;
  end process;

end architecture rtl;

