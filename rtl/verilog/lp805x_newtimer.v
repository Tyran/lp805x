`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:39:42 05/20/2012 
// Design Name: 
// Module Name:    lp805x_newtimer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: MMIO INTERFACE
//
//////////////////////////////////////////////////////////////////////////////////


`define LP805X_SFR_NTMRH 8'hea
`define LP805X_SFR_NTMRL 8'heb
`define LP805X_SFR_NTMRCTR 8'hec

module lp805x_newtimer
	(
		clk, 
		rst,
		bit_in,
		bit_out,
		data_in,
		data_out,
		wr, 
		wr_bit,
		rd,
		rd_bit,
		wr_addr, 
		rd_addr,
		ntf,
		ntr
    );
	 
parameter TIMER_BITLEN = 16;
parameter PRESCALE_BITLEN = 8; //prescaler of 256!

parameter TIMER_RSTVAL = 0;

parameter BITMODES_LEN = 3;

parameter TIMERCTR_RSTVAL = 0;
	 
input clk,rst; //inter

input wr,rd;
input wr_bit,rd_bit;

input [7:0]	wr_addr,rd_addr;

input [7:0] data_in;
input bit_in;

output tri [7:0] data_out;
output tri bit_out;

assign bit_out = 1'bz;
	 
reg [7:0] data_read;


output ntf, ntr;

assign 
	ntf = timer_ov,
	ntr = 1'b1;

//two-ways of prescaling, let's try the lsb xtra bit count way
reg [ (TIMER_BITLEN)-1:0] timer_count;
reg [ PRESCALE_BITLEN-1:0] timer_pres;
reg timer_ov;
reg [7:0] timer_control;
wire [2:0] presc_ctr;
wire inc_timer; //condition to increment is match! assign...

reg [2:0] dummy;


assign inc_timer = timer_control[4];

assign presc_ctr = timer_control[7:5];

always @(posedge clk or posedge rst)
begin
	if ( rst) begin
		timer_control <= #1 TIMERCTR_RSTVAL;
	end else if ((wr) & !(wr_bit) & (wr_addr==`LP805X_SFR_NTMRCTR)) begin
		timer_control <= #1 data_in;
	end else if ( timer_ov) begin
		timer_control[0] <= #1 1'b1;
	end
end

reg [2:0] pres_src;

always @( presc_ctr)
begin
	case ( presc_ctr)
	3'b000: pres_src = 3'b111;
	3'b001: pres_src = { timer_pres[7], 2'b11 };
	3'b010: pres_src = { timer_pres[7:6], 1'b1 };
	3'b011: pres_src = timer_pres[7:5];
	endcase
end

always @(posedge clk or posedge rst)
begin
	if ( rst) begin
		timer_count <= #1 TIMER_RSTVAL;
		timer_ov <= #1 1'b0;
		timer_pres <= #1 8'b0;
		dummy <= #1 3'b0;
	end else if ((wr) & !(wr_bit) & (wr_addr==`LP805X_SFR_NTMRH)) begin
		timer_count <= #1 {data_in,timer_count[7:0]};
	end else if ((wr) & !(wr_bit) & (wr_addr==`LP805X_SFR_NTMRL)) begin
		timer_count <= #1 {timer_count[15:8],data_in};		
	end else if ( inc_timer) begin
		case ( timer_control[BITMODES_LEN-1:0]) //nmr of configurable bits
			3'b000: begin//16 bit counter
			
				case ( presc_ctr)
				3'b000: { timer_ov, timer_count, dummy[2:0] }
				<= #1 { 1'b0, timer_count, pres_src } + 1'b1;
				
				3'b001: { timer_ov, timer_count, timer_pres[7],dummy[1:0] }
				<= #1 { 1'b0, timer_count, pres_src } + 1'b1;
				
				3'b010: { timer_ov, timer_count, timer_pres[7:6],dummy[0] }
				<= #1 { 1'b0, timer_count, pres_src } + 1'b1;
				
				3'b011: { timer_ov, timer_count, timer_pres[7:5] }
				<= #1 { 1'b0, timer_count, pres_src } + 1'b1;
				
				default: 
					begin
						timer_ov <= 1'b0;
						timer_count <= #1 timer_count;
						timer_pres <= #1 timer_pres;
						dummy <= #1 dummy;
					end
				endcase
				
			end
		endcase
	end
end

reg output_data;
//
// case of reading byte from port
always @(posedge clk or posedge rst)
begin
  if (rst) begin
    {output_data,data_read} <= #1 {1'b0,8'h0};
	end
  else
	//if ( !rd_bit)
    case (rd_addr)
		`LP805X_SFR_NTMRH: 	{output_data,data_read} <= #1 {1'b1,timer_count[15:8]};
		`LP805X_SFR_NTMRL: 	{output_data,data_read} <= #1 {1'b1,timer_count[7:0]};
      `LP805X_SFR_NTMRCTR: {output_data,data_read} <= #1 {1'b1,timer_control[7:0]};
      default:             {output_data,data_read} <= #1 {1'b0,8'h0};
    endcase
end

assign data_out = output_data ? data_read : 8'hzz;

endmodule
