`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   01:32:36 08/12/2012
// Design Name:   lp805x_rand
// Module Name:   C:/Users/Tiago/Documents/Uminho/E.S.R.G/Dissertation/Xilinx/lp805x/rtl/verilog/lp805x_randtb.v
// Project Name:  lp805x
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: lp805x_rand
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module lp805x_randtb;

	// Inputs
	reg clk;
	reg reset;
	reg loadseed_i;
	reg [31:0] seed_i;

	// Outputs
	wire [31:0] number_o;

	// Instantiate the Unit Under Test (UUT)
	lp805x_rand uut (
		.clk(clk), 
		.reset(reset), 
		.loadseed_i(loadseed_i), 
		.seed_i(seed_i), 
		.number_o(number_o)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		loadseed_i = 0;
		seed_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
		reset = 0;
        
		// Add stimulus here

	end
	
	always #5 clk <= ~clk;
      
endmodule

