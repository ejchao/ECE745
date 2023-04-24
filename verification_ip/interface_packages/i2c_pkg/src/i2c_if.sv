interface i2c_if #(
      int NUM_I2C_BUSSES = 1,
      int I2C_ADDR_WIDTH = 7,                                
      int I2C_DATA_WIDTH = 8                               
      )
(
  // System sigals
  //input tri [NUM_I2C_BUSSES-1] scl_i,
  //input tri [NUM_I2C_BUSSES-1] sda_i,
  //output tri [NUM_I2C_BUSSES-1] scl_o,
  //output tri [NUM_I2C_BUSSES-1] sda_o
  //inout triand [NUM_I2C_BUSSES-1:0] scl,
  inout triand [NUM_I2C_BUSSES-1:0] sda,
  input triand [NUM_I2C_BUSSES-1:0] scl
  //input triand [NUM_I2C_BUSSES-1:0] sda,
  //output bit [NUM_I2C_BUSSES-1:0] sda_oe
);

  import typ_pkg::*; 

  //variable declaration
  //logic slave_output = 0; //The salve will drive the SDA Line.

  bit sda_oe;
  assign sda = sda_oe ? 1'bz : 1'b0;
  //assign sda = sda_oe ? slave_output :  1'bz;
  // TASK - wait_for_i2c_transfer
  //bit [I2C_ADDR_WIDTH-1] addr_sto = 7'b0001000; // slave address
  bit [I2C_ADDR_WIDTH-1:0] addr_sda; // address from sda

  i2c_op_t op; // READ, WRITE
  bit [I2C_DATA_WIDTH-1:0] write_data [];

  bit write_queue [$];

  bit sda_bit; // sda bit transffered
  status_op_t status; // = NULL; // NULL, START, DATA, STOP
  int write_index = 0;

  // TASK - provide_read_data
  bit read_bit; // sda bit transferred
  status_op_t read_status; // = NULL; // NULL, START, DATA, STOP
  bit transfer_complete; // transfer complete bit
  int read_index; 
  int read_size; 

  // TASK - monitor
  bit [I2C_ADDR_WIDTH-1:0] addr;
  //bit [I2C_DATA_WIDTH-1:0] data[];
  status_op_t data_status; // = NULL; // NULL, START, DATA, STOP
  bit data_bit;
  int data_index = 0;

  bit monitor_queue [$];

// ****************************************************************************          
task action ( output status_op_t operation,
      output bit out_bit);

  fork
    begin: start // when SDA = 1 -> 0 while SCL = 1
      wait(scl); // wait for SCL = 1 to start
      @(negedge sda);
      if(scl) operation = START;
      //$display("Start Flag Detected at time: %0t", $realtime);
    end

    begin: data // when SCL = 0 (1 -> 0)
      @(posedge scl); // SDA constant
      out_bit = sda;
      @(negedge scl); // data can be changed
      operation = DATA;
    end

    begin: stop // when SDA = 0 -> 1 while SCL = 1
      @(posedge scl);
      @(posedge sda);
      if(scl) operation = STOP;
    end
  join_any

endtask

// ****************************************************************************
// Waits for and captures transfer start             
  task wait_for_i2c_transfer ( output i2c_op_t op, 
			output bit [I2C_DATA_WIDTH-1:0] write_data []);
  
	sda_oe = 1'b1; // start
  status = NULL;

  write_queue.delete();

  //$display("waiting for i2c");
	// wait for START conditions
	while(status != START) begin
		action(status, sda_bit);
	end

  //$display("start");
	// read in sda address (first 7 bits)
	for(int i = I2C_ADDR_WIDTH-1; i >= 0; i--) begin
		action(status, sda_bit);
		addr_sda[i] = sda_bit;
    //$display("address in i2c_if transfer: 0x%h", addr_sda);
    //$display("address bit received");
	end

  //$display("address received");
	// sda r/w
	action(status, sda_bit); // r/w is 8th bit
  /*if (sda_bit) begin op = READ;
    //$display("this is read");
  end
  else begin op = WRITE;
    //$display("this is write");
  end*/
  op = sda_bit ? READ : WRITE;
  //$display("r/w bit received");

	// acknowledge if address received is slave address
	//if(addr_sda == addr_sto) begin
		sda_oe = 1'b0;
		@(posedge scl);
		@(negedge scl);
		sda_oe = 1'b1;

    //$display("acknowledge received");
    write_data = new[1];

    if(op == WRITE) begin
      while(status != STOP) begin
        for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
          action(status, sda_bit);
          if(status == STOP) begin break;
            //$display("stop received");
          end
          write_queue.push_back(sda_bit);
          //$display("data bit received");
        end
        // acknowledge after 8 bits of data is transferred
        if(status != STOP) begin
          sda_oe = 1'b0;
		      @(posedge scl);
		      @(negedge scl);
		      sda_oe = 1'b1;

          //$display("acknowledge received");
          write_data = {>>{write_queue}};
          //write_queue.delete(); // i dont think it matters if i add this in or not?
        end
      end
      //$display("stop");
    end
  //end

  endtask        

// ****************************************************************************
// Provides data for read operation
  task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data[],
			output bit transfer_complete);
  //$display("Enter provide_read_data function. line 151");
  read_status = NULL;
  transfer_complete = 1'b0;
  read_index = 0; 
  read_size = read_data.size(); 

  //while(!transfer_complete) begin
  while(!transfer_complete) begin  
    for (int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
      sda_oe = read_data[read_index][i];
      @(posedge scl);
		  @(negedge scl);
      //$display("read data bit");
    end
    // acknowledge
    //sda_oe = 1'b0;
    //@(posedge scl);
		//@(negedge scl);
    sda_oe = 1'b1;
    //$display("acknowledge received");

    // check next bit for stop i.e. transfer is completed
    action(read_status, read_bit);
    //$display("read_status %h", read_status);
    //$display("read_bit %h", read_bit);
    /*if(read_status == STOP) begin
      transfer_complete = 1'b1;
      $display("transfer completed");
    end*/
    /*if(read_bit) begin
      $display("STOP");
      transfer_complete = 1'b1;
      //break;
    end*/
    if (!read_bit) transfer_complete = 1'b0;
    else begin
      while(read_status != STOP) begin
        action(read_status, read_bit);
        if(read_status == STOP) transfer_complete = 1'b1;
        //$display("transfer complete");
      end
    end
    read_index++; // *****
  end
  //end
  //$display("transferring");

  //$display("Leave provide_read_data function. Line 196");
  endtask

// ****************************************************************************
// Returns data observed              
  task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr,
		  output i2c_op_t op,
			output bit [I2C_DATA_WIDTH-1:0] data[]);
  
  //$display("Enter monitor at line 217");

  data_status = NULL;
  monitor_queue.delete();

  while(data_status != START) begin
    action(data_status, data_bit);
  end

  for(int i = I2C_ADDR_WIDTH-1; i >= 0; i--) begin
    action(data_status, data_bit);
    addr[i] = data_bit;
  end
  //$display("address in i2c_if monitor: 0x%h", addr);

  action(data_status, data_bit);
  op = data_bit ? READ : WRITE;

	@(posedge scl);
	@(negedge scl);

  data = new[1];

  //$display("data_status at line 227: %h", data_status);

  while(data_status != STOP) begin
    for(int i = I2C_DATA_WIDTH-1; i >= 0; i--) begin
      action(data_status, data_bit);
      //$display("data_status at line 232: %h", data_status);
      if(data_status == STOP) break;
      monitor_queue.push_back(data_bit);
    end
    //$display("data byte at line 240 %p", monitor_queue);
    if(data_status != STOP) begin
		  @(posedge scl);
		  @(negedge scl);

      data = {>>{monitor_queue}};
      //$display("data in the monitor task: %p at line 260", data);
      //monitor_queue.delete();
    end
  end
  //$display("leave monitor at line 265.");
  endtask 

endinterface
