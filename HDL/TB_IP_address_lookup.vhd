---------------------------------------------------------------------------------------------------
--                __________
--    ______     /   ________      _          ______
--   |  ____|   /   /   ______    | |        |  ____|
--   | |       /   /   /      \   | |        | |
--   | |____  /   /   /        \  | |        | |____
--   |  ____| \   \   \        /  | |        |  ____|   
--   | |       \   \   \______/   | |        | |
--   | |____    \   \________     | |_____   | |____
--   |______|    \ _________      |_______|  |______|
--
--  ECCoLe: Edge Computing, Communication and Learning Lab - INRS University
--
--  Author: Shervin Vakili
--  Project: IP address lookup core 
--  Creation Date: 2023-03-10
--  Description: Testbench for IP address lookup module
------------------------------------------------------------------------------------------------

library ieee; 
library std;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all; 
use work.Parameters.all;
use work.Definitions.all;

entity TB_ip_address_lookup is
														   
end TB_ip_address_lookup;

-----------------------------------------------------------------------
architecture TB_ip_address_lookup_tb_beh of TB_ip_address_lookup is 

    constant clk_period : time := 10 ns;	   
	signal dataIn : std_logic_vector (31 downto 0);
	signal	clk,reset : std_logic;
	signal	validIn : std_logic;
  	signal	addrOut : std_logic_vector (FINAL_ADDR_WIDTH-1 downto 0);		
 	signal	validOut : std_logic;     
   
    begin
		IP_LOOKUP: ip_address_lookup
			port map(
				ipIn_i      => dataIn, 
				clk         => clk,
				rst         => reset,
				valid_i     => validIn,
				nhiAddr_o   => addrOut,		
				valid_o     => validOut                
			);		
                
		clk_process :process
		begin
			clk <= '0';
			wait for clk_period/2;  --for 0.5 ns signal is '0'.
			clk <= '1';
			wait for clk_period/2;  --for next 0.5 ns signal is '1'.
		end process;				
		reset <=  '1' , '0' after 4*clk_period ;
        validIn <= '1';	
        
	    dataIn <=   "11100000001000000010000000000000" , 
                    "11100000001000000010001000000000" after 7*clk_period, 
                    "01001010010101000100011000000000" after 8*clk_period, 
                    "11010101001110010111011111100000" after 9*clk_period,
					"11010000010111000101111000000000" after 10*clk_period,
                    "00000101101100100100000001000101" after 11*clk_period ;
        
	   
end TB_ip_address_lookup_tb_beh; 