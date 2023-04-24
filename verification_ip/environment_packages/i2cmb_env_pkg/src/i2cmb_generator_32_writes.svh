class i2cmb_generator_32_writes extends i2cmb_generator;
  `ncsu_register_object(i2cmb_generator_32_writes);
  
  wb_transaction wb_trans;
  i2c_transaction i2c_trans;

  //rand bit [7:0] random_write[32];
  //constraint write_array { foreach(random_write[i]) random_write[i] inside {[0:31]}; } // 32 random writes limited within 0 to 31

  bit [7:0] random_write;

  function new(string name="", ncsu_component_base parent=null);
			super.new(name, parent);
  endfunction 

  virtual task run();

  // --------------------------------------------
  // test plan 5.2 : Random Write
  // write 32 random bytes to i2c slave

  i2c_trans = new;

  fork // run once to finish
    begin : i2c_flow
      i2c_trans.op = WRITE; // write random values, condition met in i2c_driver
      agent_i2c.bl_put(i2c_trans);
    end
  join_none

  // ****************************************************************************
  // Setup DUT
  wb_trans = new;

  // Write byte “1xxxxxxx” to the CSR register. This sets bit E to '1', enabling the core.
  wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'b11xxxxxx;
  agent_wb.bl_put(wb_trans);

  // Write byte 0x05 to the DPR. This is the ID of desired I2C bus.
  wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'h05;
  agent_wb.bl_put(wb_trans);

  // Write byte “xxxxx110” to the CMDR. This is Set Bus command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx110;
  agent_wb.bl_put(wb_trans);

  // Wait for interrupt or until DON bit of CMDR reads '1'.

  // ****************************************************************************
  // Write 32 incrementing values, from 0 to 31, to the i2c bus
  $display("--------------------------------------------");
  $display("----------------random writes---------------");
  $display("--------------------------------------------");

  // Write byte “xxxxx100” to the CMDR. This is Start command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx100;
  agent_wb.bl_put(wb_trans);

  // Wait for interrupt or until DON bit of CMDR reads '1'.

  // Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '0', which means writing.
  wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'h44;
  agent_wb.bl_put(wb_trans);

  // Write byte “xxxxx001” to the CMDR. This is Write command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx001;
  agent_wb.bl_put(wb_trans);

  // Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.

  // write 0 to 31 into DPR 
  for (int i = 0; i < 32; i++) begin
    // Write byte 0x-- to the DPR. This is the byte to be written.
    random_write = $random;
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = random_write; 
    agent_wb.bl_put(wb_trans);

    // Write byte “xxxxx001” to the CMDR. This is Write command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx001;
    agent_wb.bl_put(wb_trans);		

    // Wait for interrupt or until DON bit of CMDR reads '1'.
  end

  // Write byte “xxxxx101” to the CMDR. This is Stop command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx101;
  agent_wb.bl_put(wb_trans);								                
  // Wait for interrupt or until DON bit of CMDR reads '1'.

  endtask

endclass
