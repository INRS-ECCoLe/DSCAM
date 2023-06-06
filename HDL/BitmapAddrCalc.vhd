-------------------------------------------------------------------------------
--
-- Title       : Address Calculation Based on Bitmapped Word
-- Design      : BitmapAddr
-- Author      : Shervin
-- Company     : Polytechnique Montreal
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------


library ieee;			 
library std;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;	 
--use work.Parameters.all;

-------------------------------------------------------------------------------
entity BitmapAddress is  
	generic (BITMAP_MEM_WIDTH  : integer := 8);
	port (														                   
		DecIPin1 	     	: in std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0); 
		bitmap_mem_out 		: in std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0);	
		valid_in			: in std_logic;
		clk 				: in std_logic;
		rst					: in std_logic;
		valid_out			: out std_logic;
		addr_out			: out integer range 0 to BITMAP_MEM_WIDTH - 1
	);
end BitmapAddress;

-------------------------------------------------------------------------------
architecture BitmapAddr_beh of BitmapAddress is
    signal first_and		: std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0);
    signal zeros			: std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0);
    signal second_and		: std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0);
    signal mask_n			: std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0);
    signal mask				: std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0);
	signal addr_out_temp	: integer range 0 to Bitmap_Mem_Width - 1;

begin
    zeros <= (others => '0');
    first_and <= DecIPin1 and bitmap_mem_out;
    
    mask_n(0) <= first_and(0);
    F1:for i in 1 to Bitmap_Mem_Width-1 generate
       mask_n(i) <= mask_n(i-1) or first_and(i);
    end generate;
    
	-- if mask_n(BITMAP_MEM_WIDTH) = 0, there has been no match between DecIPin1 and bitmap_mem_out
    mask <= not mask_n;
    second_and <= (mask and bitmap_mem_out) when mask_n(BITMAP_MEM_WIDTH-1) = '1' else (others => '0');
    
    process(second_and)
		variable addr_out_v	: integer range 0 to Bitmap_Mem_Width - 1;
		begin
	   		addr_out_v:= 0;
			for k in Bitmap_Mem_Width-1 downto 0 loop --supposing that there is no zero bit mask	
				if second_and(k) = '1' then															  
					addr_out_v := addr_out_v+1;				
				end if;			
			end loop;	
			addr_out_temp <= addr_out_v;		 		
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				addr_out <= 0;
				valid_out <= '0';
			else 
				addr_out <= addr_out_temp;
				if first_and /= zeros and valid_in = '1' then
					valid_out <= '1'; 
				else 
					valid_out <= '0';
				end if;
			end if;
		end if;
	end process;
	
end BitmapAddr_beh;