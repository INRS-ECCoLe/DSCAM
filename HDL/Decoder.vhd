library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
library std;
use std.textio.all;
entity Decoder is
	generic(OUTPUT_REGISTER_EN: boolean:= true;
			WIDTH : integer:= 9);
	port(
		data_i :in std_logic_vector (WIDTH-1 downto 0);
		clk :in std_logic;
		reset :in std_logic;
		data_o :out std_logic_vector ((2**WIDTH)-1 downto 0)		
 	);
end Decoder;			
architecture rt_level of Decoder is 
begin
	WITH_OUTPUT_REGISTER: if OUTPUT_REGISTER_EN = True generate	
		process(clk,reset)		  
		variable outVariable :std_logic_vector (2**WIDTH-1 downto 0);									  	 
		begin	 
			if reset = '1' then
				data_o <=  (others=> '0');	
			elsif rising_edge(clk) then	
				outVariable := (others=>'0');  
				outVariable(to_integer(unsigned(data_i))) := '1';
				data_o <= outVariable;
			end if;
		end process;
	end generate;

	WITHOUT_OUTPUT_REGISTER: if OUTPUT_REGISTER_EN = False generate	
		process(data_i)		  
		variable outVariable :std_logic_vector (2**WIDTH-1 downto 0);									  	 
		begin	 	
			outVariable := (others=>'0');  
			outVariable(to_integer(unsigned(data_i))) := '1';
			data_o <= outVariable;
		end process;
	end generate;
end rt_level;	