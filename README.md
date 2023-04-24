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
|	+--- environment_packages/
|   |   |--- i2cmb_env_pkg/
|	+--- interface_packages/
|   |   |--- i2c_pkg/
|   |   |--- wb_pkg/
|   |--- ncsu_pkg/
|   |--- typ_pkg/
```

# TEST PLAN 
- 1. Register Test
	1.1 Register Core Reset
	1.2 Register Address
	1.3 Register Permissions
	1.4 Register Aliasing
	1.5 Register Default Values

- 2. DUT Test
	2.1 Bus Busy and Capture Bit
	2.2 Bus ID Check
	2.3 Byte FSM Transitions

- 3. I2C Coverage
	3.1 I2C Covergroup
	3.2 I2C Slave Address
	3.3 I2C Operation Type
	3.4 I2C Data Value
	3.5 I2C Cross Transaction

- 4. WB Coverage
	4.1 WB Covergroup
	4.2 WB Slave Address
	4.3 WB Operation Type
	4.4 WB Data Value
	4.5 WB Cross Transaction
 
- 5. Compulsory Test
	5.1 Random Read
	5.2 Random Write
	5.3 Random Alternate

- 6. Code Coverage
	6.1 RTL Core
	6.2 Bit Level FSM
	6.3 Byte Level FSM

- 7. Direct Test
	THIS TEST IS NOT UTILIZED SO IGNORE i2cmb_generator_direct_test IN i2cmb_env_pkg
