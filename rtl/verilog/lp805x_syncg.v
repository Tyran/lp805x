`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:38:10 07/31/2012 
// Design Name: 
// Module Name:    lp805x_syncg 
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

module lp805x_syncg(
		wclk,
		wrst,
		data_in,
		wput,
		wrdy,
		rclk,
		rrst,
		data_out,
		rget,
		rrdy
    );
	 
	parameter WR=0;
	parameter RD=1;
	parameter DATA_WIDTH = 40;

	input [DATA_WIDTH-1:0] data_in;
	input wclk,wrst,wput;
	output wrdy;
	
	output [DATA_WIDTH-1:0] data_out;
	input rclk,rrst,rget;
	output rrdy;
	
	wire we,wptr;
	wire rd,rptr;
	wire wq2_rptr,rq2_wptr;

	rwctl #(.OPERATION(WR)) wctl( .clk( wclk), .rst(wrst), .ld(wput),
							.rdy(wrdy), .en(we), .ptr(wptr), .q2_ptr(wq2_rptr));
	
	sync2 syncrtow( .clk( wclk), .rst( wrst), .in(rptr), .out(wq2_rptr));
	
	rwctl #(.OPERATION(RD)) rctl( .clk( rclk), .rst(rrst), .ld(rget),
							.rdy(rrdy), .en(rd), .ptr(rptr), .q2_ptr(rq2_wptr));
							
	sync2 syncwtor( .clk( rclk), .rst( rrst), .in(wptr), .out(rq2_wptr));						
		
	myfifo #(.DATA_WIDTH(DATA_WIDTH))
	fifo_1
	(
		.wclk( wclk),
		.we( we),
		.waddr( wptr),
		.wdata( data_in),
		.rclk( rclk),
		.rrst( rrst),
		.rd( rd),
		.raddr( rptr),
		.rdata( data_out)
	);

endmodule

module myfifo(
	wclk,
	we,
	waddr,
	wdata,
	rclk,
	rrst,
	rd,
	raddr,
	rdata
	);
	
	parameter DATA_WIDTH = 40;
	parameter ADDR_WIDTH = 1;

	input wclk,we;
	input [DATA_WIDTH-1:0] wdata;
	input [ADDR_WIDTH-1:0] waddr;
		
	input rclk,rd;
	input rrst;
	output reg [DATA_WIDTH-1:0] rdata;
	input [ADDR_WIDTH-1:0] raddr;
	
	reg [DATA_WIDTH-1:0] buff [0:(1<<ADDR_WIDTH)-1]; //(1<<ADDR_WIDTH)-1
		
	always @(posedge wclk)
		if ( we)
			buff[waddr] <= #1 wdata;
			
	always @(posedge rclk)
		if ( rrst)
			rdata <= #1 0;
		else if ( rd)
			rdata <= #1 buff[raddr];
	
endmodule

module rwctl( clk, rst, ld, rdy, en, ptr, q2_ptr);
	input clk,rst;
	input ld;
	input q2_ptr;
	
	output rdy;
	output ptr;
	output en;
	
	reg ffd;
	
	parameter WR=0;
	parameter RD=1;
	parameter OPERATION = WR;
	
	generate
		if ( OPERATION==WR)
			assign rdy = ~(ptr ^ q2_ptr);
		else
			assign rdy = (ptr ^ q2_ptr);
	endgenerate
	
	assign
		en = ld & rdy,
		ptr = ffd;
	
	always @(posedge clk or posedge rst)
		if ( rst)
			ffd <= #1 0;
		else
			ffd <= #1 ffd ^ en;

endmodule

module sync2( clk, rst, in, out );

	input clk,rst;
	input in;
	output out;

	reg ff1,ff2;
	
	assign out = ff2;
	
	always @(posedge clk or posedge rst)
	begin
		if ( rst) begin
			ff1 <= #1 0;
			ff2 <= #1 0;
		end else begin
			ff1 <= #1 in;
			ff2 <= #1 ff1;
		end
	end

endmodule

/*
module rctl (
  output  rrdy, reg rptr,
  input   rget,rq2_wptr,
  input   rclk, rrst_n);
  
  assign rinc  = rrdy & rget;
  assign rrdy  = (rq2_wptr ^ rptr);
  always @(posedge rclk or negedge rrst_n)
    if   (!rrst_n) rptr <= 0;
    else           rptr <= rptr ^ rinc;
endmodule

module dp_ram2
 (output [7:0] q,
  input  [7:0] d,
  input   waddr, raddr, we, clk);
  reg [7:0] mem [0:1];
  always @(posedge clk)
    if (we) mem[waddr] <= d;
  assign q = mem[raddr];
endmodule

module lp805x_syncg (
  // Write clk interface
  input  [7:0] wdata,
  output  wrdy,
  input   wput,
  input   wclk, wrst_n,
  // Read clk interface
  output [7:0] rdata,
  output  rrdy,
  input   rget,
  input   rclk, rrst_n);
  //reg wptr, we, wq2_rptr;
 // reg rptr, rq2_wptr;
  wctl  wctl  ( .wrdy(wrdy), .wptr(wptr), .we(we), .wput(wput),
  .wq2_rptr(wq2_rptr), .wclk(wclk), .wrst_n(wrst_n));
  rctl  rctl  ( .rrdy(rrdy), .rptr(rptr), .rget(rget),
  .rq2_wptr(rq2_wptr),.rclk(rclk), .rrst_n(rrst_n));
  sync2 w2r_sync (.q(rq2_wptr), .d(wptr), .clk(rclk), .rst_n(rrst_n));
  sync2 r2w_sync (.q(wq2_rptr), .d(rptr), .clk(wclk), .rst_n(wrst_n));
  // dual-port 2-deep ram
  dp_ram2 dpram (.q(rdata), .d(wdata),
                          .waddr(wptr), .raddr(rptr),
                          .we(we), .clk(wclk));
endmodule

module wctl (
  output  wrdy, 
  output reg wptr,
  output   we,
  input   wput, wq2_rptr,
  input   wclk, wrst_n);
  assign we    = wrdy & wput;
  assign wrdy  = ~(wq2_rptr ^ wptr);
  always @(posedge wclk or negedge wrst_n)
    if (!wrst_n) wptr <= 0;
    else         wptr <= wptr ^ we;
endmodule

// sync signal to different clock domain
module sync2 (
  output  reg q,
  input   d, clk, rst_n);
  reg q1; // 1st stage ff output
  always @(posedge clk or negedge rst_n)
    if (!rst_n) {q,q1} <= 0;
    else        {q,q1} <= {q1,d};
endmodule

*/