# parameters and constants
# Output file path
output_path = './HDL/mem_parameters/'
parameters_path = './mem_parameters/'
optimizer_path = './Optimizer/'
# Genetic algorithm parameters
POPULATION_SIZE = 50
TOURNOMENT_SIZE = 5
TERMINATION_COUNT = 8  # Nubmer of generations without improvement that causes termination of GA
# Misc
LOG_PRINT_EN = False
DECODER_FOR_MATCH_UNIT = True
MAX_NUM_MUX_BITS = 18
MAX_AVAILABLE_BRAMS = 100
BRAM_COSTS_TO_TEST = [200] # maximum 4 elements
PREFIX_LUT_COST = 1