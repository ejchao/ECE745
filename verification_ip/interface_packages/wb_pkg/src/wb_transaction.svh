class wb_transaction extends ncsu_transaction;
  `ncsu_register_object(wb_transaction)

  bit [WB_ADDR_WIDTH-1:0] wb_addr;
  bit [WB_DATA_WIDTH-1:0] wb_data, temp; 
  bit we;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return {super.convert2string(),$sformatf("wb_address:0x%x wb_data:0x%x write enable:0x%x", wb_addr, wb_data, we)};
  endfunction

  // i2cmb_predictor and i2cmb_scoreboard classes, compare function
  function bit compare(wb_transaction rhs);
    return ((this.wb_addr  == rhs.wb_addr ) && 
            (this.wb_data == rhs.wb_data) &&
            (this.we == rhs.we) );
  endfunction

endclass
