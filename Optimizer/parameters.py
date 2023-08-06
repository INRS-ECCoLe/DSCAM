# parameters and constants
# Output file path
output_path = './HDL/mem_parameters2/'
parameters_path = './mem_parameters2/'
optimizer_path = './Optimizer/'
# Genetic algorithm parameters
POPULATION_SIZE = 20
TOURNOMENT_SIZE = 20
TERMINATION_COUNT = 6  # Nubmer of generations without improvement that causes termination of GA
# Misc
LOG_PRINT_EN = True
MAX_NUM_MUX_BITS = 18
MAX_AVAILABLE_BRAMS = 100
BRAM_COSTS_TO_TEST = [500] # maximum 4 elements