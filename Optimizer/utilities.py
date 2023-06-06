import math 

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