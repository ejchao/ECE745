# TEST LIST
- regress.sh should contain all test files and seeds.
- to check existing coverage, type "make view_coverage" into the cmd without the quotation marks.
- to restart for checking coverage, delete all .ucdb files then run regress.sh.
- to run regress.sh, type "make regress" into the cmd without the quotation marks.

# DIRECTORY STRUCTURE

```
+ docs/
|   |--- iicmb_mb.pdf
+ project_benches/
|   |--- lab_1/
|   |--- proj_1/
|   |--- proj_2/
|   |--- proj_3/
|   |--- proj_4/
+ verification_ip/
|   +--- environment_packages/
|   |   |--- i2cmb_env_pkg/
|   +--- interface_packages/
|   |   |--- i2c_pkg/
|   |   |--- wb_pkg/
|   |--- ncsu_pkg/
|   |--- typ_pkg/
```

# TEST PLAN 
- Register Test
	1. Register Core Reset
	2. Register Address
	3. Register Permissions
	4. Register Aliasing
	5. Register Default Values

- DUT Test
	1. Bus Busy and Capture Bit
	2. Bus ID Check
	3. Byte FSM Transitions

- I2C Coverage
	1. I2C Covergroup
	2. I2C Slave Address
	3. I2C Operation Type
	4. I2C Data Value
	5. I2C Cross Transaction

- WB Coverage
	1. WB Covergroup
	2. WB Slave Address
	3. WB Operation Type
	4. WB Data Value
	5. WB Cross Transaction
 
- Compulsory Test
	1. Random Read
	2. Random Write
	3. Random Alternate

- Code Coverage
	1. RTL Core
	2. Bit Level FSM
	3. Byte Level FSM

- Direct Test
	1. THIS TEST IS NOT UTILIZED SO IGNORE i2cmb_generator_direct_test IN i2cmb_env_pkg
