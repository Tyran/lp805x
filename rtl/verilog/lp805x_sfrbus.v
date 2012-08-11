`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:16:06 08/03/2012 
// Design Name: 
// Module Name:    lp805x_sfrbus 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module lp805x_sfrbuse(
	 input clk,
    input [7:0] wr_addr,
    input [7:0] rd_addr,
    input [7:0] data_in,
    input wr,
    input rd,
    input bit_in,
    input wr_bit,
    input rd_bit,
	 input load,
	 output reg [28:0] sfr_bus
    );
	 
	 wire [28:0] sfr_bus_;
	
	assign 
		sfr_bus_ = { wr_addr, rd_addr, data_in, 
						wr, rd, bit_in, wr_bit, rd_bit };
						
	always @(posedge clk)
		if ( load)
			sfr_bus <= #1 sfr_bus_;
endmodule

module lp805x_sfrbused(
    output [7:0] wr_addr,
    output [7:0] rd_addr,
    output [7:0] data_in,
    output wr,
    output rd,
    output bit_in,
    output wr_bit,
    output rd_bit,
	 input [28:0] sfr_bus
    );
	
	assign 
		{ wr_addr, rd_addr, data_in, 
			wr, rd, bit_in, wr_bit, rd_bit } = sfr_bus;

endmodule

module lp805x_sfrbusd(
	 input clk,
    input [7:0] data_out,
    input bit_out,
	 input load,
	 output reg [8:0] sfr_bus
    );
	 
	 wire [8:0] sfr_bus_;
	
	assign 
		sfr_bus_ = { data_out, bit_out };
		
	always @(posedge clk)
		if ( load)
			sfr_bus <= #1 sfr_bus_;

endmodule
