library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library work;
use work.esistream6264_pkg.all;

entity rx_decoder is
  port (
    clk      : in  std_logic;
    din      : in  std_logic_vector(DESER_WIDTH - 1 downto 0);
    din_rdy  : in  std_logic;
    prbs     : in  std_logic_vector(DESER_WIDTH-DESER_WIDTH/32-1 downto 0);
    data_out : out std_logic_vector(DESER_WIDTH - 1 downto 0)
    );
end entity rx_decoder;

architecture rtl of rx_decoder is

  signal disparity_mask   : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');
  signal data_db          : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');
  signal descrambled_data : std_logic_vector(DESER_WIDTH-1 downto 0) := (others => '0');

  signal prbs_buf    : std_logic                    := '0';
  signal db          : std_logic                    := '0';
  signal db_d        : std_logic                    := '0';
  signal div_clk     : std_logic                    := '0';
  signal din_rdy_buf : std_logic_vector(1 downto 0) := (others => '0');

begin

  gen_decoder_64 : if DESER_WIDTH = 64 generate
    disparity_mask   <= (others => din(0));
    data_db          <= (din xor disparity_mask);
    descrambled_data <= data_db xor (prbs & "00");
  end generate gen_decoder_64;


  gen_decoder_32 : if DESER_WIDTH = 32 generate

    process(clk)
    begin
      if rising_edge(clk) then
        din_rdy_buf(0) <= din_rdy;
        din_rdy_buf(1) <= din_rdy_buf(0);
        db_d           <= db;
        prbs_buf       <= prbs(30);
        if din_rdy_buf = "01" then
          div_clk <= '1';
        else
          div_clk <= not div_clk;  -- frame_in[31:0] : div_clk = '1'  //  frame_in[63:32] : div_clk = '0'
        end if;
      end if;
    end process;

    db             <= din(0) when div_clk = '1' else db_d;
    disparity_mask <= (others => db);
    data_db        <= (din xor disparity_mask);

    descrambled_data <= (data_db(DESER_WIDTH-1 downto 2) xor prbs(29 downto 0)) & data_db(1 downto 0) when div_clk = '1'
                        else (data_db(DESER_WIDTH-1 downto 1) xor prbs) & (data_db(0) xor prbs_buf);

  end generate gen_decoder_32;

  data_out <= descrambled_data when din_rdy = '1' else (others => '0');

end architecture rtl;
