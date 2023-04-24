class i2cmb_generator_64_alts extends i2cmb_generator;
  `ncsu_register_object(i2cmb_generator_64_alts);
  
  wb_transaction wb_trans;
  i2c_transaction i2c_trans;
  i2c_transaction i2c_alt_trans[64];

  //rand bit [7:0] random_alt_write[64];
  //constraint alt_write_array { foreach(random_alt_write[i]) random_alt_write[i] inside {[64:127]}; } // 64 random writes limited within 64 to 127

  //rand bit [7:0] random_alt_read[64];
  //constraint alt_read_array { foreach(random_alt_read[i]) random_alt_read[i] inside {[0:63]}; } // 64 random reads limited within 0 to 63

  bit [7:0] alt_read;
  bit [7:0] alt_write;

  function new(string name="", ncsu_component_base parent=null);
			super.new(name, parent);
  endfunction 

  virtual task run();

  // --------------------------------------------
  // test plan 5.3 : Random Alternate
  // alternate read/write 64 random bytes from/to i2c slave

  i2c_trans = new;

  // alternate random reads, 64 transactions with 1 byte each
  for (int i = 0; i < 64; i++) begin
    i2c_alt_trans[i] = new;
    i2c_alt_trans[i].i2c_read_data = new[1];
    alt_read = $random;
    i2c_alt_trans[i].i2c_read_data[0] = alt_read;
  end
  
  fork // run once to finish
    begin : i2c_flow
      for (int i = 0; i < 64; i++) begin
        i2c_trans.op = WRITE; // random writes between 64 and 127
        agent_i2c.bl_put(i2c_trans);
        i2c_alt_trans[i].op = READ; // random reads between 0 and 63
        agent_i2c.bl_put(i2c_alt_trans[i]);
      end
    end
  join_none

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

  // ****************************************************************************
  // Alternate writes and reads for 64 transfers
  // Random writes between 64 and 127
  // Random reads between 0 and 63
  $display("--------------------------------------------");
  $display("-------------alternating values-------------");
  $display("--------------------------------------------");

  for (int i = 0; i < 64; i++) begin
    // Random writes
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
  
    // Write byte 0x-- to the DPR. This is the byte to be written.
    alt_write = $random;
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = alt_write;
    agent_wb.bl_put(wb_trans);

    // Write byte “xxxxx001” to the CMDR. This is Write command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx001;
    agent_wb.bl_put(wb_trans);
                        
    // Wait for interrupt or until DON bit of CMDR reads '1'.

    // Write byte “xxxxx101” to the CMDR. This is Stop command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx101;
    agent_wb.bl_put(wb_trans);
                          
    // Wait for interrupt or until DON bit of CMDR reads '1'.

    // Random Reads
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

    // Write byte “xxxxx011” to the CMDR. This is Read With Nack command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx011;
    agent_wb.bl_put(wb_trans);
                          
    // Wait for interrupt or until DON bit of CMDR reads '1'.

    // Read DPR to get received byte of data.
    wb_trans.we = 0; wb_trans.wb_addr = 1; 
    agent_wb.bl_put(wb_trans);

    // Write byte “xxxxx101” to the CMDR. This is Stop command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx101;
    agent_wb.bl_put(wb_trans);
                        
    // Wait for interrupt or until DON bit of CMDR reads '1'.
  end

  endtask

endclass
