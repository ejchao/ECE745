class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration configuration;
  	
	bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
	i2c_op_t i2c_op;
	bit [I2C_DATA_WIDTH-1:0] i2c_data;

  covergroup i2c_transaction_cg;

  	i2c_addr : coverpoint i2c_addr {bins used [1] = {34};}
  	i2c_op : coverpoint i2c_op {
      bins read_op = {READ};
      bins write_op = {WRITE};
    }
    i2c_data : coverpoint i2c_data {bins ranges [4] = {[0:255]};}
  	addr_x_op : cross i2c_addr, i2c_op;

  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    i2c_transaction_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    i2c_addr = trans.i2c_addr;
  	i2c_op = trans.op;
    for (int i = 0; i < trans.i2c_write_data.size(); i++) begin
      i2c_data = trans.i2c_write_data[i];
    end
    i2c_transaction_cg.sample();
  endfunction

endclass
