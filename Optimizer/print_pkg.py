#---------------------------------------------------------------------------
#                ___________
#    ______     /   ____    ____      _          ______
#   |  ____|   /   /    INRS    \    | |        |  ____|
#   | |       /   /     Edge     \   | |        | |
#   | |____  /   /    Computing   \  | |        | |____
#   |  ____| \   \  Communication /  | |        |  ____|   
#   | |       \   \   Learning   /   | |        | |
#   | |____    \   \_____LAB____/    | |_____   | |____
#   |______|    \ ___________        |_______|  |______|
#
#  Edge Computing, Communication and Learning Lab (ECCoLe)- INRS University
#
#  Author: Shervin Vakili
#
#  Project: Directly Synthesized Content-Addressable Momory (DSCAM)
#  
#  Creation Date: 2023-04-12
#
#  Description: Generate HDL parameters in parameters.vhd file
#---------------------------------------------------------------------------

import math
import parameters
from math import log

def print_pkg(num_of_prefixes_vec, input_width, candidate, pkg_data):
    # Print Package.vhd
    parameter_pkg_filename  = parameters.output_path + 'Parameters.vhd'
        
    def print_constant(name, data_type, value, pkg_file):
        if type(value) == list:
            print('constant ', name, ':', data_type, ':= (', end='', file=pkg_file)
            print(*value, sep=',', end='', file=pkg_file)
            print(');', file=pkg_file)
        else:
            print('constant ', name, ':', data_type, ':= ', value, ';', file=pkg_file)

    mu_indexes = []
    mu_indexes_flat_vec = []
    mux_unit_indexes = []
    mux_indexes_flat_vec = []
    bitmap_indexes = []
    bitmap_indexes_flat_vec = []
    no_prefix_widths = len(num_of_prefixes_vec) # number of prefix widths
    accum_no_prefixes = [0] * (no_prefix_widths + 1)
    bitwidths = [0] * no_prefix_widths
    for ii in range(no_prefix_widths):
        bitwidths[ii] = len(candidate[ii])
        mu_indexes_temp = [input_width - bitwidths[ii] + jj for jj in range(bitwidths[ii]) if candidate[ii][jj] == 0]
        mux_unit_indexes_temp = [input_width - bitwidths[ii] +jj for jj in range(bitwidths[ii]) if candidate[ii][jj] == 1]
        bitmap_indexes_temp = [input_width - bitwidths[ii] +jj for jj in range(bitwidths[ii]) if candidate[ii][jj] == 2]
        mu_indexes.append(mu_indexes_temp)
        mu_indexes_flat_vec =  mu_indexes_flat_vec + mu_indexes_temp[::-1]  # reversinf mu_indexes_temp for MSB first ordering
        mux_unit_indexes.append(mux_unit_indexes_temp)
        mux_indexes_flat_vec = mux_indexes_flat_vec + mux_unit_indexes_temp[::-1]
        bitmap_indexes.append(bitmap_indexes_temp)
        bitmap_indexes_flat_vec = bitmap_indexes_flat_vec + bitmap_indexes_temp[::-1]
        accum_no_prefixes[ii] = sum(num_of_prefixes_vec[0:ii]) # Accumulated number of prefixes
    
    with open(parameter_pkg_filename, 'w') as pmtr_file:
        nhi_addr = [math.ceil(math.log2(num_of_prefixes_vec[kk])) for kk in range(no_prefix_widths)]   
        final_addr_width = math.ceil(math.log2(sum(num_of_prefixes_vec)))
        mu_bitwidth = [len(mu_indexes[kk]) for kk in range(no_prefix_widths)]   # number of input bits resolved in match unit
        mux_bitwidth = [len(mux_unit_indexes[kk]) for kk in range(no_prefix_widths)]
        bitmap_bitwidth = [len(bitmap_indexes[kk]) for kk in range(no_prefix_widths)]
        bitmap_addr_width = [pkg_data[kk][0] for kk in range(no_prefix_widths)] 
        max_mux_in_width = [pkg_data[kk][1] for kk in range(no_prefix_widths)] 
        log2_max_mux_in_width = [math.ceil(math.log2(max_mux_in_width[kk]+1)) for kk in range(no_prefix_widths)]
        for jj in range(no_prefix_widths):
            if log2_max_mux_in_width[jj] == 0:
                log2_max_mux_in_width[jj] = 1
        mux_in_size_vec = pkg_data[0][2]
        #print('ssssssssssssssssssss', pkg_data[0][2])
        mux_in_size_start = [0] * (no_prefix_widths)
        mu_ind_start = [0] * (no_prefix_widths)
        mux_ind_start = [0] * (no_prefix_widths)
        bitmap_ind_start = [0] * (no_prefix_widths)
        if no_prefix_widths > 1:
            for jj in range(no_prefix_widths-1):
                mux_in_size_start[jj+1] = mux_in_size_start[jj] + 2 ** mux_bitwidth[jj]
                mu_ind_start[jj+1] = mu_ind_start[jj] + mu_bitwidth[jj]
                mux_ind_start[jj+1] = mux_ind_start[jj] + mux_bitwidth[jj]
                bitmap_ind_start[jj+1] = bitmap_ind_start[jj] + bitmap_bitwidth[jj] 
                mux_in_size_vec = mux_in_size_vec + (pkg_data[jj+1][2])
        # Start print out
        print('library IEEE;\nuse IEEE.STD_LOGIC_1164.ALL;\nuse std.textio.all;\n\npackage Parameters is\n', file=pmtr_file)
        print_constant('INPUT_WIDTH', 'integer', input_width, pmtr_file)
        print_constant('FINAL_ADDR_WIDTH', 'integer', final_addr_width, pmtr_file)
        print_constant('NO_PREFIX_LENGTHS', 'integer', len(bitwidths), pmtr_file)
        print('type PARAMETER_ARRAY_TYPE is array (1 to NO_PREFIX_LENGTHS+1) of integer;', file=pmtr_file)
        print_constant('PREFIX_BITWIDTH', 'PARAMETER_ARRAY_TYPE', bitwidths+[0], pmtr_file)
        print_constant('NO_PREFIXES', 'PARAMETER_ARRAY_TYPE', accum_no_prefixes, pmtr_file)
        print_constant('NHI_ADDR_WIDTH', 'PARAMETER_ARRAY_TYPE', nhi_addr+[0], pmtr_file)
        print_constant('MATCH_UNIT_BITWIDTH', 'PARAMETER_ARRAY_TYPE', mu_bitwidth+[0], pmtr_file)
        print_constant('MUX_ADDR_WIDTH', 'PARAMETER_ARRAY_TYPE', mux_bitwidth+[0], pmtr_file)
        print_constant('BITMAP_TABLE_ADDR_WIDTH', 'PARAMETER_ARRAY_TYPE', bitmap_addr_width+[0], pmtr_file)
        print_constant('MAX_MUX_IN_WIDTH', 'PARAMETER_ARRAY_TYPE', max_mux_in_width+[0], pmtr_file)
        print_constant('LOG2_MAX_MUX_IN_WIDTH', 'PARAMETER_ARRAY_TYPE', log2_max_mux_in_width+[0], pmtr_file)
        print_constant('MUX_IN_SIZE_START_IND', 'PARAMETER_ARRAY_TYPE', mux_in_size_start+[0], pmtr_file)
        print_constant('MU_IND_START', 'PARAMETER_ARRAY_TYPE', mu_ind_start+[0], pmtr_file)
        print_constant('MUX_IND_START', 'PARAMETER_ARRAY_TYPE', mux_ind_start+[0], pmtr_file)
        print_constant('BITMAP_IND_START', 'PARAMETER_ARRAY_TYPE', bitmap_ind_start+[0], pmtr_file)
        print_constant('TOTAL_MUX_INPUTS', 'integer',mux_in_size_start[no_prefix_widths-1]+2 ** mux_bitwidth[no_prefix_widths-1], pmtr_file)
        print('type MUX_IN_SIZE_TYPE is array (0 to TOTAL_MUX_INPUTS-1) of integer;', file=pmtr_file)
        #print_constant('MUX_IN_SIZE', 'MUX_IN_SIZE_TYPE',mux_in_size_vec, pmtr_file)
        print(f'type MATCH_UNIT_INDEX_TYPE is array (1 to {len(mu_indexes_flat_vec)}) of integer;', file=pmtr_file)
        print_constant('MATCH_UNIT_INDEX', 'MATCH_UNIT_INDEX_TYPE', mu_indexes_flat_vec, pmtr_file)
        print(f'type MUX_BIT_INDEX_TYPE is array (1 to {len(mux_indexes_flat_vec)}) of integer;', file=pmtr_file)
        print_constant('MUX_BIT_INDEX', 'MUX_BIT_INDEX_TYPE', mux_indexes_flat_vec, pmtr_file)
        if len(bitmap_indexes_flat_vec) > 1:
            print(f'type BITMAP_INDEX_TYPE is array (1 to {len(bitmap_indexes_flat_vec)}) of integer;', file=pmtr_file)
            print_constant('BITMAP_BIT_INDEX', 'BITMAP_INDEX_TYPE', bitmap_indexes_flat_vec, pmtr_file)
        else:
            bitmap_indexes_flat_vec.extend([0,0])
            print(f'type BITMAP_INDEX_TYPE is array (1 to 2) of integer;', file=pmtr_file)
            print_constant('BITMAP_BIT_INDEX', 'BITMAP_INDEX_TYPE', bitmap_indexes_flat_vec[0:2], pmtr_file)
        print('type TABLE_CONTENT_FILE_NAME_TYPE is array(1 to NO_PREFIX_LENGTHS+1) of string(1 to 38);', file=pmtr_file)
        offset_table1_filename = []
        offset_table2_filename = []
        match_unit_filename = []
        bitmap_table_filename = []
        mux_in_size_filename = []
        for ii in range(len(bitwidths)):
            width_str = str(bitwidths[ii])
            if bitwidths[ii] < 10:
                width_str = '00' + width_str
            elif bitwidths[ii] < 100:
                width_str = '0' + width_str
            match_unit_filename.append('"' + parameters.parameters_path + 'Match_Unit_000'+ width_str +'.txt"')
            offset_table1_filename.append('"' + parameters.parameters_path + 'Offset_Table1_'+ width_str +'.txt"')
            offset_table2_filename.append('"' + parameters.parameters_path + 'Offset_Table2_'+ width_str +'.txt"')
            bitmap_table_filename.append('"' + parameters.parameters_path + 'Bitmap_Table0_'+ width_str +'.txt"')
            mux_in_size_filename.append('"' + parameters.parameters_path + 'Mux_In_Size_00'+ width_str +'.txt"')
        match_unit_filename.append('"' + parameters.parameters_path + 'Match_Unit_000xxx.txt"')
        offset_table1_filename.append('"' + parameters.parameters_path + 'Offset_Table1_xxx.txt"')
        offset_table2_filename.append('"' + parameters.parameters_path + 'Offset_Table2_xxx.txt"')
        bitmap_table_filename.append('"' + parameters.parameters_path + 'Bitmap_Table0_xxx.txt"')
        mux_in_size_filename.append('"' + parameters.parameters_path + 'Mux_In_Size_000xx.txt"')
        print_constant('MATCH_UNIT_BITS_FILE', 'TABLE_CONTENT_FILE_NAME_TYPE', match_unit_filename, pmtr_file)
        print_constant('OFFSET_TABLE1_CONTENT_FILE', 'TABLE_CONTENT_FILE_NAME_TYPE', offset_table1_filename, pmtr_file)
        print_constant('OFFSET_TABLE2_CONTENT_FILE', 'TABLE_CONTENT_FILE_NAME_TYPE', offset_table2_filename, pmtr_file)
        print_constant('BITMAP_TABLE_CONTENT_FILE', 'TABLE_CONTENT_FILE_NAME_TYPE', bitmap_table_filename, pmtr_file)
        print_constant('MUX_IN_SIZE_CONTENT_FILE', 'TABLE_CONTENT_FILE_NAME_TYPE', mux_in_size_filename, pmtr_file)
        
        #Termination
        print('end package Parameters;\n\npackage body Parameters is\nend package body Parameters;', file=pmtr_file) 
        del pmtr_file

