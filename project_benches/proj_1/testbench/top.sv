`timescale 1ns / 10ps

module top();

import typ::*;

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
triand  [NUM_I2C_BUSSES-1:0] scl; 
triand  [NUM_I2C_BUSSES-1:0] sda; // tri or triand

bit transfer_complete = 1'b0;
int read_index = 0;
int transfer_index = 0;
int r = 100;
int t = 63;
bit transfer_bit = 1'b0;

bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
i2c_op_t i2c_op;
bit [I2C_DATA_WIDTH-1:0] i2c_data[];

// ****************************************************************************
// Clock generator
initial begin: clk_gen
	forever #5ns clk <= ~clk;
end

// ****************************************************************************
// Reset generator
initial begin: rst_gen
	#113ns rst = 1'b0;
end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript

initial begin: wb_monitoring

  bit  we_val; // master_monitor
  bit  [WB_ADDR_WIDTH-1:0] addr_val; // master_monitor
  bit  [WB_DATA_WIDTH-1:0] data_val; // master_monitor

  //forever begin
	  wb_bus.master_monitor(addr_val, data_val, we_val);
	  //$display("wb address = %h", addr_val);
	  //$display("wb data = %h", data_val);
	  //$display("wb we = %h", we_val);
  //end
end

// ****************************************************************************
// Monitor I2C bus and display transfers in the transcript
initial begin: i2c_monitoring

  //bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
  //i2c_op_t i2c_op;
  //bit [I2C_DATA_WIDTH-1:0] i2c_data[];

  forever begin
    i2c_bus.monitor(i2c_addr, i2c_op, i2c_data);
    if (i2c_op == WRITE) begin
      $display("I2C_BUS WRITE Transfer: i2c data = %p", i2c_data);
	    //$display("i2c address = %h", i2c_addr);
	    //$display("i2c operation = %h", i2c_op);
	    //$display("i2c data = %p", i2c_data);
    end
    else if (i2c_op == READ) begin
      $display("I2C_BUS READ Transfer: i2c data = %p", i2c_data);
	    //$display("i2c address = %h", i2c_addr);
	    //$display("i2c operation = %h", i2c_op);
	    //$display("i2c data = %p", i2c_data);
    end
  end
end

// ****************************************************************************
// Define the flow of the simulation
initial begin: i2c_if

  i2c_op_t op;
  bit transfer_complete;
  bit [I2C_DATA_WIDTH-1:0] write_data[];
  bit [I2C_DATA_WIDTH-1:0] read_data[];
  
  // write 0-31
  i2c_bus.wait_for_i2c_transfer(op, write_data);

  //$display("get read signal"); // read 100-131
  i2c_bus.wait_for_i2c_transfer(op, write_data);

  read_data = new[1];
  read_data[0] = 100;

  if(op) begin
    //$display("beginning read once");
    while (!transfer_complete) begin
      i2c_bus.provide_read_data(read_data, transfer_complete); // read 100-131
      read_data[0]++;
      //$display("transfer_complete %h", transfer_complete);
    end
    transfer_complete = 1'b0;
    //$display("read through once");
  end
  
  //$display("beginning transfer both ways");
  for(int i = 0; i < 64; i++) begin
    i2c_bus.wait_for_i2c_transfer(op, write_data); // write 64-127
    i2c_bus.wait_for_i2c_transfer(op, write_data); // read 63-0
    read_data[0] = 63 - i;
    //$display("read_data transfer: %p", read_data);
    i2c_bus.provide_read_data(read_data, transfer_complete); // read 63-0
  end
  //$display("transfer finish");

end

// ****************************************************************************
// Define the flow of the simulation
bit  [WB_DATA_WIDTH-1:0] readData = 0; // example 3

task interrupt();
	wait (irq); 								                // example 3 step x
	wb_bus.master_read(16'h02, readData); 		  // clear irq to move on
endtask

initial begin: wb_if
  #500ns;
	wb_bus.master_write(16'h00, 8'b11xxxxxx); 	// Write byte “1xxxxxxx” to the CSR register. This sets bit E to '1', enabling the core.
	
	wb_bus.master_write(16'h01, 8'h05); 		    // Write byte 0x05 to the DPR. This is the ID of desired I2C bus.
	wb_bus.master_write(16'h02, 8'bxxxxx110); 	// Write byte “xxxxx110” to the CMDR. This is Set Bus command.
	interrupt(); 								                // Wait for interrupt or until DON bit of CMDR reads '1'.

  // ****************************************************************************
  // Write 32 incrementing values, from 0 to 31, to the i2c bus
  // start
  wb_bus.master_write(16'h02, 8'bxxxxx100); 	// Write byte “xxxxx100” to the CMDR. This is Start command.
	interrupt(); 								                // Wait for interrupt or until DON bit of CMDR reads '1'.
	wb_bus.master_write(16'h01, 8'h44); 		    // Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '0', which means writing.
	wb_bus.master_write(16'h02, 8'bxxxxx001); 	// Write byte “xxxxx001” to the CMDR. This is Write command.
  interrupt();                                // Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.
	
  // write 0 to 31 into DPR
  for (int i = 0; i < 32; i++) begin
    wb_bus.master_write(16'h01, i);			      // Write byte 0x-- to the DPR. This is the byte to be written.
	  wb_bus.master_write(16'h02, 8'bxxxxx001); // Write byte “xxxxx001” to the CMDR. This is Write command.
	  interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.
  end
  //$display("write 0-31 done");
  // stop
	wb_bus.master_write(16'h02, 8'bxxxxx101); 	// Write byte “xxxxx101” to the CMDR. This is Stop command.
	interrupt();								                // Wait for interrupt or until DON bit of CMDR reads '1'.

  // ****************************************************************************
  // Read 32 values from the i2c_bus
  // Return incrementing data from 100 to 131
  // start
  wb_bus.master_write(16'h02, 8'bxxxxx100); 	// Write byte “xxxxx100” to the CMDR. This is Start command.
	interrupt(); 								                // Wait for interrupt or until DON bit of CMDR reads '1'.
  wb_bus.master_write(16'h01, 8'h45); 		    // Write byte 0x45 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '1', which means reading.
	wb_bus.master_write(16'h02, 8'bxxxxx001); 	// Write byte “xxxxx001” to the CMDR. This is Write command.
  interrupt();                                // Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.

  // read 31 times ending with Ack
  for (int i = 0; i < 32; i++) begin
    if (i == 31) begin
      wb_bus.master_write(16'h02, 8'bxxxxx011); // Write byte “xxxxx011” to the CMDR. This is Read With Nack command.
    end
    else begin
      wb_bus.master_write(16'h02, 8'bxxxxx010); // Write byte “xxxxx010” to the CMDR. This is Read With Ack command.
    end
    interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.
    wb_bus.master_read(16'h01, readData);     // Read DPR to get received byte of data.
  end 
  //$display("read 100-131 done");
  // stop
	wb_bus.master_write(16'h02, 8'bxxxxx101); 	// Write byte “xxxxx101” to the CMDR. This is Stop command.
	interrupt(); 								                // Wait for interrupt or until DON bit of CMDR reads '1'.
  //$display("stop");

  // ****************************************************************************
  // Alternate writes and reads for 64 transfers
  // Increment write data from 64 to 127
  // Decrement read data from 63 to 0

  for (int i = 0; i < 64; i++) begin
    // write
    wb_bus.master_write(16'h02, 8'bxxxxx100); // Write byte “xxxxx100” to the CMDR. This is Start command.
	  interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.
	  wb_bus.master_write(16'h01, 8'h44); 		  // Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '0', which means writing.
	  wb_bus.master_write(16'h02, 8'bxxxxx001); // Write byte “xxxxx001” to the CMDR. This is Write command.
    interrupt();                              // Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.

    wb_bus.master_write(16'h01, 64 + i);		  // Write byte 0x-- to the DPR. This is the byte to be written.
	  wb_bus.master_write(16'h02, 8'bxxxxx001); // Write byte “xxxxx001” to the CMDR. This is Write command.
	  interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.
    //$display("write 64-127 done");
	  wb_bus.master_write(16'h02, 8'bxxxxx101); // Write byte “xxxxx101” to the CMDR. This is Stop command.
	  interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.

    // read
    wb_bus.master_write(16'h02, 8'bxxxxx100); // Write byte “xxxxx100” to the CMDR. This is Start command.
	  interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.
    wb_bus.master_write(16'h01, 8'h45); 		  // Write byte 0x45 to the DPR. This is the slave address 0x22 shifted 1 bit to the left + rightmost bit = '1', which means reading.
	  wb_bus.master_write(16'h02, 8'bxxxxx001); // Write byte “xxxxx001” to the CMDR. This is Write command.
    interrupt();                              // Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.

    // can be Nack or Ack
    wb_bus.master_write(16'h02, 8'bxxxxx011); // Write byte “xxxxx011” to the CMDR. This is Read With Nack command.
    interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.
    wb_bus.master_read(16'h01, readData);     // Read DPR to get received byte of data.
    //$display("read 63-0 done");
	  wb_bus.master_write(16'h02, 8'bxxxxx101); // Write byte “xxxxx101” to the CMDR. This is Stop command.
	  interrupt(); 								              // Wait for interrupt or until DON bit of CMDR reads '1'.
  end

  $finish;
end

// ****************************************************************************
// Instantiate the I2C slave Bus Functional Model
i2c_if      #(
      .NUM_I2C_BUSSES(NUM_I2C_BUSSES),
      .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
      .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
      )
i2c_bus (
    //.scl_i(scl),
    //.sda_i(sda),       
    //.scl_o(scl),       
    //.sda_o(sda),
    .scl(scl),
    .sda(sda)
    //.sda_oe(sda)
    );

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


endmodule
