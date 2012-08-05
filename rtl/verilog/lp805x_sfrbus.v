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
    input [7:0] wr_addr,
    input [7:0] rd_addr,
    input [7:0] data_in,
    input wr,
    input rd,
    input bit_in,
    input wr_bit,
    input rd_bit,
	 output [28:0] sfr_bus
    );
	
	assign 
		sfr_bus = { wr_addr, rd_addr, data_in, 
						wr, rd, bit_in, wr_bit, rd_bit };
endmodule

module lp805x_sfrbusd(
    input [7:0] data_out,
    input bit_out,
	 output [9:0] sfr_bus
    );
	
	assign 
		sfr_bus = { data_out, bit_out };

endmodule
