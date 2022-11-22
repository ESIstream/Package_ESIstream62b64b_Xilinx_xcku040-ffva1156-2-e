library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;


library WORK;
use WORK.esistream6264_pkg.all;


entity tx_esistream is
  generic (
    NB_LANES : natural;
    COMMA    : std_logic_vector(63 downto 0));
  port (
    clk        : in  std_logic;
    sync       : in  std_logic;
    rst_esi_n  : in  std_logic;
    toggle_ena : in  std_logic;
    prbs_ena   : in  std_logic;
    dc_ena     : in  std_logic;
    data_in    : in  type_62_array(NB_LANES-1 downto 0);
    data_out   : out std_logic_vector(NB_LANES*SER_WIDTH-1 downto 0)
    );
end tx_esistream;


architecture rtl of tx_esistream is

  constant C_PRBS_INIT : type_31_array(11-1 downto 0) := ("101" & x"C4C" & x"CF53",
                                                          "011" & x"CBF" & x"F586",
                                                          "000" & x"D98" & x"8250",
                                                          "101" & x"1D8" & x"7EBA",
                                                          "110" & x"548" & x"64D3",
                                                          "001" & x"917" & x"C221",
                                                          "110" & x"018" & x"2136",
                                                          "001" & x"DFF" & x"446C",
                                                          "001" & x"70C" & x"B5F1",
                                                          "110" & x"EF2" & x"CA4A",
                                                          "000" & x"000" & x"0001");
  signal force_prbs      : std_logic := '0';
  signal force_flash     : std_logic := '0';
  signal reset_disparity : std_logic := '0';
  signal force_toggle    : std_logic := '0';
  signal data_enco       : type_64_array(NB_LANES-1 downto 0);
  signal prbs_init : type_31_array(NB_LANES-1 downto 0);
  --
begin

-----------------------------------------------
---- STATE MACHINE ESISTREAM
-----------------------------------------------
  inst_tx_sm : entity WORK.tx_sm
    port map(
      clk                => clk,
      sync               => sync,
      rst_esi_n          => rst_esi_n,
      force_prbs_po      => force_prbs,
      force_flash_po     => force_flash,
      reset_disparity_po => reset_disparity,
      force_toggle_po    => force_toggle
      );

--------------------------------------------------------
---- INSTANCIATION DES 11 BLOCS D'ENCODAGE ESISTREAM
--------------------------------------------------------
  gen_sub_encoding : for idx in NB_LANES-1 downto 0 generate
  begin
    prbs_init(idx) <= C_PRBS_INIT(idx);
    tx_lane_encoding_idx : entity work.tx_lane_encoding
      generic map (
        COMMA => COMMA)
      port map (
        clk => clk,

        prbs_ena   => prbs_ena,
        prbs_init  => prbs_init(idx),
        toggle_ena => toggle_ena,
        dc_ena     => dc_ena,

        reset_disparity_pi => reset_disparity,
        force_toggle_pi    => force_toggle,
        force_prbs_pi      => force_prbs,
        force_flash_pi     => force_flash,
        data_pi            => data_in(idx),
        data_po            => data_enco(idx)
        );
  end generate gen_sub_encoding;

  gen_xcvr_data : for idx in 0 to NB_LANES-1 generate
    data_out((1+idx)*64-1 downto idx*64) <= data_enco(idx);
  end generate gen_xcvr_data;

end rtl;
