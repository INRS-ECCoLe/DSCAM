-------------------------------------------------------------------------------
--
-- Title       : Memory
-- Design      : SplitBucket
-- Author      : 
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {Memory} architecture {Mem_beh}}

library ieee;			 
library std;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;	 

entity ConstMemory is  
	generic(												  
		LENGTH          : integer := 256;
		ADDRESS_WIDTH   : integer := 8;
		WIDTH           : integer := 3;
		CONTENT_FILE    : string := "../offset_table1_24.txt"
	);
	port (														
		clk 		: in  std_logic;  
		rst         : in  std_logic;         
		address_i 	: in  std_logic_vector (ADDRESS_WIDTH-1 downto 0); 
        valid_i 	: in  std_logic; 
		data_o    	: out std_logic_vector (WIDTH-1 downto 0)  
	);
end ConstMemory;

--}} End of automatically maintained section

architecture Mem_beh of ConstMemory is
	--signal reg_address :integer range 0 to Length - 1:=0;
	type RAM is array (0 to Length-1) of std_logic_vector( WIDTH-1 downto 0 ) ;
	--%%%%%%%%%%%%%%  read file   %%%%%%%%%%
 	impure function IP_Port return RAM is
		variable temp       : RAM;
 		variable inline     : line;
 		--variable dataread2: string(1 to WIDTH);	
 		--variable temp_hex : std_logic_vector (Hex_Width-1 downto 0);				
 		variable end_of_line: boolean;	 	 
		variable index      : integer range 0 to Length := 0;	
 		file myfile         : text;-- is in ContentFile;		  
 	begin
		file_open(myfile, CONTENT_FILE, READ_MODE);		
		while not endfile(myfile) and index < LENGTH loop   
			readline(myfile, inline);
			next when inline'length = 0; -- skip empty line
			read(inline, temp(index));
			index := index + 1;
		end loop;

 		return temp;
	end IP_Port;	
	
	signal mem      : RAM := IP_Port;
	
	begin 						
	process(clk)	      				
	begin			
		if rising_edge(clk) then
			if rst = '1' then
				data_o <= (others => '0');
            elsif valid_i = '1' then
			    data_o <= mem(conv_integer(address_i));
            end if;
		end if;
	end process;									   

end Mem_beh;
