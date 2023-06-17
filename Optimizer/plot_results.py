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
#  Project: IP address lookup core
#  
#  Creation Date: 2023-04-12
#
#  Description: Plot and log the results
#---------------------------------------------------------------------------

import numpy as np
import os
from multiprocessing import Pool
import matplotlib.pyplot as plt
import mpl_toolkits.mplot3d.axes3d as p3
import matplotlib.ticker as mticker
import matplotlib.animation as animation
from functools import partial
import parameters
import csv
import numpy as np


def plot_convergence(detailed_result_array):
       np.seterr(divide = 'ignore')        
       #print('cc  \n\n', len(detailed_result_array[0]))
       def log_tick_formatter(val, pos=None):
              return f"$10^{{{int(val)}}}$"  # remove int() if you don't use MaxNLocator
              # return f"{10**val:.2e}"      # e-Notation
       color_code = ['blue','orange', 'red', 'yellow']
       for length in range(len(detailed_result_array[0])):
              
              if detailed_result_array[0][length] != []:  # There is at least one prefix of bitlength equal to 'length'
                     fig = plt.figure()
                     # syntax for 3-D projection
                     ax = plt.axes(projection ='3d')
                     
                     no_bram_cost = len(detailed_result_array)
                     no_bram_vec = [[] for ii in range(no_bram_cost)]
                     logic_cost = [[] for ii in range(no_bram_cost)]
                     best_logic_cost_vec = [[] for ii in range(no_bram_cost)]
                     best_no_bram_vec = [[] for ii in range(no_bram_cost)]
                     no_generations = []
                     
                     for bram_cost_idx in range(no_bram_cost):
                            best_score = pow(10,9)  # a very large number
                            no_generations.append(len(detailed_result_array[bram_cost_idx][length]))
                            result = detailed_result_array[bram_cost_idx][length]
                            
                            population_size = len(result[0])
                            for ii in range(no_generations[bram_cost_idx]):
                                   no_bram_vec[bram_cost_idx].append([result[ii][jj][1] for jj in range(population_size)])
                                   logic_cost[bram_cost_idx].append([result[ii][jj][0] for jj in range(population_size)])
                                   score_vec = parameters.BRAM_COSTS_TO_TEST[bram_cost_idx] * np.array(no_bram_vec[bram_cost_idx][-1]) + np.array(logic_cost[bram_cost_idx][-1])
                                   min_score_temp = min(i for i in score_vec if i > 0)
                                   #print('hhhhhhh', no_bram_vec[bram_cost_idx][-1], '\n', logic_cost[bram_cost_idx][-1], '\n' , score_vec)
                                   if min_score_temp < best_score and min_score_temp != 0:
                                          best_score = min_score_temp
                                          print('***** found', min_score_temp, '    gen', ii)
                                          idx = score_vec.tolist().index(min_score_temp)
                                          best_no_bram = result[ii][idx][1]
                                          best_logic_cost = result[ii][idx][0]
                                   best_no_bram_vec[bram_cost_idx].append(best_no_bram)
                                   best_logic_cost_vec[bram_cost_idx].append(best_logic_cost)
                            for ii in range(len(no_bram_vec[bram_cost_idx])): 
                                   if logic_cost[bram_cost_idx][ii] != 0: 
                                          x = [ii+1] * len(no_bram_vec[bram_cost_idx][ii])
                                          y = no_bram_vec[bram_cost_idx][ii]  # y axis in "all candidate" plot
                                          z = np.log10(logic_cost[bram_cost_idx][ii])
                                                                                   
                                          #print('\n ', bram_cost_idx, '\nx= ', x, ' \ny= ', y, ' \nz= ', z, no_generations)
                                          ax.scatter(x, y, z, color=color_code[bram_cost_idx])
                                          
                     
                     yTitle = 'Convergence Bit-Length: ' + str(length)
                     ax.zaxis.set_major_formatter(mticker.FuncFormatter(log_tick_formatter))
                     ax.zaxis.set_major_locator(mticker.MaxNLocator(integer=True))
                     ax.xaxis.set_major_locator(mticker.MaxNLocator(integer=True))
                     ax.axes.set_ylim3d(bottom=0, top=500)
                     ax.set_title(yTitle)#'Convergence Bit-Length:')
                     ax.set_xlabel('Generation #', fontsize=14)
                     ax.set_ylabel('# BRAMs (est.)', fontsize=14)
                     ax.set_zlabel('Logic Cost (est.)', fontsize=14)
                     
                     #plt.close()
                     #del ax
                     #plt.show()
                     fig = plt.figure()
                     ax2 = plt.axes(projection ='3d')
                     for bram_cost_idx in range(no_bram_cost):
                            x2 = range(no_generations[bram_cost_idx])
                            y2 = best_no_bram_vec[bram_cost_idx] # y axis in "best candidate" plot
                            z2 = best_logic_cost_vec[bram_cost_idx]
                            print('\n ', '\nx= ', x2, ' \ny= ', y2, ' \nz= ', z2, no_generations)
                            ax2.scatter(x2, y2, z2, color=color_code[bram_cost_idx])

                     plt.show()

def plot_results(bitlength, score_rec):
       #fig, ax = plt.subplots()
       for ii in range(len(score_rec)):
              # plot
              plt.plot(range(len(score_rec[ii])), np.divide(np.array(score_rec[ii]),1000), color='blue', label= str(bitlength[ii]), marker=10, linewidth=1.0)
              plt.xlabel('Generation', fontsize=16)
              plt.ylabel('Score (x1000)', fontsize=16)
              plt.title('Bitlength: '+ str(bitlength[ii]))
              plt.show()

def log_results(length, score_rec, bram_cost, candidate, prefix_file_name, no_prefixes, best_no_bram, best_logic_cost, rem_prefixes):
       # Write the log in log.cvs
       with open(parameters.optimizer_path + 'log.csv', 'a', newline='') as csvfile:
              fieldnames = ['Filename','Bit_Length', 'Number_of_Prefixes', 'BRAM_Cost', 'Candidate', 'Final_Score', 'Est_no_BRAMs', 'Est_Logic_Cost', 'Remained_prefixes']
              writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
              if os.stat(parameters.optimizer_path + 'log.csv').st_size == 0:
                     writer.writeheader()
              #print('pppp:', candidate_str)
              writer.writerow({'Filename': prefix_file_name ,'Bit_Length': str(length), 'Number_of_Prefixes': no_prefixes, 'BRAM_Cost': bram_cost, 
                               'Candidate': str(candidate), 'Final_Score': str(score_rec[-1]), 'Est_no_BRAMs':best_no_bram, 'Est_Logic_Cost': best_logic_cost, 
                               'Remained_prefixes':rem_prefixes})

       #ax.set(xlim=(0, 8), xticks=np.arange(1, 8), ylim=(0, 8), yticks=np.arange(1, 8))