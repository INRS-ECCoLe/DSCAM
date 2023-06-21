# Directly Synthesized Content Addressable Memory (DSCAM)

## Table of contents
* [General Info](#general-info)
* [Technologies](#technologies)
* [Requirements](#Requirements)
* [User Instruction](#user-instruction)

## General Info
DSCAM (Directly Synthesized Content-Addressable Momory) is an innovative latency-guaranteed and high-throughput content-addressable memory architecture for FPGA platforms. It is the first work that allows implementation of very large CAM/TCAM memories on buget-friendly FPGAs. In herent reconfigurability of FPGAs, guaranteed fast search speed and suppoprt of large forwarding tables make SDCAM a suitable choice to replace TCAMs in SDN-enabled data planes. DSCAM does not require offchip memory access and allows user-adjustable trade-off between BRAM and logic resourse utilization. The experimental results show that the proposed method enables the implementation of an IPv4 forwarding table with over 520k prefixes on a xcku5p AMD/XILINX Kintex UltraScale+ FPGA, providing a lookup latency of less than 29ns and a throughput of 212 million lookups per second.

DSCAM project includes:
1- Hardware architecture templates, in .\HDL folder;
2- A genetic algorithm-based optimizer, in .\Optimizer folder, which generates a content-specific configuration files for the hardware architecture   
	
## Technologies
Project is created with:
* Python 3.10
* VHDL 2008
	
## Requirements
```
$ pip install numpy bitarray
$ pip install matplotlib
```

## User Instruction
DSCAM uses a GA-base optimizer to automatically generate a well-tailored hardware architecture for the given target search table.  
The optimizer has two modes of usage:

### 1- Default hardware core generation mode: 
In this mode, the optimizer searches for the best hardware core configuration for the given search table using design space exploration. The user needs to assign the path of the target search content file to prefix_file_name variable in .\Optimizer\main.py and run main.py without any argument.
```
$ python .\Optimizer\main.py
```
The best-found solution in each generation of the GA algorithm is printed and after termination, the convergence plot is shown. The generated configuration file includes all memory content files, the reordered content file and parameters.vhd file containing all generated parameter values for the hardware core will be generated in .\HDL\mem_parameters folder. To simulate and synthesize, all VHDL files in the .\HDL folder and .\HDL\parameters.h must be added to the project.
The design parameters can be adjusted in .\Optimization\parameters.py. This includes GA algorithm parameters and the important parameter of BRAM_COSTS_TO_TEST that defines the cost of BRAM resources compared to the logic resources in the cost function of the GA. Users can adjust the balance between BRAM and logic utilization in the hardware core based on their design priorities using this parameter. Assigning a higher value to BRAM_COSTS_TO_TEST signifies that BRAMs are more expensive resources. As a result, GA will likely find solutions that use less BRAM resources and more logic.

### 2- Plot mode: 
This mode is used for better visualization of GA explored solotion space and convergence projectile. This mode plots the estimated BRAM and logic utilization of all examined candidate solutions (chromosomes) during GA operation.
To run in this mode, user must specify the target search content file in .\Optimizer\main.py and run main.py with plot_all argument.
```
$ python .\Optimizer\main.py plot_all
```
![Plot all](Docs/Figure_23bit_200_1000_1500.png)