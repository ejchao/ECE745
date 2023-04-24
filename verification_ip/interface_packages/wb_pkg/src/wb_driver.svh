class wb_driver extends ncsu_component#(.T(wb_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH) bus;
  wb_configuration configuration;
  wb_transaction wb_trans;

  // wb_agent class, set_configuration function
  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

// wb_agent class, bl_put function
  virtual task bl_put(T trans);
    if(trans.we) bus.master_write(trans.wb_addr, trans.wb_data);
    if(!trans.we) bus.master_read(trans.wb_addr, trans.wb_data); //$display("wb_data from wb_driver: %p", trans.wb_data);
    if((trans.we) && (trans.wb_addr == 2)) begin
      //$display("wait_for_interrupt");
      bus.wait_for_interrupt();
      bus.master_read(2, trans.temp);
      //$display("wait_for_interrupt done");
      
    end
    
  endtask

endclass
