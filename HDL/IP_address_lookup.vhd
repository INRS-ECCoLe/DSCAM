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
--  Description: Top-level module performing longest prefix match for IP address lookup
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

entity ip_address_lookup is
	port(
		ipIn_i : in std_logic_vector (INPUT_WIDTH-1 downto 0);
		clk : in std_logic;
        rst : in std_logic;
		valid_i : in std_logic;
  		nhiAddr_o : out std_logic_vector (FINAL_ADDR_WIDTH-1 downto 0);		
 		valid_o : out std_logic                
 	);															   
end ip_address_lookup;

-----------------------------------------------------------------------
architecture ip_lookup_arch of ip_address_lookup is 
    type nhiAddrVec_type is array (1 to NO_PREFIX_LENGTHS) of std_logic_vector(FINAL_ADDR_WIDTH-1 downto 0);
    signal nhiAddrVec : nhiAddrVec_type := (others => (others => '0'));
    signal validVec : std_logic_vector(NO_PREFIX_LENGTHS downto 1);
begin

    ----------------  Instantiate a lookup engine for each prefix  -----
	GENERATE_LOOKUP_ENGINE : for ind in 1 to NO_PREFIX_LENGTHS generate  -- extract the bits that will be matched in the MU
        LU_ENGINE: lookup_engine 
            generic map(
                MATCH_UNIT_IND_START    => MU_IND_START(ind),												  
                MUX_BIT_INDEX_START     => MUX_IND_START(ind),
                BITMAP_INDEX_START      => BITMAP_IND_START(ind),
                LENGTH_IND              => ind
            )
            port map(
                dataIn_i    => ipIn_i,
                clk         => clk,
                rst         => rst,
                valid_i     => valid_i,
                nhiAddr_o   => nhiAddrVec(ind)(NHI_ADDR_WIDTH(ind)-1 downto 0),	
                valid_o     => validVec(ind)              
            );															   
    end generate GENERATE_LOOKUP_ENGINE;

    ----------------  Output buffer  -----------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then -- local synchronous reset
                nhiAddr_o          <= (others => '0');
                valid_o            <= '0';
            else
                valid_o    <= '0';
                for prefix_length in 1 to NO_PREFIX_LENGTHS loop
                    if validVec(prefix_length) = '1' then
                        nhiAddr_o  <= nhiAddrVec(prefix_length) + conv_std_logic_vector(NO_PREFIXES(prefix_length), FINAL_ADDR_WIDTH);
                        valid_o    <= '1';
                    end if;
                end loop;
            end if;
        end if;
    end process;

end ip_lookup_arch;
