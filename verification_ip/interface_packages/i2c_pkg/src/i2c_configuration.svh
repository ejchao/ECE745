class i2c_configuration extends ncsu_configuration;
  
  rand bit [5:0] min_delay;
  rand bit [5:0] max_delay;
  rand bit       sop_eop_polarity;
  bit            enable;
  bit            collect_coverage;

  constraint delay_range_c { min_delay < max_delay; }

  covergroup i2c_configuration_cg;
  	option.per_instance = 1;
  	option.name = name;
  	coverpoint min_delay;
  	coverpoint max_delay;
  	coverpoint sop_eop_polarity;
  endgroup

  function void sample_coverage();
  	i2c_configuration_cg.sample();
  endfunction
  
  function new(string name=""); 
    super.new(name);
    i2c_configuration_cg = new;
  endfunction

  virtual function string convert2string();
     return {super.convert2string};
  endfunction

endclass
