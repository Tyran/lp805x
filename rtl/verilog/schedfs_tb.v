`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   01:23:57 07/02/2012
// Design Name:   lp805x_schedfs
// Module Name:   C:/Users/Tiago/Documents/Uminho/E.S.R.G/Dissertation/Xilinx/lp805x/schedfs_tb.v
// Project Name:  lp805x
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: lp805x_schedfs
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module schedfs_tb;

	// Inputs
	reg clki;
	reg [7:0] factor;

	// Outputs
	wire [7:0] index;

	// Instantiate the Unit Under Test (UUT)
	lp805x_schedfs uut (
		.clki(clki), 
		.factor(factor), 
		.index(index)
	);

	initial begin
		// Initialize Inputs
		clki = 0;
		factor = 0;

		// Wait 100 ns for global reset to finish
		#100;
      factor = 0;
		#20
		factor = 1;
		#20
		factor = 2;
		#20
		factor = 3;
		#20
		factor = 4;
		#20
		factor = 5;
		#20
		factor = 6;
		#20
		factor = 7;
		
		// Add stimulus here

	end
	
	always #5 clki = ~clki;
      
endmodule

