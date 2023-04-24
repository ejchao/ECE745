class i2cmb_environment extends ncsu_component;

  i2cmb_env_configuration configuration;
  wb_agent                agent_wb;
  i2c_agent               agent_i2c;
  i2cmb_predictor         pred;
  i2cmb_scoreboard        scbd;
  i2cmb_coverage          coverage;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void build();
    agent_wb = new("wb_agent",this);
    agent_wb.set_configuration(configuration.wb_agent_config);
    agent_wb.build();
    agent_i2c = new("i2c_agent",this);
    agent_i2c.set_configuration(configuration.i2c_agent_config);
    agent_i2c.build();
    pred  = new("pred", this);
    pred.set_configuration(configuration);
    pred.build();
    scbd  = new("scbd", this);
    scbd.build();
    //coverage = new("coverage", this); 
    //coverage.set_configuration(configuration); 
    //coverage.build(); 
    //wb_agent.connect_subscriber(coverage); 
    agent_wb.connect_subscriber(pred);
    pred.set_scoreboard(scbd);
    agent_i2c.connect_subscriber(scbd);
  endfunction

  function wb_agent get_wb_agent();
    return agent_wb;
  endfunction

  function i2c_agent get_i2c_agent();
    return agent_i2c;
  endfunction

  virtual task run();
     agent_wb.run();
     agent_i2c.run();
  endtask

endclass
