class i2cmb_env_configuration extends ncsu_configuration;

  bit       loopback;
  bit       invert;
  bit [3:0] port_delay;

  covergroup env_configuration_cg;
  	option.per_instance = 1;
    option.name = name;
  	coverpoint loopback;
  	coverpoint invert;
  	coverpoint port_delay;
  endgroup

  function void sample_coverage();
  	env_configuration_cg.sample();
  endfunction
  
  wb_configuration wb_agent_config;
  i2c_configuration i2c_agent_config;

  function new(string name=""); 
    super.new(name);
    env_configuration_cg = new;
    wb_agent_config = new("wb_agent_config");
    i2c_agent_config = new("i2c_agent_config");
    i2c_agent_config.collect_coverage=1;
    wb_agent_config.collect_coverage=1;  
    wb_agent_config.sample_coverage();
    i2c_agent_config.sample_coverage();
  endfunction

endclass
