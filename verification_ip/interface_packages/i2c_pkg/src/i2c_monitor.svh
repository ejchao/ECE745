class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration  configuration;
  virtual i2c_if #(NUM_I2C_BUSSES, I2C_ADDR_WIDTH, I2C_DATA_WIDTH) bus;

  T i2c_monitor_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  // i2c_agent class, set_configuration function
  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  // i2c_agent class, set_agent function
  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction

  // i2c monitor
  virtual task run ();
      forever begin
        i2c_monitor_trans = new("i2c_monitor_trans");

        bus.monitor(i2c_monitor_trans.i2c_addr, 
                        i2c_monitor_trans.op, 
                        i2c_monitor_trans.i2c_write_data); // i2c_compare_data

        agent.nb_put(i2c_monitor_trans); 
        /*               
        $display("i2c_monitor_trans: addr = 0x%x, op = %x, data = %p", 
                  i2c_monitor_trans.i2c_addr, 
                  i2c_monitor_trans.op, 
                  i2c_monitor_trans.i2c_write_data);
        */
    end
  endtask

endclass
