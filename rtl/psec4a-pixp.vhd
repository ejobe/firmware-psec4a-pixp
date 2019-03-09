---------------------------------------------------------------------------------
-- PROJECT:      psec4a-pixp
-- FILE:         psec4a-pixp.vhd
-- AUTHOR:       e.oberla
-- EMAIL         eric.oberla@gmail.com
-- DATE:         2/2019
--					  	
--
-- DESCRIPTION:  TOP file for psec4a-pixp 32-channel x-ray photodiode board
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.definitions.all;
--
entity psec4a_pixp is
port(
	--//psec4a data/control signals:
	psec4a_vcdl_output_i	:	in		std_logic_vector(psec4a_instances-1 downto 0);
	psec4a_read_clk_o		:	out	std_logic_vector(psec4a_instances-1 downto 0);
	psec4a_d_i				:	in		psec4a_data_type;
	psec4a_xferadr_o		:	out	psec4a_control_type;
	psec4a_latchsel_o		:	out	psec4a_control_type;
	psec4a_ringosc_en_o	:	out	std_logic_vector(psec4a_instances-1 downto 0);
	psec4a_ringosc_mon_i	:	in		std_logic_vector(psec4a_instances-1 downto 0);
	psec4a_trigger_i		:	in		std_logic_vector(psec4a_instances-1 downto 0); 
	psec4a_compsel_o		:	out	psec4a_select_type;
	psec4a_chansel_o		:	out	psec4a_select_type;
	psec4a_rampstart_o	:	out	std_logic_vector(psec4a_instances-1 downto 0);
	psec4a_dllstart_o		:	out	std_logic_vector(psec4a_instances-1 downto 0);
	psec4a_sclk_o			:	out	std_logic_vector(psec4a_instances-1 downto 0); --//serial prog clock
	psec4a_sle_o			:	out	std_logic_vector(psec4a_instances-1 downto 0); --//serial prog load enable 
	psec4a_sdat_o 			:  out	std_logic_vector(psec4a_instances-1 downto 0); --//serial prog data
	--//ftdi chip / PC readout:
	ftdi_abus_io			: 	inout std_logic_vector(15 downto 0);  --//3.3V i/o
	--//pll control signals
	pll_cntrl_io			:  inout std_logic_vector(4 downto 0);   --//3.3V i/o
	--//dac control signals:
	dac_cntrl_io			:	inout std_logic_vector(4 downto 0);   --//3.3V i/o
	--clk_in
	clk_i						:	in		std_logic_vector(2 downto 0); --//two clocks pre-pll, one clock from pll
	--//external trigger input
	ext_trig_i				: 	in		std_logic;
	--//external trigger output
	ext_trig_o				: 	out	std_logic;
	--//fast serial, for future use:
	serial_data_o			:	out	std_logic_vector(1 downto 0);
	serial_data_i			:	in		std_logic_vector(1 downto 0);
	--//gpio stuff:
	led_o						:	out	std_logic_vector(2 downto 0);
	gpio_io					:	inout std_logic_vector(11 downto 0));
end psec4a_pixp;
--
architecture rtl of psec4a_pixp is
begin

psec4a_core_control : for i in 0 to psec4a_instances-1 generate
	xPSEC4A_CNTRL : entity work.psec4a_core 	
	port map(
		rst_i				=> global_reset_sig,
		clk_i				=> clk_25MHz_sig,
		clk_reg_i		=> clk_reg,
		clk_mezz_i		=> clk_mezz_internal,
		registers_i		=> register_array,
		psec4a_stat_o	=> open,
		trigbits_i		=> open,
		trig_for_scaler_o => open,
		dll_start_o		=> psec4a_dllstart_o(i),
		xfer_adr_o		=> psec4a_xferadr_o(i),
		ramp_o			=> psec4a_rampstart_o(i),
		ring_osc_en_o	=> psec4a_ringosc_en_o(i),
		comp_sel_o		=> psec4a_compsel_o(i),
		latch_sel_o		=> psec4a_latchsel_o(i), 
		rdout_clk_o		=> psec4a_read_clk(i),
		rdout_valid_o  => psec4a_readout_valid(i),
		rdout_ram_wr_addr_o => data_ram_wr_addr(i),
		chan_sel_o		=> psec4a_chan_sel(i));
end generate;

end rtl;
	