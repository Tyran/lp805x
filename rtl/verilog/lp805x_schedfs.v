`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:05:16 07/02/2012 
// Design Name: 
// Module Name:    lp805x_schedfs 
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
module lp805x_schedfs(
		rst,
		clk,
		factor,
		index,
		enable,
		start
    );
	 
	 parameter TOP_PRESCALER = 7;
	 
	 input clk,rst;
	 input wire [7:0] factor;
	 output reg [2:0] index;
	 
	 wire [8:0] scale [1:7];
	 
	 reg [8:0] pipe [0:6];
	 reg [2:0] select;
	 
	 input start;
	 input enable;
	 
	 assign
		scale[7] = 9'd7,
		scale[6] = 9'd15,
		scale[5] = 9'd31,
		scale[4] = 9'd62,
		scale[3] = 9'd125,
		scale[2] = 9'd250,
		scale[1] = 9'd500;
		
	always @(posedge clk or posedge rst)
	begin
		if ( rst | start)
		begin
			pipe[0] <= #1 scale[7];
			pipe[1] <= #1 scale[6];
			pipe[2] <= #1 scale[5];
			pipe[3] <= #1 scale[4];
			pipe[4] <= #1 scale[3];
			pipe[5] <= #1 scale[2];
			pipe[6] <= #1 scale[1];
			select  <= #1 3'h7;
		end
		else if ( enable)
		begin
			pipe[0] <= #1 pipe[1];
			pipe[1] <= #1 pipe[2];
			pipe[2] <= #1 pipe[3];
			pipe[3] <= #1 pipe[4];
			pipe[4] <= #1 pipe[5];
			pipe[5] <= #1 pipe[6];
			select  <= #1 select - 1'b1;
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if ( rst)
		begin
			index <= #1 3'b0;
//			enable <= #1 1'b0;
		end
		else if ( enable)
		begin
			if ( factor <= pipe[0])
			begin
				index <= select;
	//			enable <= #1 1'b0;
			end
		end
	end
	 
	 
	 
	 
	 /*always@(*)
	 begin
		if ( factor[7])
			index = 7;
		else if ( factor[6])
			index = 6;
		else if ( factor[5])
			index = 5;
		else if ( factor[4])
			index = 4;
		else if ( factor[3])
			index = 3;
		else if ( factor[2])
			index = 2;
		else if ( factor[1])
			index = 1;
		else if ( factor[0])
			index = 0;
		else
			index = 0;
	 end*/
endmodule
