vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/blk_mem_gen_v8_4_5
vlib modelsim_lib/msim/xil_defaultlib

vmap blk_mem_gen_v8_4_5 modelsim_lib/msim/blk_mem_gen_v8_4_5
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work blk_mem_gen_v8_4_5  -incr -mfcu  \
"../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -incr -mfcu  \
"../../../../../NES_CPU.gen/sources_1/ip/Test_ROM_v2/sim/Test_ROM_v2.v" \


vlog -work xil_defaultlib \
"glbl.v"

