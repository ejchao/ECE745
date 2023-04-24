class i2cmb_test extends ncsu_component;

  i2cmb_env_configuration  cfg;
  i2cmb_environment        env;

  i2cmb_generator          gen;
  i2cmb_generator_direct_test direct_gen;
  i2cmb_generator_register_test register_gen;
  i2cmb_generator_dut_test  dut_gen;
  i2cmb_generator_32_reads  read_gen;
  i2cmb_generator_32_writes write_gen;
  i2cmb_generator_64_alts alt_gen;
  string test_name;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);

    if ( !$value$plusargs("GEN_TRANS_TYPE=%s", test_name)) begin
      $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
      $fatal;
    end
    $display("%m GEN_TRANS_TYPE=%s", test_name);

    cfg = new("cfg");
    //cfg.sample_coverage();
    env = new("env",this);
    env.set_configuration(cfg);
    env.build();

    // tests
    if (test_name == "i2cmb_generator_direct_test") begin
      direct_gen = new("i2cmb_generator_direct_test",this);
      direct_gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
    end
    else if (test_name == "i2cmb_generator_register_test") begin
      register_gen = new("i2cmb_generator_register_test",this);
      register_gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
    end
    else if (test_name == "i2cmb_generator_dut_test") begin
      dut_gen = new("i2cmb_generator_dut_test",this);
      dut_gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
    end
    else if (test_name == "i2cmb_generator_32_reads") begin
      read_gen = new("i2cmb_generator_32_reads",this);
      read_gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
    end
    else if (test_name == "i2cmb_generator_32_writes") begin
      write_gen = new("i2cmb_generator_32_writes",this);
      write_gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
    end
    else if (test_name == "i2cmb_generator_64_alts") begin
      alt_gen = new("i2cmb_generator_64_alts",this);
      alt_gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
    end
    else begin
      gen = new("gen",this);
      gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
    end
  endfunction

  virtual task run();
     env.run();
     if (test_name == "i2cmb_generator_direct_test") direct_gen.run();
     else if (test_name == "i2cmb_generator_register_test") register_gen.run();
     else if (test_name == "i2cmb_generator_dut_test") dut_gen.run();
     else if (test_name == "i2cmb_generator_32_reads") read_gen.run();
     else if (test_name == "i2cmb_generator_32_writes") write_gen.run();
     else if (test_name == "i2cmb_generator_64_alts") alt_gen.run();
     else gen.run();
  endtask

endclass
