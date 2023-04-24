class wb_coverage extends ncsu_component#(.T(wb_transaction));

  wb_configuration configuration;

	bit [WB_ADDR_WIDTH-1:0] wb_addr;
	bit [WB_DATA_WIDTH-1:0] wb_data;
	bit wb_we;

  covergroup wb_transaction_cg;

  	wb_addr : coverpoint wb_addr {
      bins CSR_addr = {0};
      bins DPR_addr = {1};
      bins CMDR_addr = {2};
      bins FSMR_addr = {3}; 
    }
  	wb_data : coverpoint wb_data {bins ranges [4] = {[0:255]};} // no need to test each data point 
  	wb_we : coverpoint wb_we {
      bins read_we = {0};
      bins write_we = {1};
    }
  	addr_x_we : cross wb_addr, wb_we; 

  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    wb_transaction_cg = new;
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    wb_addr = trans.wb_addr;
  	wb_data = trans.wb_data;
  	wb_we = trans.we; 
    wb_transaction_cg.sample();
  endfunction

endclass
