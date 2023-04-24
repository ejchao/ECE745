class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

  ncsu_component#(.T(i2c_transaction)) scoreboard;
  i2c_transaction transport_trans;
  i2cmb_env_configuration configuration;

  bit [I2C_DATA_WIDTH-1:0] write_data[$];
  bit [I2C_DATA_WIDTH-1:0] read_data[$];
  bit [1:0] state;
  parameter [1:0] start_state       = 2'b00,
		              addr_state        = 2'b01,
                  write_state       = 2'b10,
                  read_state        = 2'b11;

  bit [I2C_DATA_WIDTH-1:0] dpr_reg;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void set_scoreboard(ncsu_component #(.T(i2c_transaction)) scoreboard);
      this.scoreboard = scoreboard;
  endfunction

  virtual function void nb_put(T trans);

  // sets address and r/w bit
  if(trans.wb_addr == 1 && trans.we == 1) begin
    dpr_reg = trans.wb_data;
  end

  case(state)
    start_state: // check for start command
      begin // Write byte “xxxxx100” to the CMDR. This is Start command
        //$display("start state");
        if(trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b100 && trans.we == 1) begin
          state = addr_state;
        end
      end
    addr_state: // check for address, first 8 bits are address and r/w bit 
      begin
        //$display("address state");
        if(trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b001 && trans.we == 1) begin
          transport_trans = new;
          //$display("dpr_reg in predictor: %h", dpr_reg);
          transport_trans.i2c_addr = dpr_reg[7:1];
          //$display("dpr_reg[7:1] address %h", dpr_reg[7:1]);
          //$display("dpr_reg[0] r/w bit %p", dpr_reg[0]);
          if(!dpr_reg[0]) transport_trans.op = WRITE;
          else transport_trans.op = READ;
          if(!dpr_reg[0]) state = write_state;
          else state = read_state;
        end
      end
    write_state: // check for write bit
      begin
        //$display("write state");
        if(trans.wb_addr == 1 && trans.we == 1) begin // loop to import write byte one at a time
          write_data.push_back(dpr_reg);
          //$display("write_data queue: %p", write_data);
          state = write_state;
        end
        else if(trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b101 && trans.we == 1) begin // check for stop command
          state = start_state;
          //$display("write_data size: %p", write_data.size());
          transport_trans.i2c_compare_data = new[write_data.size()];
          foreach(transport_trans.i2c_compare_data[i]) transport_trans.i2c_compare_data[i] = write_data.pop_front(); // store into i2c_transaction variable for comparison in scoreboard
          scoreboard.nb_transport(transport_trans, null);
          write_data.delete(); // wipe out queue for next time
          //state = start_state;
        end
      end
    read_state: // check for read bit
      begin
        //$display("read state");
        if(trans.wb_addr == 1 && trans.we == 0) begin // loop to import read byte one at a time
          //$display("trans.wb_data: %p", trans.wb_data);
          read_data.push_back(trans.wb_data);
          //$display("read_data queue: %p", read_data);
          state = read_state;
        end
        else if(trans.wb_addr == 2 && trans.wb_data[2:0] == 3'b101 && trans.we == 1) begin // check for stop command
          state = start_state;
          //$display("read_data size: %p", read_data.size());
          transport_trans.i2c_compare_data = new[read_data.size()];
          foreach(transport_trans.i2c_compare_data[i]) transport_trans.i2c_compare_data[i] = read_data.pop_front(); // store into i2c_transaction variable for comparison in scoreboard
          scoreboard.nb_transport(transport_trans, null);
          read_data.delete(); // wipe out queue for next time
          //state = start_state;
        end
      end
    default:
      begin
        state = start_state;
      end
  endcase

    /*
    $display({get_full_name()," ",trans.convert2string()});
    scoreboard.nb_transport(trans, transport_trans);
    */
  endfunction

endclass
