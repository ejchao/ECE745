class wb_monitor extends ncsu_component#(.T(wb_transaction));

  wb_configuration  configuration;
  virtual wb_if #(WB_ADDR_WIDTH, WB_DATA_WIDTH) bus;

  T wb_monitor_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  // wb_agent class, set_configuration function
  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  // wb_agent class, set_agent function
  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction

  // wb master_monitor
  bit [WB_ADDR_WIDTH-1:0] wb_addr;
  bit [WB_DATA_WIDTH-1:0] wb_data;
  bit we;

  virtual task run ();
      forever begin
        wb_monitor_trans = new("wb_monitor_trans");

        bus.master_monitor(wb_monitor_trans.wb_addr, 
                              wb_monitor_trans.wb_data, 
                              wb_monitor_trans.we);

        agent.nb_put(wb_monitor_trans);
        /*
        $display("wb_monitor_trans: addr = %h, data = %p, we = %x", 
                  wb_monitor_trans.wb_addr, 
                  wb_monitor_trans.wb_data, 
                  wb_monitor_trans.we);
        */
    end
  endtask

endclass
