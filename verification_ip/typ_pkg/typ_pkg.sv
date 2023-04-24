package typ_pkg;
	typedef enum bit { WRITE, READ } i2c_op_t;
	typedef enum int { NULL, START, DATA, STOP } status_op_t;

	string i2c_name [i2c_op_t] = '{
		WRITE : "WRITE",
		READ : "READ"
	};

	parameter int WB_ADDR_WIDTH = 2;
   	parameter int WB_DATA_WIDTH = 8;
   	parameter int NUM_I2C_BUSSES = 1;
   	parameter int I2C_ADDR_WIDTH = 7;
   	parameter int I2C_DATA_WIDTH = 8;
endpackage