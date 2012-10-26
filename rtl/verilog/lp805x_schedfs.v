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

`define LP805X_SFR_SCHEDH 8'he9
`define LP805X_SFR_SCHEDL 8'hea

module lp805x_schedfs(
		rst,
		clk,
		bit_in,
		bit_out,
		data_in,
		data_out,
		wr, 
		wr_bit,
		rd,
		rd_bit,
		wr_addr, 
		rd_addr
    );
	 
	parameter SCHEDH_RSTVAL = 8'h0;
	parameter SCHEDL_RSTVAL = 8'h0;
	 
	parameter TOP_PRESCALER = 7;
	 
	input clk,rst;
	 
	input wr,rd;
	input wr_bit,rd_bit;

	input [7:0]	wr_addr,rd_addr;
	
	input [7:0] data_in;
	input bit_in;
	reg [7:0] data_read;
	 
	 
	wire [15:0] factor;
	wire [10:0] scale [0:7];

	reg [10:0] pipe [0:7];
	reg [2:0] select;

	
	wire _enable;
	reg running;
	 
	//registers
	reg [7:0] sched_h, sched_l; //factor
	reg [2:0] index; //freq select [no-bind]

	//read operation
	output tri [7:0] data_out;
	output tri bit_out;

	wire start,enable;//complete is not necessary, just check start negedge ;)
	assign
		start = sched_h[7],
		enable = sched_h[6],
		//still space for fore functions :-)
		//factor comes already mult by 16
		//scale values are adjusted
		factor = { sched_h[2:0], sched_l }; 

	assign //binding frequency select
		scale[7] = 11'd12,
		scale[6] = 11'd25,
		scale[5] = 11'd50,
		scale[4] = 11'd100,
		scale[3] = 11'd200,
		scale[2] = 11'd400,
		scale[1] = 11'd800,
		scale[0] = 11'd1600;
		
	assign
		_enable = start & !running & enable ? 1'b1 : running & enable ? 1'b1 : 1'b0;
		
		
	always @(posedge clk or posedge start or posedge rst)
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
			pipe[7] <= #1 11'd0;
			select  <= #1 select - 1'b1;
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if ( rst)
		begin
			index <= #1 3'b0;
			running <= #1 1'b0;
		end
		else if ( _enable)
		begin
			if ( select == 0)
			begin
				index <= #1 select;
				running <= #1 1'b0;
			end
			else if ( factor <= pipe[0])
			begin
				index <= #1 select;
				running <= #1 1'b0;
			end
		end
		else if ( start & enable)
			running <= #1 1'b1;
	end
	
	
	always @(posedge clk or posedge rst)
	begin
		if ( rst) begin
			sched_h <= #1 SCHEDH_RSTVAL;
			sched_l <= #1 SCHEDL_RSTVAL;
		end else if (wr & !wr_bit) begin
				case ( wr_addr)
					`LP805X_SFR_SCHEDH: sched_h <= #1 data_in;
					`LP805X_SFR_SCHEDL: sched_l <= #1 data_in;
					default: begin sched_h[7] <= #1 running; sched_h[5:3] <= #1 index; end
				endcase
		end else begin
			sched_h[7] <= #1 running;
			sched_h[5:3] <= #1 index;
		end
	end

	reg output_data;
	//
	// case of reading byte from port
	always @(posedge clk or posedge rst)
	begin
	  if (rst)
		 {output_data,data_read} <= #1 {1'b0,8'h0};
	  else
		//if ( !rd_bit)
		 case (rd_addr)
			`LP805X_SFR_SCHEDH: 	{output_data,data_read} <= #1 {1'b1,sched_h};
			`LP805X_SFR_SCHEDL: 	{output_data,data_read} <= #1 {1'b1,sched_l};
			default:             {output_data,data_read} <= #1 {1'b0,8'h0};
		 endcase
	end

assign data_out = output_data ? data_read : 8'hzz;

assign bit_out = 1'bz;
	
endmodule
