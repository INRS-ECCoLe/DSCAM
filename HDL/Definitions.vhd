library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use work.Parameters.all;


package Definitions is 
	  	  
	constant PIPELINE_S1_EN         : integer := 1; -- 1: insert a pipeline stage before MUX
	constant PIPELINE_S2_EN         : integer := 1; -- 1: insert a pipeline stage after MUX
	
	--%%%%%%%%%%%%%%  Components   %%%%%%%%%%%%%%

	component Decoder is 
		generic(WIDTH : integer);
		port(
			data_i :in std_logic_vector (WIDTH-1 downto 0);
			clk :in std_logic;
			reset:in std_logic;
			data_o :out std_logic_vector ((2**WIDTH)-1 downto 0)		
		);	   
	end component;	 
	
	
--	component ComparatorBlock is		
--		generic(												  
--  			IPWidth :integer ;
--  			MaskBit :integer ;	  
--			TableWidth: integer;--Number of bits for size of the Table
--			PortBit : natural; 		   
--			Div : integer ; -- division to make groups of 8
--			MAXTableWidth : integer ;--41044;
--			RoutingTable : IP_Mask_Table
-- 		);
--		port(
--			MB_in 	: in Decoders_Outputs_Type;--std_logic_vector ((IPWidth/Div)*(2**Div)-1 downto 0);
--			IP_in 	: in std_logic_vector (IPWidth-1 downto 0);		  
--			clk 	: in std_logic;
--			reset	: in std_logic;				  
--			Match 	: out std_logic_vector (0 to MAXTableWidth-1)	
-- 		);	 
--	end component; 
				   
	
--	component NHI	
--	   generic(												  
--  			RoutingTableSize: integer;--Number of bits for size of the ROM
--			PortBit : natural
-- 		);
--	    port (													 
--			clk 	:in  std_logic; 					
--       		address :in   integer;--std_logic_vector (TableWidth-1 downto 0);
--       		data    :out std_logic_vector (PortBit-1 downto 0)
--   		);
--	end component; 
	
	component ConstMemory is  
		generic(												  
			LENGTH			: integer:=1024;
			ADDRESS_WIDTH	: integer:=10;
			WIDTH			: integer:=256;
			CONTENT_FILE	: string:="IPV4Table_Ports.txt"
		);
		port (														
			clk 		: in  std_logic;          
			rst         : in  std_logic;            
			address_i 	: in  std_logic_vector (ADDRESS_WIDTH-1 downto 0); 
        	valid_i 	: in  std_logic; 
			data_o    	: out std_logic_vector (WIDTH-1 downto 0) 
		);
	end component; 
	
	component Encoder 
		generic(												  		
			MAXTableWidth	: integer;
		   	OutputWidth		: integer
 		); 
    	port( 
         	clk, reset 		: in std_logic;	
		   	PEB_inputs 		: in std_logic_vector(MAXTableWidth-1 downto 0);
  		   	Addr_output 	: out std_logic_vector(OutputWidth-1 downto 0); 
 		   	valid 			: out std_logic          
    	);
	end component;
	
	component  BitmapAddress is 
		generic ( BITMAP_MEM_WIDTH : integer);  
    	port (														                   
			DecIPin1 	    : in std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0); 
			bitmap_mem_out 	: in std_logic_vector(BITMAP_MEM_WIDTH-1 downto 0);	
			valid_in		: in std_logic;
			clk 			: in std_logic;
			rst				: in std_logic;
			valid_out		: out std_logic;
			addr_out		: out integer range 0 to BITMAP_MEM_WIDTH - 1
   		);
	end component;
   
   
	component unary_AND IS
		generic (Width : positive := 8); --array size
		port (
			inp	: in std_logic_vector(Width-1 downto 0);
			outp: out std_logic);		
	end component;	
	
	component lookup_engine is
		generic(	
			MATCH_UNIT_IND_START    : integer := 0;											  
			MUX_BIT_INDEX_START 	: integer := 0;
			BITMAP_INDEX_START 		: integer := 0;
			LENGTH_IND 				: integer := 1
		);
		port(
			DataIn_i 	: in std_logic_vector (INPUT_WIDTH-1 downto 0); 
			clk 		: in std_logic;
			rst 		: in std_logic;
			valid_i 	: in std_logic;
			nhiAddr_o 	: out std_logic_vector (NHI_ADDR_WIDTH(LENGTH_IND)-1 downto 0);		
			valid_o 	: out std_logic                
		);															   
	end component;

	component ip_address_lookup is
		port(
			ipIn_i : in std_logic_vector (INPUT_WIDTH-1 downto 0);
			clk : in std_logic;
			rst : in std_logic;
			valid_i : in std_logic;
			nhiAddr_o : out std_logic_vector (FINAL_ADDR_WIDTH-1 downto 0);		
			valid_o : out std_logic                
		 );															   
	end component;
   	  
end package Definitions;


package body Definitions is	
	
end package body Definitions;