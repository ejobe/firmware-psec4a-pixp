---------------------------------------------------------------------------------
-- PROJECT:      psec4a-pixp
-- FILE:         definitions.vhd
-- AUTHOR:       e.oberla
-- EMAIL         eric.oberla@gmail.com
-- DATE:         2/2019
--					  	
--
-- DESCRIPTION:  TOP file for psec4a-pixp 32-channel x-ray photodiode board
---------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package definitions is

constant psec4a_instances  : integer := 4;
constant psec4a_data_width : integer := 11;

type psec4a_data_type is array(psec4a_instances-1 downto 0) of std_logic_vector(psec4a_data_width-1 downto 0);
type psec4a_select_type is array(psec4a_instances-1 downto 0) of std_logic_vector(2 downto 0);
type psec4a_control_type is array(psec4a_instances-1 downto 0) of std_logic_vector(3 downto 0);

end definitions;