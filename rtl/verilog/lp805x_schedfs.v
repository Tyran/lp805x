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
	 input wire [8:0] factor;
	 output reg [2:0] index;
	 
	 wire [15:0] _factor;
	 wire [10:0] scale [0:7];
	 
	 reg [10:0] pipe [0:7];
	 reg [2:0] select;
	 
	 input start;
	 input enable;
	 
	 reg _enable;
	 
	 assign
		scale[7] = 11'd12,
		scale[6] = 11'd25,
		scale[5] = 11'd50,
		scale[4] = 11'd100,
		scale[3] = 11'd200,
		scale[2] = 11'd400,
		scale[1] = 11'd800,
		scale[0] = 11'd1600;
		
	assign
		_factor = factor[8:0]<<4;
		
	always @(posedge clk or posedge rst or posedge start)
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
			pipe[7] <= #1 scale[0];
			select  <= #1 3'h7;
		end
		else if ( _enable)
		begin
			pipe[0] <= #1 pipe[1];
			pipe[1] <= #1 pipe[2];
			pipe[2] <= #1 pipe[3];
			pipe[3] <= #1 pipe[4];
			pipe[4] <= #1 pipe[5];
			pipe[5] <= #1 pipe[6];
			pipe[6] <= #1 pipe[7];
			select  <= #1 select - 1'b1;
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if ( rst)
		begin
			index <= #1 3'b0;
			_enable <= #1 1'b0;
		end
		else if ( _enable)
		begin
			if ( select == 0)
			begin
				index <= #1 select;
				_enable <= #1 1'b0;
			end
			else if ( _factor <= pipe[0])
			begin
				index <= #1 select;
				_enable <= #1 1'b0;
			end
		end
		else if ( start)
			_enable <= #1 1'b1;
	end
	 
endmodule
