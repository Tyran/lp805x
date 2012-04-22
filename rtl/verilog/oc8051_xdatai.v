// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on
`include "oc8051_defines.v"

module oc8051_xdatai( clk, rst, addr, data_i, data_o, wr, stb, ack);

input 				clk;
input 				rst;

input					wr;
input					stb;

//output	reg		ack;
output				ack;

input		[15:0]	addr;
input		[7:0]		data_i;

output	[7:0]		data_o;

//always @(posedge clk)
//begin
//		if ( rst)
//			ack <= 1'b0;
//		else if ( stb & !ack)
//			ack <= 1'b1;
//		else
//			ack <= 1'b0;
//end

reg ack_w;	//1 cycle faster
reg ack_r;
assign ack = stb & ack_w & (ack_r|wr);

always @(posedge clk)
begin
		if ( rst)
			ack_w <= 1'b1;
		else if ( stb & ack_w & wr)
			ack_w <= 1'b0;
		else
			ack_w <= 1'b1;
end

always @(posedge clk)
begin
		if ( rst)
			ack_r <= 1'b0;
		else if ( stb & !ack_r)
			ack_r <= 1'b1;
		else
			ack_r <= 1'b0;
end

`ifdef OC8051_XRAM_ALTERA
myaltera_xram oc8051_xrami1(
	.aclr(rst),
	.address(addr),
	.clock(clk),
	.data(data_i),
	.wren(wr),
	.q(data_o)
	);
`else
`ifdef OC8051_XRAM_XILINX
generic_xram oc8051_xrami1(
	.aclr(rst),
	.address(addr),
	.clock(clk),
	.data(data_i),
	.rden(1'b1),
	.wren(wr),
	.q(data_o)
	);
`else
generic_xram oc8051_xrami1(
	.aclr(rst),
	.address(addr),
	.clock(clk),
	.data(data_i),
	.rden(1'b1),
	.wren(wr),
	.q(data_o)
	);
`endif
`endif

endmodule

module generic_xram(
	aclr,
	address,
	clock,
	data,
	rden,
	wren,
	q
);

	input aclr,rden,wren,clock;
	input [15:0] address;
	input [7:0] data;
	output reg [7:0] q;
	
	reg [7:0] buff [0:4095] /* synthesis syn_preserve */; //4kb

	always@(posedge clock)
	begin
		if ( wren)
			buff[address] <= data;
	end
	
	always@(posedge clock)
	begin
		if ( rden)
			q <= buff[address];		
	end

endmodule
