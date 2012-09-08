// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on
`include "oc8051_defines.v"

module lp805x_xdatai( clk, rst, addr, data_i, data_o, wr, stb, ack);

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

`ifdef LP805X_XRAM_ALTERA
myaltera_xram lp805x_xrami1(
	.aclr(rst),
	.address(addr[`LP805X_XDATALEN-1:0]),
	.clock(clk),
	.data(data_i),
	.wren(wr),
	.q(data_o)
	);
`else
`ifdef LP805X_XRAM_XILINX
generic_xram lp805x_xrami1(
	.aclr(rst),
	.address(addr[`LP805X_XDATALEN-1:0]),
	.clock(clk),
	.data(data_i),
	.rden(1'b1),
	.wren(wr),
	.q(data_o)
	);
`else
generic_xram lp805x_xrami1(
	.aclr(rst),
	.address(addr[`LP805X_XDATALEN-1:0]),
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

	parameter LP805X_XDATA_LEN = `LP805X_XDATASIZE;
	parameter LP805X_ADD_LEN = `LP805X_XDATALEN;

	input aclr,rden,wren,clock;
	input [LP805X_ADD_LEN-1:0] address;
	input [7:0] data;
	output reg [7:0] q;
	
	reg [7:0] buff [0:LP805X_XDATA_LEN-1] /* synthesis syn_preserve */; //4kb
	
	// synthesis translate_off
	integer i;
	initial
	begin
		for ( i=0; i<LP805X_XDATA_LEN; i=i+1)
			buff[i] = 8'h00000000;
	end
	// synthesis translate_on

	always@(posedge clock)
	begin
		if ( wren)
			buff[address] <= data;
	end
	
	always@(posedge clock)
	begin
		if ( aclr)
			q <= 8'b0;
		else if ( rden)
			q <= buff[address];	
	end

endmodule
