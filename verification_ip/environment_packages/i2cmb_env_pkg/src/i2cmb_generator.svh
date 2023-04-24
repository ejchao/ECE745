class i2cmb_generator extends ncsu_component;
 // `ncsu_register_object(i2cmb_generator);

  wb_transaction wb_trans;
  i2c_transaction i2c_trans;
  i2c_transaction i2c_alt_trans[64];
  wb_agent agent_wb;
  i2c_agent agent_i2c;
  string trans_name;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual task run();
  
  // continuous read 100-131, 1 transaction with 32 bytes
  i2c_trans = new;
  i2c_trans.i2c_read_data = new[32];
  for (int i = 0; i < 32; i++) begin
    i2c_trans.i2c_read_data[i] = 100 + i;
    //$display("i2c_trans.i2c_read_data: %p", i2c_trans.i2c_read_data[i]);
  end

  // alternate read 63-0, 64 transactions with 1 byte each
  for (int i = 0; i < 64; i++) begin
    i2c_alt_trans[i] = new;
    i2c_alt_trans[i].i2c_read_data = new[1];
    i2c_alt_trans[i].i2c_read_data[0] = 63 - i;
    //$display("i2c_alt_trans.i2c_read_data: %p", i2c_alt_trans[i].i2c_read_data[0]);
  end
  
  fork // run once to finish
    begin : i2c_flow
      i2c_trans.op = WRITE; // write 0-31, condition met in i2c_driver
      agent_i2c.bl_put(i2c_trans);

      i2c_trans.op = READ; // read 100-131, condition met in i2c_driver
      agent_i2c.bl_put(i2c_trans);
  
      for (int i = 0; i < 64; i++) begin
        i2c_trans.op = WRITE; // write 64-127
        agent_i2c.bl_put(i2c_trans);
        i2c_alt_trans[i].op = READ; // read 63-0
        agent_i2c.bl_put(i2c_alt_trans[i]);
      end
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
  $display("----------------writing 0-31----------------");
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
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = i;
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

  // ****************************************************************************
  // Read 32 values from the i2c_bus
  // Return incrementing data from 100 to 131
  $display("---------------------------------------------");
  $display("---------------reading 100-131---------------");
  $display("---------------------------------------------");
  // Write byte “xxxxx100” to the CMDR. This is Start command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx100;
  agent_wb.bl_put(wb_trans);
  //$display("CMDR start");                            
  // Wait for interrupt or until DON bit of CMDR reads '1'.

  // Write byte 0x45 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '1', which means reading.
  wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'h45;
  agent_wb.bl_put(wb_trans);
  //$display("DPR slave address");
  // Write byte “xxxxx001” to the CMDR. This is Write command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx001;
  agent_wb.bl_put(wb_trans);
  //$display("CMDR write command");                 
  // Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.

  // read 31 times ending with Ack
  for (int i = 0; i < 32; i++) begin
    if (i == 31) begin
      // Write byte “xxxxx011” to the CMDR. This is Read With Nack command.
      wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx011;
      agent_wb.bl_put(wb_trans);
      //$display("read with nack i2c_read_data %p", i2c_trans.i2c_read_data);
    end
    else begin
      // Write byte “xxxxx010” to the CMDR. This is Read With Ack command.
      wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx010;
      agent_wb.bl_put(wb_trans);
      //$display("read with ack i2c_read_data %p", i2c_trans.i2c_read_data);
    end
                        
    // Wait for interrupt or until DON bit of CMDR reads '1'.
    //$display("wb_data before DPR: %p", wb_trans.wb_data);
    // Read DPR to get received byte of data.
    wb_trans.we = 0; wb_trans.wb_addr = 1;
    //$display("wb_data during DPR: %p", wb_trans.wb_data);
    agent_wb.bl_put(wb_trans);
    //$display("wb_data after DPR: %p", wb_trans.wb_data);
    //$display("i2c_read_data after DPR: %p", i2c_trans.i2c_read_data);
    //$display("DPR read data");
    //$display("generator i2c_read_data %p", i2c_trans.i2c_read_data);
  end 

  // Write byte “xxxxx101” to the CMDR. This is Stop command.
  wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx101;
  agent_wb.bl_put(wb_trans);
  //$display("CMDR stop");                          
  // Wait for interrupt or until DON bit of CMDR reads '1'.

  // ****************************************************************************
  // Alternate writes and reads for 64 transfers
  // Increment write data from 64 to 127
  // Decrement read data from 63 to 0
  $display("--------------------------------------------");
  $display("-------------alternating values-------------");
  $display("--------------------------------------------");

  for (int i = 0; i < 64; i++) begin
    // Write 64 to 127
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
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 64 + i;
    agent_wb.bl_put(wb_trans);

    // Write byte “xxxxx001” to the CMDR. This is Write command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx001;
    agent_wb.bl_put(wb_trans);
                        
    // Wait for interrupt or until DON bit of CMDR reads '1'.

    // Write byte “xxxxx101” to the CMDR. This is Stop command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx101;
    agent_wb.bl_put(wb_trans);
                          
    // Wait for interrupt or until DON bit of CMDR reads '1'.

    // Read 63 to 0
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

  function void set_agent(wb_agent agent_wb, i2c_agent agent_i2c);
    this.agent_wb = agent_wb;
    this.agent_i2c = agent_i2c;
  endfunction

endclass
