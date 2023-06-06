library ieee; 
library std;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;
use std.textio.all;	 
use work.Definitions.all;
use work.Parameters.all;

entity TB_lookup_engine is												   
end TB_lookup_engine;


architecture TB_lookup_engine_arch of TB_lookup_engine is 	
 	
 	constant clk_period : time := 10 ns;	   
	signal dataIn : std_logic_vector (31 downto 0);
	signal	clk,reset : std_logic;
	signal	validIn : std_logic;
  	signal	addrOut : std_logic_vector (0 downto 0);		
 	signal	validOut : std_logic;     
   
    begin
		LOOKUP_ENG: lookup_engine
			generic map(												  
				MUX_BIT_INDEX_START 	=> 0,
				BITMAP_INDEX_START 		=> 0,
				LENGTH_IND 				=> 1
			)
			port map(
				DataIn_i    => dataIn, 
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
                    "11100010000000000010000000000000" after 8*clk_period, 
                    "11100001101000001000111100000000" after 9*clk_period,
                    "11100010000000001010111100000000" after 10*clk_period ;
        
 	     
end TB_lookup_engine_arch; 

