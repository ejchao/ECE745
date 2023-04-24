class i2cmb_generator_32_reads extends i2cmb_generator;
  `ncsu_register_object(i2cmb_generator_32_reads);
  
  wb_transaction wb_trans;
  i2c_transaction i2c_trans;

  //rand bit [7:0] random_read[32];
  //constraint read_value { foreach(random_read[i]) random_read[i] inside {[100:131]}; } // 32 random reads limited within 100 to 131

  bit [7:0] random_read;

  function new(string name="", ncsu_component_base parent=null);
			super.new(name, parent);
  endfunction 

  virtual task run();

  // --------------------------------------------
  // test plan 5.1 : Random Read
  // read 32 random bytes from i2c slave

  // continuous random read, 1 transaction with 32 bytes
  i2c_trans = new;
  i2c_trans.i2c_read_data = new[32];
  for (int i = 0; i < 32; i++) begin 
    random_read = $random;
    i2c_trans.i2c_read_data[i] = random_read;
  end

  fork // run once to finish
    begin : i2c_flow
      i2c_trans.op = READ; // read random values, condition met in i2c_driver
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
  // Read 32 values from the i2c_bus
  // Return random data between 100 and 131
  $display("---------------------------------------------");
  $display("-----------------random reads----------------");
  $display("---------------------------------------------");
  // Write byte “xxxxx100” to the CMDR. This is Start command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx100;
  agent_wb.bl_put(wb_trans);
                           
  // Wait for interrupt or until DON bit of CMDR reads '1'.

  // Write byte 0x45 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '1', which means reading.
  wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'h45;
  agent_wb.bl_put(wb_trans);

  // Write byte “xxxxx001” to the CMDR. This is Write command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx001;
  agent_wb.bl_put(wb_trans);
                
  // Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.

  // read 31 times ending with Ack
  for (int i = 0; i < 32; i++) begin
    if (i == 31) begin
      // Write byte “xxxxx011” to the CMDR. This is Read With Nack command.
      wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx011;
      agent_wb.bl_put(wb_trans);
    end
    else begin
      // Write byte “xxxxx010” to the CMDR. This is Read With Ack command.
      wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx010;
      agent_wb.bl_put(wb_trans);
    end
                        
    // Wait for interrupt or until DON bit of CMDR reads '1'.

    // Read DPR to get received byte of data.
    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
  end 

  // Write byte “xxxxx101” to the CMDR. This is Stop command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx101;
  agent_wb.bl_put(wb_trans);

  // Wait for interrupt or until DON bit of CMDR reads '1'.

  endtask

endclass
