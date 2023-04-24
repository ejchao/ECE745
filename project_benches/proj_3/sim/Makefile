export ECE745_PROJECT_HOME ?= $(PWD)/../../..

GEN_TRANS_TYPE ?= i2cmb_generator_register_test
TEST_SEED ?= 12345

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/typ_pkg/Makefile

CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TRANS_TYPE); \
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

clean: 
	rm -rf work *.wlf transcript

comp_I2C_MB:
	vcom -cover bces ../rtl/iicmb_int_pkg.vhd
	vcom -cover bces ../rtl/iicmb_pkg.vhd
	vcom -cover bcesf ../rtl/mbyte.vhd
	vcom -cover bcesf ../rtl/mbit.vhd
	vcom -cover bces ../rtl/bus_state.vhd
	vcom -cover bces ../rtl/filter.vhd
	vcom -cover bces ../rtl/conditioner.vhd
	vcom -cover bces ../rtl/conditioner_mux.vhd
	vcom -cover bces ../rtl/iicmb_m.vhd
	vcom -cover bces ../rtl/regblock.vhd
	vcom -cover bces ../rtl/wishbone.vhd
	vcom -cover bces ../rtl/iicmb_m_wb.vhd


comp_bench: comp_typ_pkg comp_ncsu_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg
	vlog -cover bcesf ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

run_cli:
	vsim -c -coverage -sv_seed $(TEST_SEED) $(CLI_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim -coverage -sv_seed $(TEST_SEED) $(DEBUG_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

debug: clean compile optimize run_gui

merge_coverage:
	xml2ucdb -format Excel ./test_plan_layered_testbench.xml ./test_plan_layered_testbench.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 

regress:
	./regress.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb


