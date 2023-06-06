library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;


package Definitions is 
	  	  
	
	
	--function init_table	(BucketNumber : string; TableWidth: integer) return IP_Mask_Table;
	--function Second_Decoder return DecoderValues;	
	--function ReadFromFileInteger(FileName : string) return BuckSize_Type;	
	
	--%%%%%%%%%%%%%%  Components   %%%%%%%%%%%%%%

	component DecoderBlock is 
		generic(Div : integer);
		port(
			IP_in_8 :in std_logic_vector (Div-1 downto 0);
			clk 	:in std_logic;
			reset	:in std_logic;
			Out_256 :out std_logic_vector (0 to (2**Div)-1)		
		);			   
	end component;	 
	
	
	component ComparatorBlock is		
		generic(												  
  			IPWidth :integer ;
  			MaskBit :integer ;	  
			TableWidth: integer;--Number of bits for size of the Table
			PortBit : natural; 		   
			Div : integer ; -- division to make groups of 8
			MAXTableWidth : integer ;--41044;
			RoutingTable : IP_Mask_Table
 		);
		port(
			MB_in 	: in Decoders_Outputs_Type;--std_logic_vector ((IPWidth/Div)*(2**Div)-1 downto 0);
			IP_in 	: in std_logic_vector (IPWidth-1 downto 0);		  
			clk 	: in std_logic;
			reset	: in std_logic;				  
			Match 	: out std_logic_vector (0 to MAXTableWidth-1)	
 		);	 
	end component; 
				   
	
	component NHI	
	   generic(												  
  			RoutingTableSize: integer;--Number of bits for size of the ROM
			PortBit : natural
 		);
	    port (													 
			clk 	:in  std_logic; 					
       		address :in   integer;--std_logic_vector (TableWidth-1 downto 0);
       		data    :out std_logic_vector (PortBit-1 downto 0)
   		);
	end component; 
	
	component ConstMemory is  
		 generic(												  
		   Length: integer:=1024;
		   AddrWidth: integer:=10;
		   Width: integer:=256;
		   ContentFile: string:="IPV4Table_Ports.txt"
 	    );
       port (														
         clk :in  std_logic;                    
         address :in  std_logic_vector (AddrWidth-1 downto 0); 
         data    :out std_logic_vector (Width-1 downto 0)  
       );
	end component; 
	
	component Encoder 
      generic(												  		
		   MAXTableWidth: integer;
		   OutputWidth: integer
 	   ); 
      port( 
         clk, reset : in std_logic;	
		   PEB_inputs : in 	std_logic_vector (MAXTableWidth-1 downto 0);
  		   Addr_output : out std_logic_vector (OutputWidth-1 downto 0); 
 		   valid : out std_logic          
      );
	end component;
	
	
	component  BitmapAddr is   
    		port (														                   
        		DecIPin1 	     : in std_logic_vector(Bitmap_Mem_Width-1 downto 0); 
        		bitmap_mem_out : in std_logic_vector(Bitmap_Mem_Width-1 downto 0);	
			 valid_in			    : in std_logic;
			 valid_out			   : out std_logic;
			 addr_out		     : out integer range 0 to Bitmap_Mem_Width - 1
    	);
   end component;
   
   
   component unary_AND IS
      generic (Width: positive := 8); --array size
       port (
           inp: in std_logic_vector(Width-1 downto 0);
           outp: out std_logic);		
   end component;		
   
   component Prefix_Processor is
	   generic(												  
  		   DirectIPinWidth :integer:= 16;    --excluding bitmap bits		  		 
		   Bucket_TableWidth : BuckSize_Type;
		   MAXTableWidth: integer;--41044;    --encoder input width 
		   EncoderOutWidth: integer;          --log2(MAXTableWidth)
		   NHI_Addr_width: integer;
		   Bitmap_length: integer;
		   Bitmap_Addr_Width: integer;            --Number of inputs of each AND gate in MS
		   EachMuxWidth: integer;
		   Prefix_FileName : string:= "abc"
 	   );
	   port(
		   DirectIP_in : in std_logic_vector (DirectIPinWidth-1 downto 0);
		   DecIPin : in Decoders_Outputs_Type;
		   DecBitmapin : in std_logic_vector (Bitmap_Mem_Width-1 downto 0); 
		   clk,reset : in std_logic;
		   valid_in : in std_logic;
  		   addr_out : out std_logic_vector (NHI_Addr_width-1 downto 0);		
 		   valid_out : out std_logic                
 	);															   
   end component;
   
   
					  
end package Definitions;


package body Definitions is	
	

end package body Definitions;