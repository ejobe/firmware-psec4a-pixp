---------------------------------------------------------------------------------
-- PROJECT:      psec4a-pixp
-- FILE:         definitions.vhd
-- AUTHOR:       e.oberla
-- EMAIL         eric.oberla@gmail.com
-- DATE:         2/2019
--					  	
--
-- DESCRIPTION:  global definitions
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package definitions is

constant define_register_size : 	integer := 32;
constant define_address_size	:	integer := 8;

constant firmware_version 	: std_logic_vector(define_register_size-define_address_size-1 downto 0) := x"000002";
constant firmware_date 		: std_logic_vector(define_register_size-define_address_size-1 downto 0) := x"000" & x"7" & x"05";
constant firmware_year 		: std_logic_vector(define_register_size-define_address_size-1 downto 0) := x"000" & x"7e2";

constant psec4a_instances  : integer := 4;
constant psec4a_num_channels : integer := 8;
constant psec4a_num_dacs : integer := 18;
constant psec4a_dac_bits : integer := 10;
constant psec4a_data_width : integer := 11;
constant data_word_size : integer := 16; --//

type psec4a_dac_array_type is array (psec4a_instances-1 downto 0, psec4a_num_dacs-1 downto 0) of std_logic_vector(psec4a_dac_bits-1 downto 0);
type psec4a_data_type is array(psec4a_instances-1 downto 0) of std_logic_vector(psec4a_data_width-1 downto 0);
type psec4a_select_type is array(psec4a_instances-1 downto 0) of std_logic_vector(2 downto 0);
type psec4a_control_type is array(psec4a_instances-1 downto 0) of std_logic_vector(3 downto 0);
type psec4a_instance_type is std_logic_vector(psec4a_instances-1 downto 0);

type register_array_type is array (127 downto 0) of std_logic_vector(define_register_size-define_address_size-1 downto 0);
type read_register_array_type is array (31 downto 0) of std_logic_vector(15 downto 0);

end definitions;