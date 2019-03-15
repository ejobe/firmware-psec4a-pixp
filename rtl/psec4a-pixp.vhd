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
	psec4a_vcdl_output_i	:	in		psec4a_instance_type;
	psec4a_read_clk_o		:	out	psec4a_instance_type;
	psec4a_d_i				:	in		psec4a_data_type;
	psec4a_xferadr_o		:	out	psec4a_control_type;
	psec4a_latchsel_o		:	out	psec4a_control_type;
	psec4a_ringosc_en_o	:	out	psec4a_instance_type;
	psec4a_ringosc_mon_i	:	in		psec4a_instance_type;
	psec4a_trigger_i		:	in		psec4a_instance_type; --//only wiring up TRIGOUT1 to FPGA (TRIGOUT1 can be cfg'd as an OR as
	psec4a_compsel_o		:	out	psec4a_select_type;
	psec4a_chansel_o		:	out	psec4a_select_type;
	psec4a_rampstart_o	:	out	psec4a_instance_type;
	psec4a_dllstart_o		:	out	psec4a_instance_type;
	psec4a_sclk_o			:	out	psec4a_instance_type; --//serial prog clock
	psec4a_sle_o			:	out	psec4a_instance_type; --//serial prog load enable 
	psec4a_sdat_o 			:  out	psec4a_instance_type; --//serial prog data
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

signal clk_25MHz_sig, clk_1MHz_sig, clk_75MHz_sig, clk_10Hz_sig, clk_1Hz_sig, clk_register : std_logic;
signal clk_psec4a_read : psec4a_instance_type;
signal global_reset_sig, reset_pwrup_sig : std_logic;

signal refresh_clk_1Hz, refresh_clk_10Hz : std_logic := '0';
signal refresh_clk_counter_1Hz, refresh_clk_counter_10Hz : std_logic_vector(19 downto 0);
signal REFRESH_CLK_MATCH_1HZ		: std_logic_vector(19 downto 0) := x"F4240"; --x"186A0";
signal REFRESH_CLK_MATCH_10HZ		: std_logic_vector(19 downto 0) := x"186A0"; --x"02710";

signal register_array 	:	register_array_type;

signal psec4a_chan_sel 	: psec4a_select_type;

signal data_fifo_data : std_logic_vector(data_word_size-1 downto 0);
signal data_ram_rd_addr : std_logic_vector(10 downto 0);
signal data_ram_wr_addr : std_logic_vector(10 downto 0);

begin
--//////---------------------------------------
xCLK_GEN_10Hz : entity work.Slow_Clocks
generic map(clk_divide_by => 50000)
port map(clk_1MkHz_sig, global_reset_sig, clk_10Hz_sig);
--//////---------------------------------------	
xCLK_GEN_1Hz : entity work.Slow_Clocks
generic map(clk_divide_by => 500000)
port map(clk_1MHz_sig, global_reset_sig, clk_1Hz_sig);

--//////---------------------------------------
xRESET : entity work.reset
port map(
	clk_i	=> clk_25MHz_sig, reg_i=>register_array, 
	power_on_rst_o => reset_pwrup_sig, reset_o => global_reset_sig);
	
--//////---------------------------------------
xPLL0 : entity work.pll0
port map(
	areset => '0', inclk0 => clk_i(0),
	c0	=> clk_25MHz_sig, c1	=> clk_1MHz_sig, c2 => clk_75MHz_sig, locked	=> open);

clk_register <= clk_25MHz_sig;
psec4a_read_clk_o(0) <= clk_psec4a_read(0);
psec4a_read_clk_o(1) <= clk_psec4a_read(1);
psec4a_read_clk_o(2) <= clk_psec4a_read(2);
psec4a_read_clk_o(3) <= clk_psec4a_read(3);

--//////---------------------------------------
proc_make_refresh_pulse : process(clk_1MHz_sig)
begin
	if rising_edge(clk_1MHz_sig) then			
		if refresh_clk_1Hz = '1' then
			refresh_clk_counter_1Hz <= (others=>'0');
		else
			refresh_clk_counter_1Hz <= refresh_clk_counter_1Hz + 1;
		end if;
		--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
		case refresh_clk_counter_1Hz is
			when REFRESH_CLK_MATCH_1HZ =>
				refresh_clk_1Hz <= '1';
			when others =>
				refresh_clk_1Hz <= '0';
		end case;
		
		if refresh_clk_10Hz = '1' then
			refresh_clk_counter_10Hz <= (others=>'0');
		else
			refresh_clk_counter_10Hz <= refresh_clk_counter_10Hz + 1;
		end if;
		--//pulse refresh when refresh_clk_counter = REFRESH_CLK_MATCH
		case refresh_clk_counter_10Hz is
			when REFRESH_CLK_MATCH_10HZ =>
				refresh_clk_10Hz <= '1';
			when others =>
				refresh_clk_10Hz <= '0';
		end case;
	end if;
end process;
	
--//////---------------------------------------
psec4a_core_control : for i in 0 to psec4a_instances-1 generate
	xPSEC4A_CNTRL : entity work.psec4a_core 	
	port map(
		rst_i				=> global_reset_sig,
		clk_i				=> clk_25MHz_sig,
		clk_reg_i		=> clk_reg,
		clk_mezz_i		=> clk_75MHz_sig,
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
		rdout_clk_o		=> clk_psec4a_read(i),
		rdout_valid_o  => psec4a_readout_valid(i),
		rdout_ram_wr_addr_o => data_ram_wr_addr(i),
		chan_sel_o		=> psec4a_chan_sel(i));
end generate;

--//////---------------------------------------
psec4a_data_mgmt : for i in 0 to psec4a_instances-1 generate
	xPSEC4A_DATA : entity work.psec4a_data_ram
	port map(	
		rst_i				=> global_reset_sig,	
		wrclk_i			=> clk_psec4a_read,
		registers_i		=> register_array,
		psec4a_dat_i	=> psec4a_d_i(i),
		psec4a_ch_sel_i=> psec4a_chan_sel(i),
		data_valid_i	=> psec4a_readout_valid,
		ram_clk_i		=> 
		ram_rd_addr_i	=> data_ram_rd_addr,
		ram_wr_addr_i	=> data_ram_wr_addr,
		ram_rd_data_o	=> data_fifo_data);

--//////---------------------------------------
psec4a_serial_mgmt : for i in 0 to psec4a_instances-1 generate
	xPSEC4A_SERIAL : entity work.psec4a_serial
	port map(		
		clk_i				=> clk_1MHz_sig,
		rst_i				=> global_reset_sig,
		registers_i		=> register_array,
		write_i			=> refresh_clk_1Hz,
		psec4a_ro_bit_i => psec4a_ringosc_mon_i(i), --//ring oscillator divider bit
		psec4a_ro_count_lo_o => readout_register_array(0),
		psec4a_ro_count_hi_o => readout_register_array(1),
		serial_clk_o	=> psec4a_sclk_o(i),
		serial_le_o		=> psec4a_sle_o(i),
		serial_dat_o	=> psec4a_sdat_o(i));
		
--//////---------------------------------------		
xREGISTERS : entity work.registers
port map(
		rst_powerup_i	=> reset_pwrup_sig,	
		rst_i				=> global_reset_sig,
		clk_i				=> clk_register, 
		write_reg_i		=> usb_instr_sig,
		write_rdy_i		=> usb_instr_rdy_sig,
		read_reg_o 		=> readout_reg_sig,
		registers_io	=> register_array,
		readout_register_i => readout_register_array,
		address_o		=> reg_addr_sig);

--//////---------------------------------------		
xRDOUT_CNTRL : entity work.rdout_controller 
	port map(
		rst_i					=> global_reset_sig,	
		clk_i					=> clk_register	
		rdout_reg_i			=> readout_reg_sig,	
		reg_adr_i			=> reg_addr_sig,	
		registers_i			=> register_array,	   
		usb_slwr_i			=> usb_slwr_sig,
		tx_rdy_o				=> usb_start_wr_sig,	
		tx_ack_i				=> usb_done_sig,
		data_rd_addr_o		=> data_ram_rd_addr,
		data_fifo_i			=> data_fifo_data,
		rdout_length_o		=> usb_readout_length,
		rdout_fpga_data_o	=> usb_dataout_sig);	

--//////---------------------------------------
xLTC2600 : entity work.DAC_MAIN_LTC2600
port map(
	xCLKDAC			=> clk_1MHz_sig,
	xCLK_REFRESH	=> refresh_clk_1Hz,
	xCLR_ALL			=> global_reset_sig,
	registers_i		=> register_array,
	SDATOUT1			=> dac_cntrl_io(2),
	SDATOUT2			=> open,
	DACCLK1			=> dac_cntrl_io(0),
	DACCLK2			=> open,
	LOAD1				=> dac_cntrl_io(4),
	LOAD2				=> open,
	CLR_BAR1			=> dac_cntrl_io(3),
	CLR_BAR2			=> open,
	SDATIN1			=> dac_cntrl_io(1),
	SDATIN2			=> '0');
end rtl;
	