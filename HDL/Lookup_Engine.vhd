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
--  Edge Computing, Communication and Learning Lab (ECCoLE) - INRS University
--
--  Author: Shervin Vakili
--  Project: IP address lookup core 
--  Creation Date: 2023-03-10
--  Description: lookup engine performs look up for a fixed prefix length.
--               Paremeters are defined in Parameters.vhd package.
------------------------------------------------------------------------------------------------

library ieee; 
library std;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;
use std.textio.all;	 
use work.Parameters.all;
use work.Definitions.all;

-----------------------------------------------------------------------
entity lookup_engine is
	generic(												  
        MATCH_UNIT_IND_START    : integer := 0;
        MUX_BIT_INDEX_START     : integer := 0;
        BITMAP_INDEX_START      : integer := 0;
        LENGTH_IND              : integer := 1
 	);
	port(
		dataIn_i    : in std_logic_vector (INPUT_WIDTH-1 downto 0);
		clk         : in std_logic;
        rst         : in std_logic;
		valid_i     : in std_logic;
  		nhiAddr_o   : out std_logic_vector (NHI_ADDR_WIDTH(LENGTH_IND)-1 downto 0);		
 		valid_o     : out std_logic                
 	);															   
end lookup_engine;

-----------------------------------------------------------------------
architecture lookup_engine_arch of lookup_engine is 		

    --constant ENCODER_OUT_WIDTH  : integer:= log2(MAX_MUX_IN_WIDTH);
    type muxInSize_type is array (0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1) of std_logic_vector(LOG2_MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
    signal valid_b1             : std_logic;
    -- Match Unit
    constant MU_DEC_IN_WIDTH: integer:= 5;
    --constant NO_MU_DEC          : integer:= 4;
    
    type MU_DEC_OUT_TYPE is array (1 to NUM_MU_DECODERS(LENGTH_IND)) of std_logic_vector(2**MU_DEC_IN_WIDTH-1 downto 0);
    signal muDecOut: MU_DEC_OUT_TYPE;

    type muDecMatchVec_type is array (0 to MAX_MUX_IN_WIDTH(LENGTH_IND)-1) of std_logic_vector(NUM_MU_DECODERS(LENGTH_IND)-1 downto 0);
    type muDecMatch_type is array (0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1) of muDecMatchVec_type;
    signal muDecMatch: muDecMatch_type;
    constant allOne: std_logic_vector(NUM_MU_DECODERS(LENGTH_IND)-1 downto 0) := (others => '1');

    
    signal MatchUnitInputBits   : std_logic_vector (MATCH_UNIT_BITWIDTH(LENGTH_IND)-1 downto 0);  -- input bits that are matched in the match unit
    type matchData_type is array (0 to MAX_MUX_IN_WIDTH(LENGTH_IND)-1) of std_logic_vector(MATCH_UNIT_BITWIDTH(LENGTH_IND)-1 downto 0); 
    type matchArray_type is array (0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1) of matchData_type;
    signal matchArray           : matchArray_type;
    -- MUX
    type muxIn_type is array (0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1) of std_logic_vector(MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxInPre             : muxIn_type := (others => (others => '0'));
    signal muxIn_b1             : muxIn_type := (others => (others => '0'));
    signal muxIn                : muxIn_type;
    signal muxInValid           : std_logic;
	signal muxOut		        : std_logic_vector(MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxOut_b1            : std_logic_vector(MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxOut_pre           : std_logic_vector(MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxOut_pre0          : std_logic_vector(MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
	signal muxSelInputBits	    : std_logic_vector(MUX_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxSelInputBits_b1   : std_logic_vector(MUX_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxSelInputBits_b2   : std_logic_vector(MUX_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxSelInputBits_b3   : std_logic_vector(MUX_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal muxSelInputBits_buf   : std_logic_vector(MUX_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    -- Encoder
    signal encoderValidOut      : std_logic;
    signal encoderValidOut_b1   : std_logic;
    signal encoderValidOut_b2   : std_logic;
    signal encoderOut           : std_logic_vector(LOG2_MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
    -- Bitmap
    constant BITMAP_MEM_WIDTH   : integer := 2**BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND);	
    constant BITMAP_ADDR_WIDTH  : integer := PREFIX_BITWIDTH(LENGTH_IND) - MUX_ADDR_WIDTH(LENGTH_IND) - MATCH_UNIT_BITWIDTH(LENGTH_IND); -- Number of bits matched by the bitmap mechanism
    signal bitmapAddrOffset     : std_logic_vector (BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal bitmapAddr           : std_logic_vector (BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal bitmapAddr_b1        : std_logic_vector (BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal bitmapMemOut         : std_logic_vector(2**BITMAP_ADDR_WIDTH-1 downto 0);
    signal bitmapMemOut_b1      : std_logic_vector(2**BITMAP_ADDR_WIDTH-1 downto 0);
    signal bitmapMatch          : std_logic;
    signal relativeAddr         : integer range 0 to 2**BITMAP_ADDR_WIDTH - 1;
    signal bitmapSelInputBits   : std_logic_vector(BITMAP_ADDR_WIDTH-1 downto 0);
    signal bitmapSelInputBits_b1: std_logic_vector(BITMAP_ADDR_WIDTH-1 downto 0);
    signal bitmapSelInputBits_b2: std_logic_vector(BITMAP_ADDR_WIDTH-1 downto 0);
    signal bitmapSelInputBits_b3: std_logic_vector(BITMAP_ADDR_WIDTH-1 downto 0);
    signal bitmapSelInputBits_b4: std_logic_vector(BITMAP_ADDR_WIDTH-1 downto 0);
    signal bitmapSelInputBits_buf: std_logic_vector(BITMAP_ADDR_WIDTH-1 downto 0);
    signal decBitmapIn          : std_logic_vector (2**BITMAP_ADDR_WIDTH-1 downto 0);
    -- NHI address
    signal nhiAddrOffset        : std_logic_vector(NHI_ADDR_WIDTH(LENGTH_IND)-1 downto 0);
    signal nhiAddr              : std_logic_vector(NHI_ADDR_WIDTH(LENGTH_IND)-1 downto 0);	 
	
	----------------  Initialize lookup table ---------------------------
	

    impure function init_mux_in_size_array (fileName : string) return muxInSize_type is 			 
        variable inline         : line;
        variable element        : std_logic_vector(LOG2_MAX_MUX_IN_WIDTH(LENGTH_IND)-1 downto 0);
        variable muxInCnt       : integer range 0 to 2 ** MUX_ADDR_WIDTH(LENGTH_IND) := 0;
        variable matchLimitInd  : integer range 0 to  TOTAL_MUX_INPUTS-1 := MUX_IN_SIZE_START_IND(LENGTH_IND);
        variable muxInSizeArray : muxInSize_type ;
        file inFile          : text; 		 		  
	begin
        file_open(inFile,fileName,READ_MODE);
        while not endfile(inFile) and (muxInCnt < 2 ** MUX_ADDR_WIDTH(LENGTH_IND)) loop   
            readline(inFile, inline);
            next when inline'length = 0; -- skip empty line
            read(inline, element);
            muxInSizeArray(muxInCnt) := element;
            muxInCnt := muxInCnt + 1;
        end loop;
        file_close(inFile);
        return muxInSizeArray;
	end function;		
    CONSTANT MUX_IN_SIZE_ARRAY : muxInSize_type := init_mux_in_size_array(MUX_IN_SIZE_CONTENT_FILE(LENGTH_IND));

    impure function init_match_unit_data (fileName : string) return matchArray_type is 			 
        variable inline         : line;
        --variable dataread2      : std_logic_vector(Hex_Width-1 downto 0); 				
        --variable char : character:='0';  
        variable matchCnt       : integer range 0 to MAX_MUX_IN_WIDTH(LENGTH_IND) := 0;	
        variable muxInCnt       : integer range 0 to 2**MUX_ADDR_WIDTH(LENGTH_IND) := 0;
        variable matchLimitInd  : integer range 0 to  TOTAL_MUX_INPUTS-1 := MUX_IN_SIZE_START_IND(LENGTH_IND);
        variable matchArray_v   : matchArray_type ;
        file matchFile          : text; 		 		  
	begin
        file_open(matchFile,fileName,READ_MODE);
        while not endfile(matchFile) loop             
            --if matchCnt >=  MUX_IN_SIZE(matchLimitInd) then
            if matchCnt >=  MUX_IN_SIZE_ARRAY(muxInCnt) then
                muxInCnt := muxInCnt + 1;
                --matchLimitInd := matchLimitInd + 1;
                matchCnt := 0;
            else 
                readline(matchFile, inline);
                next when inline'length = 0; -- skip empty line
                read(inline, matchArray_v(muxInCnt)(matchCnt));
                matchCnt := matchCnt + 1;
            end if; 
        end loop;
        file_close(matchFile);
        return matchArray_v;
	end function;		

begin

    ----------------  Input bit partitionings  ---------------------------
	GENERATE_MU_BITS : for ind in 0 to MATCH_UNIT_BITWIDTH(LENGTH_IND)-1 generate  -- extract the bits that will be matched in the MU
        MatchUnitInputBits(MATCH_UNIT_BITWIDTH(LENGTH_IND)-1-ind) <= dataIn_i(MATCH_UNIT_INDEX(MATCH_UNIT_IND_START + ind + 1));
    end generate GENERATE_MU_BITS;

    GENERATE_MUX_SEL_BITS : for ind in 0 to MUX_ADDR_WIDTH(LENGTH_IND)-1 generate  -- extract the bits that will be matched by the mux address
        muxSelInputBits(MUX_ADDR_WIDTH(LENGTH_IND)-1-ind) <= dataIn_i(MUX_BIT_INDEX(MUX_BIT_INDEX_START + ind + 1));
    end generate GENERATE_MUX_SEL_BITS;
    
    BITMAP_BITS: if BITMAP_ADDR_WIDTH > 0 generate
    GENERATE_BITMAP_BITS : for ind in 0 to BITMAP_ADDR_WIDTH-1 generate  -- extract the bits that will be matched by the bitmap section
        bitmapSelInputBits(BITMAP_ADDR_WIDTH-ind-1) <= dataIn_i(BITMAP_BIT_INDEX(BITMAP_INDEX_START + ind + 1));
    end generate GENERATE_BITMAP_BITS;
    end generate BITMAP_BITS;

    matchArray  <= init_match_unit_data(MATCH_UNIT_BITS_FILE(LENGTH_IND));


    ----------------  Match Unit-----------------------------------------
    -- DSCAM+
    MU_DECODER: if NUM_MU_DECODERS(LENGTH_IND) > 0 generate
        GENERATE_DECODER : for mu_dec_ind in 1 to NUM_MU_DECODERS(LENGTH_IND) generate
            MU_DE: Decoder 
                generic map(OUTPUT_REGISTER_EN => False,
                            WIDTH => MU_DEC_IN_WIDTH)
                port map(
                    data_i  => MatchUnitInputBits(mu_dec_ind*MU_DEC_IN_WIDTH-1 downto (mu_dec_ind-1)*MU_DEC_IN_WIDTH),
                    clk     => clk,
                    reset   => rst,
                    data_o  => muDecOut(mu_dec_ind)		
                 );
        end generate GENERATE_DECODER;
    end generate MU_DECODER;

    -- MU-assigned input bits are partially decoded
    WITH_MU_DECODER: if NUM_MU_DECODERS(LENGTH_IND) > 0 and MATCH_UNIT_BITWIDTH(LENGTH_IND) > MU_DEC_IN_WIDTH*NUM_MU_DECODERS(LENGTH_IND) generate   
        GENERATE_MATCH : for mux_in_ind in 0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1 generate
            GENERATE_MATCH_L2 : for mux_in_cnt in 0 to conv_integer(MUX_IN_SIZE_ARRAY(mux_in_ind))-1 generate                        
                muxInPre(mux_in_ind)(mux_in_cnt) <= '1' when MatchUnitInputBits(MATCH_UNIT_BITWIDTH(LENGTH_IND)-1 downto NUM_MU_DECODERS(LENGTH_IND)*MU_DEC_IN_WIDTH) = matchArray(mux_in_ind)(mux_in_cnt)(MATCH_UNIT_BITWIDTH(LENGTH_IND)-1 downto NUM_MU_DECODERS(LENGTH_IND)*MU_DEC_IN_WIDTH) and (muDecMatch(mux_in_ind)(mux_in_cnt)=allOne)
                                                    else '0';
                DECODER_OUTs : for mu_dec_ind in 1 to NUM_MU_DECODERS(LENGTH_IND) generate
                    muDecMatch(mux_in_ind)(mux_in_cnt)(mu_dec_ind-1) <= muDecOut(mu_dec_ind)(conv_integer(matchArray(mux_in_ind)(mux_in_cnt)(mu_dec_ind*MU_DEC_IN_WIDTH-1 downto (mu_dec_ind-1)*MU_DEC_IN_WIDTH)));  -- matches through MU decoders
                end generate DECODER_OUTs;
                --muxInPre(mux_in_ind)(mux_in_cnt) <= '1' when MatchUnitInputBits = matchArray(mux_in_ind)(mux_in_cnt) else '0';
            end generate GENERATE_MATCH_L2;
        end generate GENERATE_MATCH;
    end generate WITH_MU_DECODER;

    -- All MU-assigned input bits are decoded
    WITH_ONLY_MU_DECODER: if NUM_MU_DECODERS(LENGTH_IND) > 0 and MATCH_UNIT_BITWIDTH(LENGTH_IND) <= MU_DEC_IN_WIDTH*NUM_MU_DECODERS(LENGTH_IND) generate
        GENERATE_MATCH : for mux_in_ind in 0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1 generate
            GENERATE_MATCH_L2 : for mux_in_cnt in 0 to conv_integer(MUX_IN_SIZE_ARRAY(mux_in_ind))-1 generate                        
                muxInPre(mux_in_ind)(mux_in_cnt) <= '1' when muDecMatch(mux_in_ind)(mux_in_cnt)=allOne  else '0';
                DECODER_OUTs : for mu_dec_ind in 1 to NUM_MU_DECODERS(LENGTH_IND) generate
                    muDecMatch(mux_in_ind)(mux_in_cnt)(mu_dec_ind-1) <= muDecOut(mu_dec_ind)(conv_integer(matchArray(mux_in_ind)(mux_in_cnt)(mu_dec_ind*MU_DEC_IN_WIDTH-1 downto (mu_dec_ind-1)*MU_DEC_IN_WIDTH)));  -- matches through MU decoders
                end generate DECODER_OUTs;
                --muxInPre(mux_in_ind)(mux_in_cnt) <= '1' when MatchUnitInputBits = matchArray(mux_in_ind)(mux_in_cnt) else '0';
            end generate GENERATE_MATCH_L2;
        end generate GENERATE_MATCH;
    end generate WITH_ONLY_MU_DECODER;
    
    -- No decoder
    WITHOUT_MU_DECODER: if NUM_MU_DECODERS(LENGTH_IND) = 0 generate
        GENERATE_MATCH : for mux_in_ind in 0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1 generate
            GENERATE_MATCH_L2 : for mux_in_cnt in 0 to conv_integer(MUX_IN_SIZE_ARRAY(mux_in_ind))-1 generate                        
                muxInPre(mux_in_ind)(mux_in_cnt) <= '1' when MatchUnitInputBits = matchArray(mux_in_ind)(mux_in_cnt) else '0';
            end generate GENERATE_MATCH_L2;
        end generate GENERATE_MATCH;
    end generate WITHOUT_MU_DECODER;


    -- DSCAM
--    GENERATE_MATCH : for mux_in_ind in 0 to 2**MUX_ADDR_WIDTH(LENGTH_IND)-1 generate
--        GENERATE_MATCH_L2 : for mux_in_cnt in 0 to conv_integer(MUX_IN_SIZE_ARRAY(mux_in_ind))-1 generate
--            muxInPre(mux_in_ind)(mux_in_cnt) <= '1' when MatchUnitInputBits = matchArray(mux_in_ind)(mux_in_cnt) else '0';
--        end generate GENERATE_MATCH_L2;
--    end generate GENERATE_MATCH;

    -----------------  Pipeline buffers ---------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then -- local synchronous reset
                muxIn_b1            <= (others => (others => '0'));
                valid_b1            <= '0';
                --valid_b2            <= '0';
                encoderValidOut_b1  <= '0';
                encoderValidOut_b2  <= '0';
                muxOut_b1           <= (others => '0');
                muxSelInputBits_b1  <= (others => '0');
                muxSelInputBits_b2  <= (others => '0');
                muxSelInputBits_b3  <= (others => '0');
                valid_o             <= '0';
                bitmapMemOut_b1     <= (others => '0');
                bitmapAddr_b1       <= (others => '0');
            else
                muxIn_b1    <= muxInPre;
                valid_b1    <= valid_i;
                --valid_b2    <= valid_b1;
                --valid_b3    <= valid_b2;
                muxOut_b1   <= muxOut_pre;
                muxSelInputBits_b1      <= muxSelInputBits;
                muxSelInputBits_b2      <= muxSelInputBits_b1;
                bitmapSelInputBits_b1   <= bitmapSelInputBits;
                bitmapSelInputBits_b2   <= bitmapSelInputBits_b1;
                bitmapSelInputBits_b3   <= bitmapSelInputBits_b2;
                bitmapSelInputBits_b4   <= bitmapSelInputBits_b3;
                encoderValidOut_b1      <= encoderValidOut;
                encoderValidOut_b2      <= encoderValidOut_b1;
                bitmapMemOut_b1         <= bitmapMemOut;
                bitmapAddr_b1           <= bitmapAddr;
                valid_o                 <= bitmapMatch;
                nhiAddr_o               <= nhiAddr;
            end if;
        end if;
    end process;

    muxIn <= muxInPre when (PIPELINE_S1_EN = 0) else muxIn_b1; -- First pipeline stage exists?
    muxInValid <= valid_i when (PIPELINE_S1_EN = 0) else valid_b1;

    ----------------  MUX  ----------------------------------------------
    MUX: if PIPELINE_S2_EN = 0 generate
        muxOut_pre0 <= muxIn(conv_integer(muxSelInputBits));
    end generate MUX;
    MUX_B1: if PIPELINE_S2_EN = 1 generate
        muxOut_pre0 <= muxIn(conv_integer(muxSelInputBits_b1));
    end generate MUX_B1;
    muxOut_pre <= muxOut_pre0 when muxInValid = '1' else (others => '0');
    muxOut <=  muxOut_pre when (PIPELINE_S2_EN = 0) else muxOut_b1;

    ----------------  Encoder after MUX  --------------------------------   
	EB: Encoder 
         generic map (												  		
		      MAXTableWidth  => MAX_MUX_IN_WIDTH(LENGTH_IND),
		      OutputWidth    => LOG2_MAX_MUX_IN_WIDTH(LENGTH_IND)
 	    )
         port map( 
            clk         => clk,
            reset       => rst,--(reset or (not valid_sig2)),
		    PEB_inputs  => muxOut,
  		    Addr_output => encoderOut,
 		    valid       => encoderValidOut         
        ); 
         
    ---------------- Bitmap table address (Offsets + encoder out) --------	
    muxSelInputBits_buf <= muxSelInputBits when (PIPELINE_S2_EN = 0 and PIPELINE_S1_EN = 0) else muxSelInputBits_b2 when (PIPELINE_S2_EN = 1 and PIPELINE_S1_EN = 1) else muxSelInputBits_b1;
	
    OFFSET_TABLE1: ConstMemory   
        generic map (												  
            LENGTH          => 2 ** MUX_ADDR_WIDTH(LENGTH_IND),
            ADDRESS_WIDTH   => MUX_ADDR_WIDTH(LENGTH_IND), 
            WIDTH           => BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND),
            CONTENT_FILE    => OFFSET_TABLE1_CONTENT_FILE(LENGTH_IND)
        )
        port map (														
            clk             => clk,    
            rst             => rst,                
            address_i       => muxSelInputBits_buf,-- !!! timing must be adjusted 
            valid_i         => '1',
            data_o          => bitmapAddrOffset 
        );	

    bitmapAddr <= bitmapAddrOffset + encoderOut;

    BITMAP_GEN: if BITMAP_ADDR_WIDTH > 0 generate   -- only if at least one input bit is to be resolved by bitmaping, the bitmap section is generated 
    ---------------- BITMAP MEMORY ---------------------------------------
    BITMAP_MEM: ConstMemory   
        generic map(												  
            LENGTH          => 2 ** BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND),
            ADDRESS_WIDTH   => BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND), 
            WIDTH           => 2 ** BITMAP_ADDR_WIDTH,
            CONTENT_FILE    => BITMAP_TABLE_CONTENT_FILE(LENGTH_IND)
        )
        port map (														
            clk             => clk,  
            rst             => rst,                  
            address_i       => bitmapAddr, 
            valid_i         => encoderValidOut,
            data_o          => bitmapMemOut  
        );
   
    ---------------- BITMAP ADDRESS CALC ---------------------------------
    bitmapSelInputBits_buf <= bitmapSelInputBits_b1 when (PIPELINE_S2_EN = 0 and PIPELINE_S1_EN = 0) else bitmapSelInputBits_b3 when (PIPELINE_S2_EN = 1 and PIPELINE_S1_EN = 1) else muxSelInputBits_b2;

    DEC: Decoder
		generic map(WIDTH => BITMAP_ADDR_WIDTH)
		port map(
			data_i  => bitmapSelInputBits_buf,
			clk     => clk,
			reset   => rst,
			data_o  => decBitmapIn		
		);

    BITMAP_ADDR: BitmapAddress 
        generic map (BITMAP_MEM_WIDTH  => 2**BITMAP_ADDR_WIDTH)  
        port map (														                   
            DecIPin1        => decBitmapIn, 
            bitmap_mem_out  => bitmapMemOut,	
            valid_in        => encoderValidOut_b1,
            clk             => clk,
			rst             => rst,
            valid_out       => bitmapMatch,
            addr_out        => relativeAddr
        );

    ---------------- NHI address offset table ----------------------------	
	OFFSET_TABLE2: ConstMemory   
        generic map (												  
            LENGTH		    => 2 ** BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND),
            ADDRESS_WIDTH   => BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND), 
            WIDTH		    => NHI_ADDR_WIDTH(LENGTH_IND),
            CONTENT_FILE    => OFFSET_TABLE2_CONTENT_FILE(LENGTH_IND)
        )
        port map (														
            clk             => clk,      
            rst             => rst,              
            address_i       => bitmapAddr_b1,
            valid_i         => encoderValidOut_b1,
            data_o          => nhiAddrOffset 
        );
    nhiAddr <= nhiAddrOffset + relativeAddr;

    end generate BITMAP_GEN;

    WO_BITMAP: if BITMAP_ADDR_WIDTH = 0 generate  -- if none of the bits is matched using bitmap technique
        process(clk)
        begin
            if rising_edge(clk) then
                -- Creating the same number of pipeline stages as when bitmap exists 
                nhiAddr <= (others => '0');
                nhiAddr(BITMAP_TABLE_ADDR_WIDTH(LENGTH_IND)-1 downto 0)    <= bitmapAddr_b1;
                bitmapMatch         <= encoderValidOut_b1;
            end if;
        end process;
    end generate WO_BITMAP;

    

end lookup_engine_arch;		                                    