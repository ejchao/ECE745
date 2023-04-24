class i2cmb_generator_direct_test extends i2cmb_generator;
  `ncsu_register_object(i2cmb_generator_direct_test);
  
  wb_transaction wb_trans;
  i2c_transaction i2c_trans;
/*
  class randomization;
    rand bit [7:0] random_read;
    constraint read_value { random_read inside {[100:131]}; } // 32 random reads limited within 100 to 131
  endclass
*/
  function new(string name="", ncsu_component_base parent=null);
			super.new(name, parent);
  endfunction 

  virtual task run();
/*
    randomization 32_reads = new();

    for (int i = 0; i < 32; i++) begin 
      32_reads.randomize();
      $display("randomized reads: %d", 32_reads.random_read);
    end
*/
  // 100% functional coverage so "unneccesary""

  endtask

endclass
