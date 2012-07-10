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
	reg [8:0] factor;
	reg rst;
	reg start;

	// Outputs
	wire [2:0] index;

	// Instantiate the Unit Under Test (UUT)
	lp805x_schedfs uut (
		.clk( clki), 
		.rst( rst),
		.enable( 1'b1),
		.start( start),
		.factor(factor), 
		.index(index)
	);

	initial begin
		// Initialize Inputs
		clki = 0;
		rst = 1;
		start = 0;
		factor = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;
		start = 1;
      factor = 5;
		#10
		start = 0;
		#100
		start = 1;
		factor = 8;
		#10
		start = 0;
		#100
		start = 1;
		factor = 15;
		#10
		start = 0;
		#100
		start = 1;
		factor = 30;
		#10
		start = 0;
		#100
		start = 1;
		factor = 32;
		#10
		start = 0;
		#100
		start = 1;
		factor = 70;
		#10
		start = 0;
		#100
		start = 1;
		factor = 250;
		#10
		start = 0;
		#100
		start = 1;
		factor = 271;
		#10
		start = 0;
		#100
		start = 1;
		factor = 501;
		
		// Add stimulus here

	end
	
	always #5 clki = ~clki;
      
endmodule

