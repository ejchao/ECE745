package i2cmb_env_pkg;
	import ncsu_pkg::*;
	import wb_pkg::*;
    import i2c_pkg::*;
	import typ_pkg::*;
	`include "ncsu_macros.svh"
	
	`include "src/i2cmb_env_configuration.svh"
	`include "src/i2cmb_coverage.svh"
	`include "src/i2cmb_scoreboard.svh"
	`include "src/i2cmb_predictor.svh"
	`include "src/i2cmb_environment.svh"
	`include "src/i2cmb_generator.svh"
	`include "src/i2cmb_generator_direct_test.svh"
	`include "src/i2cmb_generator_register_test.svh"
	`include "src/i2cmb_generator_dut_test.svh"
	`include "src/i2cmb_generator_32_reads.svh"
	`include "src/i2cmb_generator_32_writes.svh"
	`include "src/i2cmb_generator_64_alts.svh"
	`include "src/i2cmb_test.svh"
endpackage