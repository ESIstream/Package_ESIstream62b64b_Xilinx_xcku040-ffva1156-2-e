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
use ieee.numeric_std.all;

entity uart_top is
  port (
    -- AXI MASTER PORT
    clk        : in  std_logic;
    rstn       : in  std_logic;
    -- UART PORT
    tx         : out std_logic;
    rx         : in  std_logic;
    uart_ready : out std_logic;
    -- Registers PORT
    reg_0      : out std_logic_vector(31 downto 0);
    reg_1      : out std_logic_vector(31 downto 0);
    reg_2      : out std_logic_vector(31 downto 0);
    reg_3      : out std_logic_vector(31 downto 0);
    reg_4      : out std_logic_vector(31 downto 0);
    reg_5      : out std_logic_vector(31 downto 0);
    reg_6      : out std_logic_vector(31 downto 0);
    reg_7      : out std_logic_vector(31 downto 0);
    reg_8      : in  std_logic_vector(31 downto 0);
    reg_9      : in  std_logic_vector(31 downto 0);
    reg_10     : in  std_logic_vector(31 downto 0);
    reg_11     : in  std_logic_vector(31 downto 0);
    reg_12     : out std_logic_vector(31 downto 0);
    reg_13     : out std_logic_vector(31 downto 0);
    reg_14     : out std_logic_vector(31 downto 0);
    reg_15     : out std_logic_vector(31 downto 0);
    reg_16     : out std_logic_vector(31 downto 0);
    reg_17     : out std_logic_vector(31 downto 0);
    reg_18     : in  std_logic_vector(31 downto 0);
    reg_19     : in  std_logic_vector(31 downto 0);
    reg_4_os   : out std_logic;
    reg_5_os   : out std_logic;
    reg_6_os   : out std_logic;
    reg_7_os   : out std_logic;
    reg_10_os  : out std_logic;
    reg_12_os  : out std_logic
    );
end uart_top;

architecture rtl of uart_top is
  --
  signal m_axi_addr  : std_logic_vector(3 downto 0)  := (others => '0');
  signal m_axi_strb  : std_logic_vector(3 downto 0)  := (others => '0');
  signal m_axi_wdata : std_logic_vector(31 downto 0) := (others => '0');
  signal m_axi_rdata : std_logic_vector(31 downto 0) := (others => '0');
  signal m_axi_wen   : std_logic                     := '0';
  signal m_axi_ren   : std_logic                     := '0';
  signal m_axi_busy  : std_logic                     := '0';
  signal interrupt   : std_logic                     := '0';
  --
  signal rstn_re     : std_logic                     := '0';
--
begin
  --------------------------------------------------------------------------------------------
  -- UART 8 bit 115200 and Register map
  --------------------------------------------------------------------------------------------
  uart_wrapper_1 : entity work.uart_wrapper
    port map (
      clk         => clk,
      rstn        => rstn,
      m_axi_addr  => m_axi_addr,
      m_axi_strb  => m_axi_strb,
      m_axi_wdata => m_axi_wdata,
      m_axi_rdata => m_axi_rdata,
      m_axi_wen   => m_axi_wen,
      m_axi_ren   => m_axi_ren,
      m_axi_busy  => m_axi_busy,
      interrupt   => interrupt,
      tx          => tx,
      rx          => rx);

  risingedge_1 : entity work.risingedge
    port map (
      rst => '0',
      clk => clk,
      d   => rstn,
      re  => rstn_re
      );

  register_map_1 : entity work.register_map
    generic map (
      CLK_FREQUENCY_HZ => 100000000,
      TIME_US          => 1000000)
    port map (
      clk          => clk,
      rstn         => rstn,
      interrupt_en => rstn_re,
      m_axi_addr   => m_axi_addr,
      m_axi_strb   => m_axi_strb,
      m_axi_wdata  => m_axi_wdata,
      m_axi_rdata  => m_axi_rdata,
      m_axi_wen    => m_axi_wen,
      m_axi_ren    => m_axi_ren,
      m_axi_busy   => m_axi_busy,
      interrupt    => interrupt,
      uart_ready   => uart_ready,
      reg_0        => reg_0,
      reg_1        => reg_1,
      reg_2        => reg_2,
      reg_3        => reg_3,
      reg_4        => reg_4,
      reg_5        => reg_5,
      reg_6        => reg_6,
      reg_7        => reg_7,
      reg_8        => reg_8,
      reg_9        => reg_9,
      reg_10       => reg_10,
      reg_11       => reg_11,
      reg_12       => reg_12,
      reg_13       => reg_13,
      reg_14       => reg_14,
      reg_15       => reg_15,
      reg_16       => reg_16,
      reg_17       => reg_17,
      reg_18       => reg_18,
      reg_19       => reg_19,
      reg_4_os     => reg_4_os,
      reg_5_os     => reg_5_os,
      reg_6_os     => reg_6_os,
      reg_7_os     => reg_7_os,
      reg_10_os    => reg_10_os,
      reg_12_os    => reg_12_os);
  --
end rtl;
