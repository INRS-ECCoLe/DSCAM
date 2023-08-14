import math 
import numpy as np
import parameters

def estimate_no_brams(length, width):
    # Estimate the number of brams from the length and width   
    no_parallel_brams = 1
    width_t = width
    if width_t > 72:
        no_parallel_brams = math.ceil((width_t/72))
        width_t = width_t / no_parallel_brams
    if width_t == 0:
        no_brams = 0
    elif width_t == 1:      # 32K x 1 config
        no_brams = math.ceil(length / pow(2,15))
    elif width_t == 2:    # 16K x 2 config
        no_brams = math.ceil(length / pow(2,14))
    elif width_t <= 4:
        no_brams = math.ceil(length / pow(2,13))
    elif width_t <= 9:
        no_brams = math.ceil(length / pow(2,12))
    elif width_t <= 18:
        no_brams = math.ceil(length / pow(2,11))
    elif width_t <= 36:
        no_brams = math.ceil(length / pow(2,10))
    elif width_t <= 72:
        no_brams = math.ceil(length / pow(2,9))
    #print(f'width = {width}  no_brams = {no_brams}    no_parallel_brams = {no_parallel_brams}')
    return no_brams * no_parallel_brams

def estimate_no_luts(num_remained_prefix, mu_bitwidth, mux_bitwidth, max_mux_in):
    alpha = 0.0563115  # values of alpha, beta and gamma found by minimizing MSE compared to some actual results
    beta  = 0.16
    gamma = 0.2063719
    MU_cost_vec = num_remained_prefix * mu_bitwidth # MU cost
    MUX_cost_vec = np.power(2,mux_bitwidth)
    dec_cost_vec = max_mux_in*np.log2(max_mux_in)
    cost = MU_cost_vec * alpha   +   MUX_cost_vec * beta   +    dec_cost_vec * gamma
    return cost

