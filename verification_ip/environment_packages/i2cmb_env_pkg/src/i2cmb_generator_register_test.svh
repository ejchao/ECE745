class i2cmb_generator_register_test extends i2cmb_generator;
  `ncsu_register_object(i2cmb_generator_register_test);
  
  wb_transaction wb_trans;
  //i2c_transaction i2c_trans;

  // [0] = CSR, [1] = DPR, [2] = CMDR, [3] = FSMR

  bit [WB_DATA_WIDTH-1:0] pre_core[4]; // test plan 1.5
  bit [WB_DATA_WIDTH-1:0] post_core[4]; // test plan 1.1
  bit [WB_DATA_WIDTH-1:0] post_write[4]; // test plan 1.4

  function new(string name="", ncsu_component_base parent=null);
			super.new(name, parent);
  endfunction 

  virtual task run();

    $display("-----------------------------------");
    $display("     TEST PLAN 1: REGISTER TEST"    );
    $display("-----------------------------------");

    // --------------------------------------------
    // test plan 1.2 : Register Address
    // refer to all other test cases

    // --------------------------------------------
    // test plan 1.5 : Register Default Values
    // registers should have default values before enabling core

    $display("______TEST PLAN 1.5: REGISTER DEFAULT VALUES______");

    wb_trans = new;

    // default register values before enabling core
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    pre_core[0] = wb_trans.wb_data;
    //$display("PRE CORE CSR DATA: %b", pre_core[0]);

    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    pre_core[1] = wb_trans.wb_data;
    //$display("PRE CORE DPR DATA: %b", pre_core[1]);

    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    pre_core[2] = wb_trans.wb_data;
    //$display("PRE CORE CMDR DATA: %b", pre_core[2]);

    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    pre_core[3] = wb_trans.wb_data;
    //$display("PRE CORE FSMR DATA: %b", pre_core[3]);

    if(pre_core[0] == 8'b00000000 &&
      pre_core[1] == 8'b00000000 &&
      pre_core[2] == 8'b10000000 &&
      pre_core[3] == 8'b00000000) $display("TEST PLAN 1.5 PASS");
    else $display("test plan 1.5 fail");

    // --------------------------------------------
    // test plan 1.1 : Register Core Reset
    // DPR, CMDR, and FSMR registers should reset to default after enabling core

    $display("______TEST PLAN 1.1: REGISTER CORE RESET______");

    wb_trans = new;

    // enable core
    wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'b11xxxxxx;
    agent_wb.bl_put(wb_trans);

    // read register values before writing
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_core[0] = wb_trans.wb_data;
    //$display("POST CORE CSR DATA: %b", post_core[0]);

    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_core[1] = wb_trans.wb_data;
    //$display("POST CORE DPR DATA: %b", post_core[1]);

    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_core[2] = wb_trans.wb_data;
    //$display("POST CORE CMDR DATA: %b", post_core[2]);

    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_core[3] = wb_trans.wb_data;
    //$display("POST CORE FSMR DATA: %b", post_core[3]);

    if(post_core[0] == 8'b11000000 &&
      post_core[1] == 8'b00000000 &&
      post_core[2] == 8'b10000000 &&
      post_core[3] == 8'b00000000) $display("TEST PLAN 1.1 PASS");
    else $display("test plan 1.1 fail");

    // --------------------------------------------
    // test plan 1.4 : Register Aliasing
    // writing to 1 register should not affect the others

    $display("______TEST PLAN 1.4: REGISTER ALIASING______");

    wb_trans = new;

    // write to CSR
    // r/w bit = 1 so [7] and [6] = 1
    // no idle state in predictor so [5] = 1
    // CSR starts at 8'b1110_0000 after writing 8'hff to it
    wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    // check registers after writing
    // DPR starts at 8'b0000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_write[1] = wb_trans.wb_data;
    //$display("POST WRITE DPR DATA: %b", post_write[1]); 

    // CMDR starts at 8'b1000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_write[2] = wb_trans.wb_data;
    //$display("POST WRITE CMDR DATA: %b", post_write[2]);

    // FSMR starts at 8'b0000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_write[3] = wb_trans.wb_data;
    //$display("POST WRITE FSMR DATA: %b", post_write[3]); 

    if(post_write[1] == 8'b00000000 &&
      post_write[2] == 8'b10000000 &&
      post_write[3] == 8'b00000000) $display("TEST PLAN 1.4 CSR PASS");
    else $display("test plan 1.4 CSR fail");

    // write to DPR
    // DPR returns last sent byte but there was no last byte [7:0] = 0
    // DPR should be 8'b0000_0000 after writing 8'hff to it
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    // check registers after writing
    // CSR should be 8'b1110_0000
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_write[0] = wb_trans.wb_data;
    //$display("POST WRITE CSR DATA: %b", post_write[0]); //

    // CMDR should be 8'b1000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_write[2] = wb_trans.wb_data;
    //$display("POST WRITE CMDR DATA: %b", post_write[2]); 

    // FSMR should be 8'b0000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_write[3] = wb_trans.wb_data;
    //$display("POST WRITE FSMR DATA: %b", post_write[3]); 

    if(post_write[0] == 8'b11100000 &&
      post_write[2] == 8'b10000000 &&
      post_write[3] == 8'b00000000) $display("TEST PLAN 1.4 DPR PASS");
    else $display("test plan 1.4 DPR fail");

    // write to CMDR
    // writing 8'hff into CMDR causes arbitration error at [5] = 1
    // writing 8'hff into CMDR makes bits [2:0] = 1
    // CMDR should be 8'b0010_1110 after writing 8'hff to it
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    // check registers after writing
    // CSR should be 8'b1110_0000
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_write[0] = wb_trans.wb_data;
    //$display("POST WRITE CSR DATA: %b", post_write[0]); 

    // DPR should be 8'b0000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_write[1] = wb_trans.wb_data;
    //$display("POST WRITE DPR DATA: %b", post_write[1]); 

    // FSMR should be 8'b0000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 3;
    agent_wb.bl_put(wb_trans);
    post_write[3] = wb_trans.wb_data;
    //$display("POST WRITE FSMR DATA: %b", post_write[3]); 

    if(post_write[0] == 8'b11100000 &&
      post_write[1] == 8'b00000000 &&
      post_write[3] == 8'b00000000) $display("TEST PLAN 1.4 CMDR PASS");
    else $display("test plan 1.4 CMDR fail");

    // write to FSMR
    // writing 8'hff into FSMR doesn't change anything [7:0] = 0
    // FSMR should be 8'b0000_0000 after writing 8'hff to it
    wb_trans.we = 1; wb_trans.wb_addr = 3; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);

    // check registers after writing
    // CSR should be 8'b1110_0000
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    post_write[0] = wb_trans.wb_data;
    //$display("POST WRITE CSR DATA: %b", post_write[0]);

    // DPR should be 8'b0000_0000
    wb_trans.we = 0; wb_trans.wb_addr = 1;
    agent_wb.bl_put(wb_trans);
    post_write[1] = wb_trans.wb_data;
    //$display("POST WRITE DPR DATA: %b", post_write[1]);

    // CMDR should be 8'b0001_0111
    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    post_write[2] = wb_trans.wb_data;
    //$display("POST WRITE CMDR DATA: %b", post_write[2]);

    if(post_write[0] == 8'b11100000 &&
      post_write[1] == 8'b00000000 &&
      post_write[2] == 8'b00010111) $display("TEST PLAN 1.4 FSMR PASS");
    else $display("test plan 1.4 FSMR fail");

    // --------------------------------------------
    // test plan 1.3 : Register Permissions 
    // access permissions for CSR and DPR should follow specifications

    $display("______TEST PLAN 1.3: REGISTER PERMISSIONS______");

    wb_trans = new; 

    // CSR access test
    // r/w bit = 1 so [7] and [6] = 1
    // no idle state in predictor so [5] = 1
    wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);
    wb_trans.we = 0;
    agent_wb.bl_put(wb_trans);
    //$display("wb_data: %b", wb_trans.wb_data);

    if(wb_trans.wb_data == 8'b11100000) $display("TEST PLAN 1.3 CSR PASS");
    else $display("test plan 1.3 CSR fail");

    // DPR access test
    // DPR returns last sent byte but there was no last byte [7:0] = 0
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'hff;
    agent_wb.bl_put(wb_trans);
    wb_trans.we = 0;
    agent_wb.bl_put(wb_trans);
    //$display("wb_data: %b", wb_trans.wb_data);

    if(wb_trans.wb_data == 8'b00000000) $display("TEST PLAN 1.3 DPR PASS");
    else $display("test plan 1.3 DPR fail");

  endtask

endclass
