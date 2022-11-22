library work;
use work.esistream6264_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;

entity rx_buffer_wrapper is
  port (
    clk        : in  std_logic;
    clk_acq    : in  std_logic;
    sync       : in  std_logic;
    rst_esi    : in  std_logic;
    rd_en      : in  std_logic;
    din_rdy    : in  std_logic;
    din        : in  std_logic_vector(DESER_WIDTH-1 downto 0);
    dout       : out std_logic_vector(DESER_WIDTH-1 downto 0);
    lane_ready : out std_logic
    );
end entity rx_buffer_wrapper;

architecture rtl of rx_buffer_wrapper is

  signal rst   : std_logic := '0';
  signal wr_en : std_logic := '0';
  signal empty : std_logic := '1';

begin

  delay_decoding_rdy : entity work.delay
    generic map (
      LATENCY => (3-DESER_WIDTH/32)*32-1 -1
      )
    port map (
      clk => clk,
      rst => rst,
      d   => din_rdy,
      q   => wr_en
      );

  i_output_buffer_32b : entity work.output_buffer_32b
    port map(
      srst        => rst,
      --clk         => clk,
      wr_clk      => clk,
      rd_clk      => clk_acq,
      din         => din,
      wr_en       => wr_en,
      rd_en       => rd_en,
      dout        => dout,
      full        => open,
      empty       => empty,
      wr_rst_busy => open,
      rd_rst_busy => open
      );

  lane_ready <= not empty;
  rst        <= sync or rst_esi;

end architecture rtl;
