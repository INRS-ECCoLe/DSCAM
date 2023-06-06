-------------------------------------------------------------------------------
--
-- Title       : Encoder
-- Design      : SplitBucket
-- Author      : Shervin
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity Encoder is
   generic(												  		
		MAXTableWidth: integer:= 256;
		OutputWidth: integer:= 8
 	); 
   port( 
        clk, reset : in std_logic;	
		PEB_inputs : in std_logic_vector (MAXTableWidth-1 downto 0);
  		Addr_output : out std_logic_vector (OutputWidth-1 downto 0); 
 		valid : out std_logic          
   );
  
end Encoder;


architecture rtl of Encoder is
    
   signal Addr_output_temp: std_logic_vector (OutputWidth-1 downto 0);
   constant zeros :std_logic_vector (MAXTableWidth-1 downto 0):= (others=>'0');
   function one_hot_to_binary (One_Hot : std_logic_vector(MAXTableWidth-1 downto 0)) return std_logic_vector is
       variable Bin_Vec_Var : std_logic_vector(OutputWidth-1 downto 0); 
   begin
       Bin_Vec_Var := (others => '0');
       for I in 0 to MAXTableWidth-1 loop
         if One_Hot(I) = '1' then
           Bin_Vec_Var := Bin_Vec_Var or std_logic_vector(to_unsigned(I,OutputWidth));
         end if;
       end loop;
       return Bin_Vec_Var;
   end function;

begin

  process(clk)
	begin			
		if rising_edge(clk)then		
		   if reset='1' then				 
			   Addr_output_temp <=  (others => '0');
			   valid <= '0';
			else													  
			   --Addr_output_temp <= one_hot_to_binary(PEB_inputs);	
			   valid <= '0';
			   for I in 0 to MAXTableWidth-1 loop
                    if PEB_inputs(I) = '1' then
                       Addr_output_temp <= std_logic_vector(to_unsigned(I,OutputWidth));
                       valid <= '1';
                    end if;
               end loop;		
			   --if PEB_inputs=zeros then	
			   --   valid <= '0';
			   --else
			   --   valid <= '1';														  	
			   --end if;	
			end if;					 
		end if;	
	end process;
	
	--valid <= '0' when conv_integer(Addr_output_temp)=0 else '1';
	Addr_output <= Addr_output_temp;

end rtl;
