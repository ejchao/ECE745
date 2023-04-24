class i2cmb_generator_dut_test extends i2cmb_generator;
  `ncsu_register_object(i2cmb_generator_dut_test);

  wb_transaction wb_trans;
  i2c_transaction i2c_trans;

  bit [WB_DATA_WIDTH-1:0] valid_bus = 8'h10; // 0001_0000
  bit [WB_DATA_WIDTH-1:0] invalid_bus = 8'h02; // 0000_0010

  function new(string name="", ncsu_component_base parent=null);
			super.new(name, parent);
  endfunction

  virtual task run();

    $display("-----------------------------------");
    $display("       TEST PLAN 2: DUT TEST"       );
    $display("-----------------------------------");

    // --------------------------------------------
    // test plan 2.3 : Byte FSM Transitions
    // refer to all other test cases

    i2c_trans = new;
    i2c_trans.op = WRITE; // write

    fork agent_i2c.bl_put(i2c_trans); join_none

    // --------------------------------------------
    // test plan 2.1 : Bus Busy and Bit Capture
    // check BB and BC before start command

    // BB [5]: '0' = bus is idle, '1' = bus is busy
    // BC [4]: '0' = bus isn't captured by IICMB, '1' = bus is captured by IICMB

    $display("______TEST PLAN 2.1: BUS BUSY AND BIT CAPTURE______");

    wb_trans = new;

    // enable core
    wb_trans.we = 1; wb_trans.wb_addr = 0; wb_trans.wb_data = 8'b11xxxxxx;
    agent_wb.bl_put(wb_trans);

    // read out of CSR
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    //$display("CSR start data: %b", wb_trans.wb_data);

    if(!wb_trans.wb_data[5]) $display("TEST PLAN 2.1 BB START PASS");
    else $display("test plan 2.1 BB start fail");

    if(!wb_trans.wb_data[4]) $display("TEST PLAN 2.1 BC START PASS");
    else $display("test plan 2.1 BC start fail");

    // --------------------------------------------
    // test plan 2.2 : Bus ID Check
    // check if DUT responds to a valid bus number through CMDR

    // DON [7]: '1' = command completed normally

    $display("______TEST PLAN 2.2: BUS ID VALID______");

    // write desired bus ID into DPR
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = valid_bus;
    agent_wb.bl_put(wb_trans);

    // set bus command through CMDR
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx110;
    agent_wb.bl_put(wb_trans);
    
    // read out of CMDR
    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    //$display("CMDR valid bus data: %b", wb_trans.wb_data);

    if(wb_trans.wb_data[7]) $display("TEST PLAN 2.2 VALID ID PASS");
    else $display("test plan 2.2 valid fail");

    // CMDR start command
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx100;
    agent_wb.bl_put(wb_trans);

    // Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '0', which means writing.
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = 8'h44;
    agent_wb.bl_put(wb_trans);
  
    // Write byte “xxxxx001” to the CMDR. This is Write command.
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx001;
    agent_wb.bl_put(wb_trans);	

    // --------------------------------------------
    // test plan 2.1 : Bus Busy and Bit Capture
    // check BC freed after stop command

    // BC [4]: '0' = bus isn't captured by IICMB, '1' = bus is captured by IICMB
    
    $display("______TEST PLAN 2.1: BIT CAPTURE FREED______");

    // CMDR stop command
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx101;
    agent_wb.bl_put(wb_trans);

    // read out of CSR
    wb_trans.we = 0; wb_trans.wb_addr = 0;
    agent_wb.bl_put(wb_trans);
    //$display("CSR stop data: %b", wb_trans.wb_data);

    if(!wb_trans.wb_data[4]) $display("TEST PLAN 2.1 BC STOP PASS");
    else $display("test plan 2.1 BC stop fail");

    // --------------------------------------------
    // test plan 2.2 : Bus ID Check
    // check if DUT responds to a invalid bus number through CMDR
    
    // ERR [4]: '1' = last command terminated with an error

    $display("______TEST PLAN 2.2: BUS ID INVALID______");

    // write desired bus ID into DPR
    wb_trans.we = 1; wb_trans.wb_addr = 1; wb_trans.wb_data = invalid_bus;
    agent_wb.bl_put(wb_trans);

    // set bus command through CMDR
    wb_trans.we = 1; wb_trans.wb_addr = 2; wb_trans.wb_data = 8'bxxxxx110;
    agent_wb.bl_put(wb_trans);
      
    // read out of CMDR
    wb_trans.we = 0; wb_trans.wb_addr = 2;
    agent_wb.bl_put(wb_trans);
    //$display("CMDR invalid bus data: %b", wb_trans.wb_data);

    if(wb_trans.wb_data[4]) $display("TEST PLAN 2.2 INVALID PASS");
    else $display("test plan 2.2 invalid fail");

  endtask

endclass
