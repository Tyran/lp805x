`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:06:50 08/03/2012
// Design Name:   lp805x_syncg
// Module Name:   C:/Users/Tiago/Documents/Uminho/E.S.R.G/Dissertation/Xilinx/lp805x/rtl/verilog/lp805x_synctb.v
// Project Name:  lp805x
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: lp805x_syncg
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module lp805x_synctb;

	// Inputs
	reg wclk;
	reg wrst;
	reg [39:0] data_in;
	reg wput;
	reg rclk;
	reg rrst;
	reg rget;

	// Outputs
	wire wrdy;
	wire [39:0] data_out;
	wire rrdy;

	// Instantiate the Unit Under Test (UUT)
	lp805x_syncg uut (
		.wclk(wclk), 
		.wrst(wrst), 
		.data_in(data_in), 
		.wput(wput), 
		.wrdy(wrdy), 
		.rclk(rclk), 
		.rrst(rrst), 
		.data_out(data_out), 
		.rget(rget), 
		.rrdy(rrdy)
	);
	
	initial begin
	wclk = 0;
		forever #5 wclk <= ~wclk;
	end
	
	initial begin
	rclk = 0;
		forever #10 rclk <= ~rclk;
	end

	initial begin
		// Initialize Inputs
		wrst = 1;
		data_in = 0;
		wput = 0;
		rrst = 1;
		rget = 0;

		// Wait 100 ns for global reset to finish
		#100;
		wrst = 0;
		rrst = 0;
		
		// Add stimulus here
		
		#100
		data_in = 40'hAA55;
		wput = 1;
		
		#20
		wput = 0;
		
		#200
		rget = 1;
		#20
		rget = 0;
		
				
		#100
		data_in = 40'h88FFFF550000;
		wput = 1;
		
		#20
		wput = 0;
		
		#200
		rget = 1;
		
		#20
		rget = 0;
		
	end
      
endmodule

