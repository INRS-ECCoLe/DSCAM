set file_list {
                ../mem_parameters/Parameters.vhd
                ../Definitions.vhd
                ../Encoder.vhd
                ../Decoder.vhd
                ../ConstMemory.vhd
                ../BitmapAddrCalc.vhd
                ../Lookup_Engine.vhd
                ../IP_address_lookup.vhd
                ../TB_IP_address_lookup.vhd
}

# 1) Create a work directory for modelsim
# vlib ./work

foreach file $file_list {
    vcom -93 $file
}

# 2) Compile stuff in defined use order


# 3) Use ipsplitbucket entity for simulates
vsim TB_IP_address_lookup 

# 4) Open some windows for viewing results
view wave

# 5) Open some windows for viewing results
add wave -position insertpoint sim:/tb_ip_address_lookup/IP_LOOKUP/*
add wave -divider -height 30 " LOOKUP ENGINE 1 "
add wave -position insertpoint sim:/tb_ip_address_lookup/IP_LOOKUP/GENERATE_LOOKUP_ENGINE(1)/LU_ENGINE/*

# 6) Run commands
run 200ns
WaveRestoreZoom {0 fs} {200 ns}