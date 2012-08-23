`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:28:25 08/22/2012 
// Design Name: 
// Module Name:    lp805x_rand 
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
// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"

`define LP805X_SFR_RANDCON 8'hfc
`define LP805X_SFR_RANDSEED 8'hfd
`define LP805X_SFR_RANDOUT 8'hfe

module lp805x_rand( rst, 
						 clk,
						 wr_addr, rd_addr,
						 data_in, data_out, 
						 wr, rd, 
						 bit_in, bit_out,
						 wr_bit, rd_bit
						);
//
// clk          (in)  clock source
// rsti         (in)  reset source
// rst          (out) running reset
// wr_addr      (in)  write address [oc8051_ram_wr_sel.out]
// rd_addr      (in)  read address [oc8051_ram_wr_sel.out]
// data_in      (in)  data input [oc8051_alu.des1]
// bit_in       (in)  input bit data [oc8051_alu.desCy]
// wr           (in)  write [oc8051_decoder.wr -r]
// rd           (in)  read [oc8051_decoder.rd -r]
// wr_bit       (in)  write bit addresable [oc8051_decoder.bit_addr -r]
// rd_bit       (in)  read bit addresable [oc8051_decoder.bit_addr -r]
// data_out     (out) data output [oc8051_alu.des1]
// bit_out      (out) output bit data [oc8051_alu.desCy]
//

parameter LP805X_RST_RANDCON = 8'b0;

input 			rst, clk;
input [7:0] 	wr_addr, rd_addr;
input [7:0]		data_in;
input				bit_in;
input 			wr,rd;
input				wr_bit,rd_bit;

/*		internal SFR register		*/

reg [7:0] rand_control;
reg [31:0] rand_seed;

/*		internal SFR register		*/

/*		internal SFR control		*/

output tri [7:0] data_out;
output tri bit_out;

/*		internal SFR control		*/


/*		internal Random Control		*/

reg [1:0] rand_state;
reg [1:0] rand_sload;

reg rand_stw;
reg rand_rund;

wire [31:0] rand_out;
reg [7:0] rand_bout;

/*		internal Random Control		*/

wire rand_en,rand_seedr,rand_mode,rand_clw;
wire [1:0] rand_len;

assign
	rand_en = rand_control[7],
	rand_seedr = rand_control[6],
	rand_mode = rand_control[5],
	rand_clw = rand_control[4],
	rand_len = rand_control[1:0];

always @(*)
begin
	case ( rand_len)
		2'b00: rand_sload = 2'b00;
		2'b01: rand_sload = 2'b01;
		2'b10: rand_sload = 2'b10;
		2'b11: rand_sload = 2'b11;
		default: rand_sload = 2'b00;
	endcase
end
	
	//
//case writing to rand control register
always @(posedge clk)
begin
	if ( rst) begin
		rand_control <= #1 LP805X_RST_RANDCON;
		rand_seed <= #1 0;
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_RANDCON)) begin
		rand_control <= #1 data_in;
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_RANDSEED)) begin
		case ( rand_state)
			2'b00: rand_seed[7:0] 		<= #1 data_in;
			2'b01: rand_seed[15:8] 	<= #1 data_in;
			2'b10: rand_seed[23:16] 	<= #1 data_in;
			2'b11: rand_seed[31:24] 	<= #1 data_in;
			default: rand_seed <= #1 rand_seed;
		endcase		
	end else begin
		rand_control[6] <= 1'b0;
	end
end

always @(posedge clk)
begin
	if ( rst) begin
		rand_state <= #1 0;
	end else if ( wr & ~wr_bit & (wr_addr==`LP805X_SFR_RANDCON) & data_in[4]) begin
		rand_state <= #1 0;
	end else if ( (wr & ~wr_bit & ((wr_addr==`LP805X_SFR_RANDSEED)))
						| (rd & ((rd_addr == `LP805X_SFR_RANDOUT))) ) begin
		if ( rand_en & (rand_state == rand_sload))
			rand_state <= #1 0;
		else
			case ( rand_state)
				2'b00: rand_state <= #1 2'b01;
				2'b01: rand_state <= #1 2'b10;
				2'b10: rand_state <= #1 2'b11;
				2'b11: rand_state <= #1 2'b00;
			endcase
	end
end

always @(posedge clk)
begin
	if ( rst)
		rand_stw <= 0;
	else if ( wr & ~wr_bit & (wr_addr==`LP805X_SFR_RANDCON))
		rand_stw <= data_in[6];
	else
		rand_stw <= 0;
end

	always @(posedge clk)
	begin
		if ( rst)
			rand_rund <= #1 0;
		else if ( rand_mode)
			rand_rund <= #1 rand_en;
		else if ( rd & (rd_addr == `LP805X_SFR_RANDOUT) & (rand_state == rand_sload))
			rand_rund <= #1 rand_en;
		else 
			rand_rund <= #1 0;
	end

random psdrand_1
	(
		.clk( clk),
		.reset( rst),
		.loadseed_i( rand_stw),
		.seed_i( rand_seed),
		.number_o( rand_out),
		.run( rand_rund)
	);
	
	always @(posedge clk)
	begin
		if ( rst)
			rand_bout = 0;
		else if ( rd & (rd_addr == `LP805X_SFR_RANDOUT)) begin
			case ( rand_state) /* all cases */
				2'b00: rand_bout = rand_out[7:0];
				2'b01: rand_bout = rand_out[15:8];
				2'b10: rand_bout = rand_out[23:16];
				2'b11: rand_bout = rand_out[31:24];
			endcase
		end	
		else
			rand_bout = 0;
	end
	
reg output_data;
reg [7:0] data_read;
//
// case of reading byte from port
always @(posedge clk)
begin
  if (rst) begin
    {output_data,data_read} <= #1 {1'b0,8'h0};
	end
  else
	if ( rd)
    case (rd_addr)
      `LP805X_SFR_RANDCON: 		{output_data,data_read} <= #1 {1'b1,rand_control};
		`LP805X_SFR_RANDOUT: 		{output_data,data_read} <= #1 {1'b1,rand_bout};
      default:             {output_data,data_read} <= #1 {1'b0,8'h0};
    endcase
end

assign data_out = output_data ? data_read : 8'hzz;

assign bit_out = 1'bz; //no bit addr

endmodule
