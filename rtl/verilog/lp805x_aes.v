`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:37:47 08/19/2012 
// Design Name: 
// Module Name:    lp805x_aes 
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

`define LP805X_SFR_AESCON 8'h00
`define LP805X_SFR_AESIN 8'h00
`define LP805X_SFR_AESOUT 8'h01
`define LP805X_SFR_AESKEY 8'h02

module lp805x_aes( rsti, 
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

parameter LP805X_RST_AESCON = 8'b0;

input 			rsti, clk;
input [7:0] 	wr_addr, rd_addr;
input [7:0]		data_in;
input				bit_in;
input 			wr,rd;
input				wr_bit,rd_bit;

/*		internal SFR register		*/

reg [7:0] aes_control = LP805X_RST_AESCON;
reg [127:0] aes_key;
reg [127:0] aes_data;

/*		internal SFR register		*/

/*		internal SFR control		*/

output tri [7:0] data_out;
output tri bit_out;

/*		internal SFR control		*/


/*		internal AES Crypt/DeCrypt		*/

reg [4:0] aes_state;

//because last data arrives 1 clock later! ;)
reg aes_preload;
reg aes_load;

reg [4:0] aes_sload;

wire [127:0] aes_out;
reg [7:0] aes_bout;

/*		internal AES Crypt/DeCrypt		*/

wire aes_en,aes_cpt,aes_key,aes_rdy;
wire [2:0] aes_len;

assign
	aes_en = aes_control[7],
	aes_cpt = aes_control[6],
	aes_key = aes_control[5],
	aes_rdy = aes_control[4],
	aes_len = aes_control[2:0];
	
always @(*)
begin
	case ( aes_len)
		3'b000: aes_sload = 4'b0000;
		3'b001: aes_sload = 4'b0001;
		3'b010: aes_sload = 4'b0011;
		3'b011: aes_sload = 4'b0111;
		3'b100: aes_sload = 4'b1111;
		default: aes_sload = 4'b0000;
	endcase
end

always @(posedge clk)
begin
	if ( rst) begin
		aes_preload <= #1 0;
		aes_load <= #1 0;
	end if ( aes_en & (aes_state == aes_sload)) begin
		aes_preload <= #1 1;
		aes_load <= #1 0;
	end else begin
		aes_preload <= #1 0;
		aes_load <= #1 aes_preload;
	end
end
	
	//
//case writing to aes control register
always @(posedge clk)
begin
	if ( rst) begin
		aes_control <= #1 LP805X_RST_AESCON;
		aes_load <= #1 0;
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_AESCON)) begin
		aes_control <= #1 {data_in[7:6],data_in[5],aes_control[4],data_in[4:0]};
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_AESIN)) begin
		case ( aes_state)
			4'b0000: aes_data[7:0] 		<= #1 data_in;
			4'b0001: aes_data[15:8] 	<= #1 data_in;
			4'b0010: aes_data[23:16] 	<= #1 data_in;
			4'b0011: aes_data[31:24] 	<= #1 data_in;
			4'b0100: aes_data[39:32] 	<= #1 data_in;
			4'b0101: aes_data[47:40] 	<= #1 data_in;
			4'b0110: aes_data[55:48] 	<= #1 data_in;
			4'b1111: aes_data[63:56] 	<= #1 data_in;
			4'b1000: aes_data[71:64] 	<= #1 data_in;
			4'b1001: aes_data[79:72] 	<= #1 data_in;
			4'b1010: aes_data[87:80] 	<= #1 data_in;
			4'b1011: aes_data[95:88]	<= #1 data_in;
			4'b1100: aes_data[103:96] 	<= #1 data_in;
			4'b1101: aes_data[111:104] <= #1 data_in;
			4'b1110: aes_data[119:112] <= #1 data_in;
			4'b1111: aes_data[127:120] <= #1 data_in;
			default: aes_data <= #1 aes_data;
		endcase		
				
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_AESKEY)) begin
		case ( aes_state)
			4'b0000: aes_key[7:0] 		<= #1 data_in;
			4'b0001: aes_key[15:8] 		<= #1 data_in;
			4'b0010: aes_key[23:16] 	<= #1 data_in;
			4'b0011: aes_key[31:24] 	<= #1 data_in;
			4'b0100: aes_key[39:32] 	<= #1 data_in;
			4'b0101: aes_key[47:40] 	<= #1 data_in;
			4'b0110: aes_key[55:48] 	<= #1 data_in;
			4'b1111: aes_key[63:56] 	<= #1 data_in;
			4'b1000: aes_key[71:64] 	<= #1 data_in;
			4'b1001: aes_key[79:72] 	<= #1 data_in;
			4'b1010: aes_key[87:80]		<= #1 data_in;
			4'b1011: aes_key[95:88]		<= #1 data_in;
			4'b1100: aes_key[103:96] 	<= #1 data_in;
			4'b1101: aes_key[111:104] 	<= #1 data_in;
			4'b1110: aes_key[119:112] 	<= #1 data_in;
			4'b1111: aes_key[127:120] 	<= #1 data_in;
			default: aes_key <= #1 aes_key;
		endcase
	end
end

always @(posedge clk)
begin
	if ( rst) begin
		aes_state <= #1 0;
	end else if ( wr & ~wr_bit & ((wr_addr==`LP805X_SFR_AESIN) | (wr_addr==`LP805X_SFR_AESKEY) )) begin
		case ( aes_state)
			5'b00000: aes_state <= #1 5'b00001;
			5'b00001: aes_state <= #1 5'b00010;
			5'b00010: aes_state <= #1 5'b00011;
			5'b00011: aes_state <= #1 5'b00100;
			5'b00100: aes_state <= #1 5'b00101;
			5'b00101: aes_state <= #1 5'b00110;
			5'b00110: aes_state <= #1 5'b00111;
			5'b00111: aes_state <= #1 5'b01000;
			5'b01000: aes_state <= #1 5'b01001;
			5'b01001: aes_state <= #1 5'b01010;
			5'b01010: aes_state <= #1 5'b01011;
			5'b01011: aes_state <= #1 5'b01100;
			5'b01100: aes_state <= #1 5'b01101;
			5'b01101: aes_state <= #1 5'b01110;
			5'b01110: aes_state <= #1 5'b01111;
			5'b01111: aes_state <= #1 5'b10000;
			5'b10000: aes_state <= #1 5'b00000;
		endcase
	end
end

aes aes_1
	(
		.clk( clk),
		.reset( rst),
		.load_i( aes_ld),
		.decrypt_i( aes_cpt),
		.data_i( aes_data),
		.key_i( aes_key),
		.ready_o( aes_rdy),
		.data_o( aes_out)
	);
	
	
	always @(posedge clk)
	begin
		if ( rst)
			aes_bout <= #1 0;
		else if ( rd & output_data) begin
			aes_bout <= #1 0;
		end	
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
      `LP805X_SFR_AESCON: 		{output_data,data_read} <= #1 {1'b1,aes_control};
		`LP805X_SFR_AESIN: 		{output_data,data_read} <= #1 {1'b1,aes_data};
		`LP805X_SFR_AESOUT: 		{output_data,data_read} <= #1 {1'b1,aes_out};
		`LP805X_SFR_AESKEY: 		{output_data,data_read} <= #1 {1'b1,aes_key};
      default:             {output_data,data_read} <= #1 {1'b0,8'h0};
    endcase
end

assign data_out = output_data ? data_read : 8'hzz;

assign bit_out = 1'bz; //no bit addr

endmodule
