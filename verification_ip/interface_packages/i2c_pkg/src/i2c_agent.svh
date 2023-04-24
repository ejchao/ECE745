class i2c_agent extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration configuration;
  i2c_driver        driver;
  i2c_monitor       monitor;
  i2c_coverage      coverage;
  ncsu_component #(T) subscribers[$];
  virtual i2c_if #(NUM_I2C_BUSSES, I2C_ADDR_WIDTH, I2C_DATA_WIDTH) bus;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    if ( !(ncsu_config_db#(virtual i2c_if #(NUM_I2C_BUSSES, I2C_ADDR_WIDTH, I2C_DATA_WIDTH))::get(get_full_name(), this.bus))) begin;
      $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      $finish;
    end
  endfunction

  // i2cmb_environment class, set_configuration function
  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  // i2cmb_environment class, build function
  virtual function void build();
    driver = new("driver",this);
    driver.set_configuration(configuration);
    driver.build();
    driver.bus = this.bus;
    
    if ( configuration.collect_coverage) begin
      coverage = new("coverage",this);
      coverage.set_configuration(configuration);
      coverage.build();
      connect_subscriber(coverage);
    end
    
    monitor = new("monitor",this);
    monitor.set_configuration(configuration);
    monitor.set_agent(this);
    monitor.enable_transaction_viewing = 1;
    monitor.build();
    monitor.bus = this.bus;
  endfunction

  // i2c_monitor class, nb_put function
  virtual function void nb_put(T trans);
    foreach (subscribers[i]) subscribers[i].nb_put(trans);
  endfunction

  // i2cmb_generator class, bl_put function
  virtual task bl_put(T trans);
    driver.bl_put(trans);
  endtask

  // i2cmb_environment class, connect_subscriber function
  virtual function void connect_subscriber(ncsu_component #(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction

  virtual task run();
     fork monitor.run(); join_none
  endtask

endclass


