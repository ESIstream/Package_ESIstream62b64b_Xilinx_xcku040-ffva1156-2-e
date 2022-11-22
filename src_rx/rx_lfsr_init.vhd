library work;
use work.esistream6264_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;


entity rx_lfsr_init is
  port (
    clk      : in  std_logic;
    din      : in  std_logic_vector(DESER_WIDTH-1 downto 0);
    din_rdy  : in  std_logic;
    prbs_ena : in  std_logic;
    dout     : out std_logic_vector(DESER_WIDTH-1 downto 0);
    dout_rdy : out std_logic;
    prbs     : out std_logic_vector(DESER_WIDTH-DESER_WIDTH/32-1 downto 0)
    );

end entity rx_lfsr_init;


architecture rtl of rx_lfsr_init is

  signal prbsLS      : std_logic_vector(30 downto 0)            := (others => '0');
  signal prbs_init   : std_logic_vector(30 downto 0)            := (others => '0');
  signal prbsMS      : std_logic_vector(30 downto 0)            := (others => '0');
  signal din_rdy_buf : std_logic_vector(3 downto 0)             := "0000";
  signal din_d       : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');
  signal din_2d      : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');
  signal dout_d      : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');

begin


  din_rdy_buf(0) <= din_rdy;

  delay_proc : process(clk)
  begin
    if rising_edge(clk) then
      din_rdy_buf(1) <= din_rdy_buf(0);
      din_rdy_buf(2) <= din_rdy_buf(1);
      din_rdy_buf(3) <= din_rdy_buf(2);
      din_d          <= din;
    end if;
  end process;


  gen_lfsr_proc_64 : if DESER_WIDTH = 64 generate
    process(clk)
    begin
      if rising_edge(clk) then
        if din_rdy = '0' then
          dout_rdy <= '0';
          prbsLS   <= (others => '0');
          prbsMS   <= (others => '0');
        elsif din_rdy_buf = "0001" then  -- lfsr init value
          dout_rdy <= '1';
          if din(0) = '0' then           -- check disparity bit
            prbsLS <= din(32 downto 2);
            prbsMS <= f_lfsr(din(32 downto 2));
          else
            prbsLS <= not din(32 downto 2);
            prbsMS <= f_lfsr(not din(32 downto 2));
          end if;
        else                             -- normal process
          prbsLS <= f_lfsr(prbsMS);
          prbsMS <= f_lfsr(f_lfsr(prbsMS));
        end if;
      end if;
    end process;
    prbs <= prbsMS & prbsLS when prbs_ena = '1' else (others => '0');
    dout <= din_d;
  end generate gen_lfsr_proc_64;


  gen_lfsr_proc_32 : if DESER_WIDTH = 32 generate
    process(clk)
    begin
      if rising_edge(clk) then
        if din_rdy = '0' then
          dout_rdy <= '0';
          prbsLS   <= (others => '0');
        elsif din_rdy_buf = "0111" then  -- lfsr init value
          dout_rdy <= '1';
          -- dout_rdy <= '1';
          -- if din_d(0) = '0' then        -- check disparity bit
          --   prbsLS <= din(0) & din_d(31 downto 2);
          -- else
          --   prbsLS <= not (din(0) & din_d(31 downto 2));
          -- end if;
          if din_2d(0) = '0' then         -- check disparity bit
            prbsLS <= prbs_init;
          else
            prbsLS <= not prbs_init;
          end if;
        else                             -- normal process
          prbsLS <= f_lfsr(prbsLS);
        end if;
      end if;
    end process;

    prbs <= prbsLS when prbs_ena = '1' else (others => '0');

    process(clk)
    begin
      if rising_edge(clk) then
        prbs_init <= din(0) & din_d(31 downto 2);
        din_2d    <= din_d;
        dout      <= din_2d;
      end if;
    end process;

  end generate gen_lfsr_proc_32;


end architecture rtl;
