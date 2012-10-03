`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:49:47 10/01/2012
// Design Name:   bufgmux_test
// Module Name:   C:/Users/Tiago/Documents/Uminho/E.S.R.G/Dissertation/Xilinx/lp805x/bufgmux_tb.v
// Project Name:  lp805x
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: bufgmux_test
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module bufgmux_tb;

	// Inputs
	reg clk1;
	reg clk2;
	reg rst;
	reg sel;

	// Outputs
	wire clko;
	wire lg;

	// Instantiate the Unit Under Test (UUT)
	bufgmux_test uut (
		.clk1(clk1), 
		.clk2(clk2), 
		.rst(rst), 
		.clko(clko), 
		.sel(sel), 
		.lg(lg)
	);

	initial begin
		// Initialize Inputs
		clk1 = 0;
		clk2 = 0;
		rst = 0;
		sel = 0;

		// Wait 100 ns for global reset to finish
		#120;
      sel=1;
		
		#107
		sel=0;
		
		#53
		sel=1;
		
		#49
		sel=0;
		
		#33
		sel=1;
		// Add stimulus here
	end
	
	always #5 clk1 = ~clk1;
	always #12 clk2 = ~clk2;
      
endmodule

