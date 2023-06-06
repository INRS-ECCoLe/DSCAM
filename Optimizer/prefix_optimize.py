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
#  Project: IP address lookup core
#  
#  Creation Date: 2022-04-16
#
#  Description: main optimization class
#---------------------------------------------------------------------------

import numpy as np
from numpy.random import rand
from random import randint
from bitarray import bitarray
import math
import parameters
import utilities
from bitarray.util import ba2int
from binary_tree import binary_tree
import sys

# ----- 1 Ram bit to 1 gate Cost ratio used in titness calculation 
#RAMBIT_GATE_WEIGTH_RATIO = 2

# ----- Genetic algorithm optimization class
class prefix_optimize:
    prefixes = []
    population = []
    scores = []
    best_score_rec = []
   
    def __init__(self, prefixes, prefix_length):
        self.num_of_prefixes = len(prefixes)        
        #self.prefixes_int = prefixes_int
        self.prefixes = prefixes
        self.prefix_length = prefix_length
        self.bram_cost = parameters.BRAM_COSTS_TO_TEST[0]
        self.detailed_result = []
        self.best_score_rec = []
        self.best_logic_cost = -1
        self.best_no_bram = -1
        self.best_rem_prefixes = -1
        
    def print_results(self):
        print(f'Scores : {self.scores} \n')

    # --- Initial population generation
    def initial_population(self):
        self.population = [0] * self.population_size
        for ii in range(self.population_size):
            self.population[ii] = []
            # In each bit position, 0 means that bit is matched in the match unit, 1 means match via MUX, and 2 means match via bitmap table
            for jj in range(self.prefix_length):
                self.population[ii].append(randint(0, 2));#extend(bitarray([int(rand()>=0.5)]))
    
    # --- Fitness function
    def fitness(self):
        self.scores = [0] * self.population_size
        result_vec = [[] for ii in range(self.population_size)]
        # calculating fitness of each chromosome
        for ii in range(self.population_size):
            #print('oooo', self.score_calc(self.population[ii]))
            (self.scores[ii], detailed_temp) = self.score_calc(self.population[ii]) 
            result_vec[ii].extend(detailed_temp)
        self.detailed_result.append(result_vec)

    # --- Calculate the score of a chromosome
    def score_calc(self, candidate):
        mux_bitarray = bitarray()
        bitmap_bitarray = bitarray()
        num_mux_bits = 0
        num_bitmap_bits = 0
        # mux_bitarray[i] = 1 means i'th bit is matched via MUX
        mux_bitarray = bitarray([])
        # bitmap_bitarray[i] = 1 means i'th bit is matched via bitmap table
        bitmap_bitarray = bitarray([])
        
        for jj in range(self.prefix_length):
            mux_bitarray.extend(str(int(candidate[jj] == 1)))
            bitmap_bitarray.extend(str(int(candidate[jj] != 2)))  # bits that are not resolved by bitmap table (i.e., are resolved by match unit or MUX)
            num_mux_bits = num_mux_bits + int(candidate[jj] == 1)
            num_bitmap_bits = num_bitmap_bits + int(candidate[jj] == 2)

        if (num_mux_bits > parameters.MAX_NUM_MUX_BITS) or (num_mux_bits == 0) or (candidate.count(0) < 2):  # candidate must contain at least a 1 and a 0
            return -1, [0 ,0, 0]
        #if (0 in candidate):
        #    return -1, [0 ,0, 0]
            
        num_of_mu_bits_vec = [0] * pow(2,num_mux_bits)
        mux_indexes = [jj for jj in range(self.prefix_length) if candidate[jj] == 1]
        match_unit_indexes = [jj for jj in range(self.prefix_length) if candidate[jj] == 0]
        num_of_remained_prefixes = 1
        if num_mux_bits:
            mux_bits = ba2int(bitarray([self.prefixes[0][kk] for kk in mux_indexes]))
            num_of_mu_bits_vec[mux_bits] += 1
        
        btree = binary_tree(ba2int(self.prefixes[0] & bitmap_bitarray))
        #print(bitmap_bitarray, '          ', candidate)
        #cnt=0
        for jj in range(1,self.num_of_prefixes):
            masked_prefix = ba2int(self.prefixes[jj] & bitmap_bitarray)
            found = 0
            if btree.insert(masked_prefix):
                num_of_remained_prefixes = num_of_remained_prefixes + 1   #
                if num_mux_bits:
                    mux_bits = ba2int(bitarray([self.prefixes[jj][kk] for kk in mux_indexes]))
                    num_of_mu_bits_vec[mux_bits] += 1    # increamenting the number of match circuits that correspond to mux_bits' input of the MUX
                #cnt += 1
                
        # cost function
        max_mux_in_width = max(num_of_mu_bits_vec) 
        nonzero_mux_inputs = np.count_nonzero(num_of_mu_bits_vec)
        mu_cost = sum(num_of_mu_bits_vec)   # The cost of match unit
        mux_cost = nonzero_mux_inputs * max_mux_in_width
        encoder_cost = pow(max_mux_in_width, 2)
        offset1_mem_cost =  utilities.estimate_no_brams(pow(2,num_mux_bits), math.ceil(math.log2(sum(num_of_mu_bits_vec))))
        if num_bitmap_bits > 0:
            bitmap_mem_cost =  utilities.estimate_no_brams(num_of_remained_prefixes, pow(2, num_bitmap_bits))
            offset2_mem_cost =  utilities.estimate_no_brams(num_of_remained_prefixes, math.ceil(math.log2(self.num_of_prefixes)))
        else:
            bitmap_mem_cost = 0
            offset2_mem_cost = 0
        #score = (nonzero_mux_inputs * max_mux_in_width) + (num_of_remained_prefixes * pow(2, num_bitmap_bits)) 
        overal_no_brams = (offset1_mem_cost + bitmap_mem_cost + offset2_mem_cost)
        overal_logic_cost = mu_cost + mux_cost + encoder_cost
        #if overal_no_brams <= parameters.MAX_AVAILABLE_BRAMS:
        score = overal_logic_cost + self.bram_cost * overal_no_brams
        '''
        print('          ', candidate)
        print(f' mu cost = {mu_cost}      mux cost = {mux_cost}      offset mem cost = {offset1_mem_cost}      bitmap_mem_cost = {bitmap_mem_cost}     offset2_mem_cost = {offset2_mem_cost}     num_of_remained_prefixes= {num_of_remained_prefixes}' )
        print(f'SCORE = {score}\n')
        '''
        del btree 
        detailed_result =  [overal_logic_cost, overal_no_brams, num_of_remained_prefixes] 
        return score , detailed_result
    
    # --- tournamrent selection
    def selection(self):
	    # first random selection
        selected_idx = np.random.randint(self.population_size)
        for idx in np.random.randint(0, self.population_size, parameters.TOURNOMENT_SIZE-1):
		    # check if better in a tournament
            #print(f'* idx = {idx}')
            if self.scores[idx] < self.scores[selected_idx]:
                selected_idx = idx
        return [self.population[selected_idx], self.scores[selected_idx]]

    # --- uniform crossover two parents to create two children
    def crossover(self, parent1, parent2, crossover_rate):
        # children are copies of parents by default
        child1, child2 = parent1.copy(), parent2.copy()
        # check for recombination
        if rand() < crossover_rate:
            for ii in range(self.prefix_length):
                if rand() < 0.5:
                    # perform crossover
                    child1[ii] = parent2[ii]
                    child2[ii] = parent1[ii]
        return [child1, child2]

    # --- mutation operator
    def mutation(self, chromosome, mutation_rate):
        mutated = chromosome.copy()
        for ii in range(self.prefix_length):
            # check for a mutation
            if rand() < mutation_rate:
                # change the element
                mutated[ii] = randint(0, 2)
        #print(f'## chromosome {chromosome}   ->   \n   mutated:   {mutated}')
        return mutated

     # --- Generate output files 
    def generate_result_files(self, solution):
        # generate memory content files for match unit, MUX, offset memories and bitmap unit
        if self.prefix_length < 10:
            str_temp = '00' + str(self.prefix_length)
        elif self.prefix_length < 100:
            str_temp = '0' + str(self.prefix_length)
        else:
            str_temp = str(self.prefix_length)
        mu_filename             = parameters.output_path + 'Match_Unit_000'  + str_temp + '.txt'
        offset1_filename        = parameters.output_path + 'Offset_Table1_' + str_temp + '.txt'
        offset2_filename        = parameters.output_path + 'Offset_Table2_' + str_temp + '.txt'
        bitmap_filename         = parameters.output_path + 'Bitmap_Table0_' + str_temp + '.txt'
        reordered_filename      = parameters.output_path + 'Reordered_Prefixes.txt'
        mux_size_filename       = parameters.output_path + 'Mux_In_Size_00' + str_temp + '.txt'

        mux_bitarray = bitarray()
        bitmap_bitarray = bitarray()
        nhi_addr_width = math.ceil(math.log2(self.num_of_prefixes))
        num_mux_bits = 0
        num_bitmap_bits = 0
        # mux_bitarray[i] = 1 means i'th bit is matched via MUX
        mux_bitarray = bitarray([])
        # bitmap_bitarray[i] = 1 means i'th bit is matched via bitmap table
        bitmap_bitarray = bitarray([])
        for jj in range(self.prefix_length):
            mux_bitarray.extend(str(int(solution[jj] == 1)))
            bitmap_bitarray.extend(str(int(solution[jj] != 2)))  # bits that are not resolved by bitmap table (i.e., are resolved by match unit or MUX)
            num_mux_bits = num_mux_bits + int(solution[jj] == 1)
            num_bitmap_bits = num_bitmap_bits + int(solution[jj] == 2)

        num_mux_inputs = pow(2,num_mux_bits)
        bitmap_mem_width = pow(2, num_bitmap_bits)
        match_unit_bit_array = [[]] * num_mux_inputs
        mux_in_width_vec = [0]* num_mux_inputs
        bitmap_array = [[]] * num_mux_inputs
        reordered_prefix_array = [[]] * num_mux_inputs  # to print into reordered_prefixes.txt file
        num_of_mu_bits_vec = [0] * num_mux_inputs
        mux_unit_indexes = [jj for jj in range(self.prefix_length) if solution[jj] == 1]
        bitmap_indexes = [jj for jj in range(self.prefix_length) if solution[jj] == 2]
        for ii in range(self.num_of_prefixes):
            mux_bits = ba2int(bitarray([self.prefixes[ii][kk] for kk in mux_unit_indexes]))
            if bitmap_indexes != []:
                bitmap_value = ba2int(bitarray([self.prefixes[ii][kk] for kk in bitmap_indexes]))
            else:
                bitmap_value = []
            num_of_mu_bits_vec[mux_bits] += 1
            match_unit_bits = [self.prefixes[ii][jj] for jj in range(self.prefix_length) if solution[jj] == 0]
            
            if match_unit_bit_array[mux_bits] == []:
                match_unit_bit_array[mux_bits]=[match_unit_bits]
                bitmap_array[mux_bits]=[[bitmap_value]]
                reordered_prefix_array[mux_bits]=[[ii]]
            else:
                found_ind = -1
                for mu_prefix_ind in range(len(match_unit_bit_array[mux_bits])):
                    if match_unit_bit_array[mux_bits][mu_prefix_ind] == match_unit_bits:
                        found_ind = mu_prefix_ind
                if found_ind == -1:
                    match_unit_bit_array[mux_bits].append(match_unit_bits)
                    bitmap_array[mux_bits].append([bitmap_value])
                    reordered_prefix_array[mux_bits].append([ii])
                else:
                    if (bitmap_value not in bitmap_array[mux_bits][found_ind]):
                        bitmap_array[mux_bits][found_ind].append(bitmap_value)
                        reordered_prefix_array[mux_bits][found_ind].append(ii)
        max_mux_in_width = 0 
        total_mu_prefixes = 0
        for ii in range(len(match_unit_bit_array)):
            mux_in_width_vec[ii] = len(match_unit_bit_array[ii])
            total_mu_prefixes += mux_in_width_vec[ii]
            if max_mux_in_width < mux_in_width_vec[ii]:
                max_mux_in_width = mux_in_width_vec[ii]
        mux_addr_width = math.ceil(math.log2(total_mu_prefixes))

        # generate the output memory content files
        bitmap_mem_length = 0
        with open(mu_filename, 'w') as mu_file:
            with open(offset1_filename, 'w') as offset1_file:
                with open(bitmap_filename, 'w') as bitmap_file:
                    with open(offset2_filename, 'w') as offset2_file:
                        offset1_addr = 0
                        offset2_temp = 0
                        for ii in range(len(match_unit_bit_array)):

                            for jj in range(len(match_unit_bit_array[ii])):
                                #mu_file.write('\n'.join( match_unit_bit_array[1][0]))
                                print(*match_unit_bit_array[ii][jj], sep="", file=mu_file)
                                if bitmap_indexes != []:
                                    bitmap_temp = [0] * bitmap_mem_width 
                                    for kk in range(len(bitmap_array[ii][jj])):
                                        bitmap_temp[bitmap_mem_width - bitmap_array[ii][jj][kk] - 1] = 1
                                    print(*bitmap_temp, sep="", file=bitmap_file)
                                print(f'{offset2_temp:0{nhi_addr_width}b}', file=offset2_file)
                                offset2_temp += len(bitmap_array[ii][jj])
                                bitmap_mem_length += 1
                            print(f'{offset1_addr:0{mux_addr_width}b}', file=offset1_file)
                            remained = 0
                            for jj in range(ii+1,len(match_unit_bit_array)):
                                remained += len(match_unit_bit_array[jj]) 
                            #print( remained)
                            if remained > 0:
                                offset1_addr += len(match_unit_bit_array[ii]) 
        with open(reordered_filename, 'a') as ro_file:
            # Printing reordered_prefix.txt file
            for ii in range(len(bitmap_array)):
                for jj in range(len(bitmap_array[ii])):
                    sorted_ind = sorted(range(len(bitmap_array[ii][jj])),key=bitmap_array[ii][jj].__getitem__)
                    for kk in sorted_ind:
                        print(*self.prefixes[reordered_prefix_array[ii][jj][kk]], sep="", file=ro_file)
        with open(mux_size_filename, 'w') as mux_size_file:
            #print(*mux_in_width_vec, sep="\n", file=mux_size_file)
            #print(f'{mux_in_width_vec:0{max_mux_in_width}b}', sep="\n",file=offset2_file)
            for ii in range(num_mux_inputs):
                print(f'{mux_in_width_vec[ii]:0{math.ceil(math.log2(max_mux_in_width+1))}b}', file=mux_size_file)

        del mu_file
        del offset1_file
        del offset2_file
        del bitmap_file
        del ro_file
        del mux_size_file
        
        param_pkg_data = []
        param_pkg_data.append(math.ceil(math.log2(bitmap_mem_length))) # element 1: bitmap addr width  
        param_pkg_data.append(max_mux_in_width) # element 2: MAX_MUX_IN_WIDTH
        param_pkg_data.append(mux_in_width_vec) # element 3: MUX_IN_SIZE

        #print('ooooooooooo:  ', param_pkg_data)

        return param_pkg_data
            
    
    # --- genetic algorithm
    def genetic_algorithm(self, max_no_improve_iter, population_size):
        if population_size <= 1:
            print('ERROR: the population size must be greater than or equal to 2')
            return
        self.population_size = population_size
        # initial population of random bitstring
        self.initial_population()
        # evaluate all candidates in the population
        self.fitness()
        
        # keep track of best solution
        best_eval = pow(2,31)#self.scores[0]
        best = self.population[0]
        self.best_rem_prefixes = self.num_of_prefixes
    
        selected = [[0] * self.prefix_length] * self.population_size
        selected_score = [0] * self.population_size
        children = [[0] * self.prefix_length] * self.population_size
        
        generation = 1
        # enumerate generations
        no_improve_count = 0
        
        while no_improve_count < max_no_improve_iter:
            # check for new best solution
            no_improve_count += 1
            children_count = 0
            
            for ii in range(0, self.population_size, 2):
                # get selected parents in pairs
                parent1 = selected[ii]
                parent2 = best
                #parent2 = selected[ii+1]
                # crossover and mutation
                for child in self.crossover(parent1, parent2, 0.95):
                    # mutation
                    # store for next generation
                    children[children_count] = self.mutation(child, 0.1)
                    children_count += 1
            # replace population
            self.population = children
            self.fitness()
            children = [[0] * self.prefix_length] * self.population_size

            for ii in range(self.population_size):
                if self.scores[ii] > 0 and self.scores[ii] < best_eval:
                    best, best_eval = self.population[ii], self.scores[ii]
                    self.best_no_bram = self.detailed_result[generation][ii][1]
                    self.best_logic_cost = self.detailed_result[generation][ii][0]
                    self.best_rem_prefixes = self.detailed_result[generation][ii][2]   # number of remained prefixes using the best candidate
                    no_improve_count = 0
                    #print('\033[32m' + "{0}".format('*** NEW BEST *** ') + '\033[0m', end='\n')
                    #print(self.population[ii], '  # BRAMs:', self.detailed_result[generation][ii][1], '  Logic Cost:', self.detailed_result[generation][ii][0],'\n\n')
                # select parents
                [selected[ii], selected_score[ii]] = self.selection()
            # create the next generation
            generation = generation + 1   
            self.best_score_rec.append(best_eval)
            print(f'Length: {self.prefix_length}   BRAM Cost: {self.bram_cost}  |  Gen: {generation}    Best Chrom: {best}   Score: {best_eval}   Logic: {self.best_logic_cost}   # BRAMs: {self.best_no_bram}   Remaining: {self.best_rem_prefixes}')
        return [best, best_eval]
    

    

    


    