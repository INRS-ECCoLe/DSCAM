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
#  Edge Computing, Communication and Learning Lab - INRS University
#
#  Author: Shervin Vakili
#
#  Project: Directly Synthesized Content-Addressable Momory (DSCAM)
#  
#  Creation Date: 2022-03-14
#
#  Description: Finding optimal way to map a given set of IP prefixes into 
#               SplitBucket+ architecture.
#---------------------------------------------------------------------------

import numpy as np
import sys
import os
import glob
import csv
from prefix_optimize import prefix_optimize
from print_pkg import print_pkg
from bitarray import bitarray
from timeit import default_timer as timer
from bitarray.util import ba2int
import plot_results
import parameters

args = sys.argv[1:]  # 3 functions: plot_all, bebug, [default optimization] (without any argument)


#prefix_file_name = '.\Optimizer\\test_23bit.txt'
#prefix_file_name = '.\Optimizer\\test_24bit.txt'
#prefix_file_name = '.\Optimizer\\TestCase524287.txt'
prefix_file_name = '.\Optimizer\\generated_prefix_file.txt'
#prefix_file_name = '.\Optimizer\\small_test.txt'

# --- Read prefix file
with open(prefix_file_name) as prefix_file:
    prefixes = prefix_file.readlines()

line_length = len(prefixes[0])
log2_prefix_length = int(np.log2(line_length))
prefix_length = 2 ** log2_prefix_length

prefix = []
for ii in range(prefix_length+1):
    prefix.append([])
num_of_prefixes = [0] * (prefix_length+1)
num_of_prefixes_vec = [0] * (prefix_length + 1)  # value j at index i indicates there are j prefixes of bitlength i
# Organizing prefixes. prefix[i] contains all prefixes of length i.
for prefix_str in prefixes:
    prefix_temp= bitarray(prefix_str)
    # Length of this prefix
    if prefix_str and prefix_str != '\n':
        actual_prefix_length = ba2int(prefix_temp[prefix_length:])
        num_of_prefixes[actual_prefix_length] += 1
        prefix_temp= bitarray(prefix_str)
        # Length of this prefix
        actual_prefix_length = ba2int(prefix_temp[prefix_length:])
        prefix[actual_prefix_length].append(prefix_temp[0:actual_prefix_length])     
        num_of_prefixes_vec[actual_prefix_length] += 1

old_files = glob.glob(parameters.output_path+'*')
for ff in old_files:
    os.remove(ff)

# --- Processing prefixes
result_vec = []
pkg_data = []
length_vec = []
candidate_vec = []
index = 0
if args != [] and args[0] == 'debug':  
# checks the score of one given solution (candidate) and generates corresponding memory contents and parameters.vhd
    candidate = [0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1]
    found = 0
    for length in range(prefix_length+1):
        if num_of_prefixes_vec[length] > 0 :
            if length == len(candidate):
                found = 1
                p1 = prefix_optimize(prefix[length], length)
                print(f' ------------- {p1.score_calc(candidate)}')
                # Generate memory content files
                pkg_data.append(p1.generate_result_files(candidate))
                candidate_vec.append(candidate[::-1])
                length_vec.append(num_of_prefixes_vec[length])
                print_pkg(length_vec, prefix_length, candidate_vec, pkg_data)
                #print(f'\n\n ---------------- Prefix length : {length}', num_of_prefixes_vec[length])
                del p1
    if found == 0:
        print('*** WARNING: No prefix with the similar length to the given candidate was found')

elif args != [] and args[0] == 'plot_all': 
    # Ploting all different options of BRAM_COSTS_TO_TEST (in parameters.py) in one chart
    if len(parameters.BRAM_COSTS_TO_TEST) > 3:
           print('Error: BRAM_COSTS_TO_TEST can not have more than 4 elements')
           quit()
    #detailed_result_array = [[[0]] * prefix_length] * len(parameters.BRAM_COSTS_TO_TEST)
    detailed_result_array = [[[] for i in range(prefix_length)] for j in range(len(parameters.BRAM_COSTS_TO_TEST))]
    #detailed_result_array[1][1].append(1)
    for length in range(prefix_length+1):
        if num_of_prefixes_vec[length] > 0 :
            idx = 0
            for bram_cost in parameters.BRAM_COSTS_TO_TEST:
                p1 = prefix_optimize(prefix[length], length)
                p1.bram_cost = bram_cost
                # Running GA
                result = p1.genetic_algorithm(parameters.TERMINATION_COUNT, parameters.POPULATION_SIZE)
                result_vec.append(result[0])
                # Generate memory content files
                pkg_data.append(p1.generate_result_files(result[0]))  # Generate HDL files only for the first bram cost option (BRAM_COSTS_TO_TEST)
                candidate_vec.append(result[0][::-1])
                length_vec.append(num_of_prefixes_vec[length])
                detailed_result_array[idx][length].extend(p1.detailed_result) 
                del p1
                idx += 1
    plot_results.plot_convergence(detailed_result_array)
    print_pkg(length_vec, prefix_length, candidate_vec, pkg_data)

elif args != [] and args[0] == 'H':  
    for length in range(prefix_length+1):
        if num_of_prefixes_vec[length] > 0 :
            print(f'\n\n**************************** Bit Length : {length} ****************************\n')
            
            p1 = prefix_optimize(prefix[length], length)
            result = p1.Heuristic_optimizer()

else:
    # Ordinary optimization
    bitlength_vec = []
    best_score_rec = []
    for length in range(prefix_length+1):
        if num_of_prefixes_vec[length] > 0 :
            print(f'\n\n**************************** Bit Length : {length} ****************************\n')
            
            bitlength_vec.append(length)
            p1 = prefix_optimize(prefix[length], length)
            # genetic_algorithm(max_no_improve_iter, population_size)
            start_time = timer()
            result = p1.genetic_algorithm(parameters.TERMINATION_COUNT, parameters.POPULATION_SIZE)
            result_vec.append(result[0])
            best_score_rec.append(p1.best_score_rec)
            stop_time = timer()

            # Generate memory content files
            pkg_data.append(p1.generate_result_files(result[0]))
            candidate_vec.append(result[0][::-1])
            length_vec.append(num_of_prefixes_vec[length])

            time_str='*** Elapsed time : ' + str(stop_time - start_time) + 's'
            print('\033[32m' + "{0}".format(time_str) + '\033[0m', end='')
            index += 1
            if parameters.LOG_PRINT_EN == True:
                plot_results.log_results(length, p1.best_score_rec, parameters.BRAM_COSTS_TO_TEST[0], candidate_vec[-1], prefix_file_name, 
                                         length_vec[-1], p1.best_no_bram, p1.best_logic_cost, p1.best_rem_prefixes)
            del p1
    print_pkg(length_vec, prefix_length, candidate_vec, pkg_data)
    with open(parameters.optimizer_path + 'log.csv', 'a', newline='') as outfile:
        writer = csv.writer(outfile, lineterminator='\n')
        writer.writerow('')
    # plot the results
    plot_results.plot_results(bitlength_vec, best_score_rec)