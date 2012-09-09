//////////////////////////////////////////////////////////////////////
////                                                              ////
////  8051 internal program rom                                   ////
////                                                              ////
////  This file is part of the 8051 cores project                 ////
////  http://www.opencores.org/cores/8051/                        ////
////                                                              ////
////  Description                                                 ////
////   internal program rom for 8051 core                         ////
////                                                              ////
////  To Do:                                                      ////
////   Nothing                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - Simon Teran, simont@opencores.org                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

//
// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on
`include "oc8051_defines.v"

module lp805x_rom (rst, clk, addr, ea_int, data_o);

//parameter INT_ROM_WID= 15;

input rst, clk;
input [15:0] addr;
output ea_int;
output [31:0] data_o;


wire ea;

reg ea_int;


`ifdef LP805X_XILINX
parameter INT_ROM_WIDTH = (`LP805X_IROMLEN+2);
reg [31:0] data_o;

assign ea = | addr[15:INT_ROM_WIDTH];

always @(posedge clk or posedge rst)
begin
 if (rst)
   ea_int <= #1 1'b1;
  else ea_int <= #1 !ea;
end

wire [31:0] data0;
wire [31:0] data1;
	
reg [INT_ROM_WIDTH-1:0] addr_r;
	
always @(posedge clk or posedge rst)
begin
	if ( rst)
	begin
		addr_r <= 0;
	end
	else
	begin
		addr_r <= addr[INT_ROM_WIDTH-1:0];
	end
end
  
always @(*)
begin
	case ( addr_r[1:0])
	2'b00: data_o = data0[31:0];
	2'b01: data_o = { data1[7:0], data0[31:8] };
	2'b10: data_o = { data1[15:0], data0[31:16] };
	2'b11: data_o = { data1[23:0], data0[31:24] };
	endcase
end

 //9:0
`ifdef LP805X_ROM_INFER
lp5xRomI 
`else
lp805x_romX
`endif
romX
	(
	  .clka( clk),
	  .ena( 1'b1),
	  .addra( addr[INT_ROM_WIDTH-1:2]),
	  .douta( data0),
	  .clkb( clk),
	  .enb( 1'b1),
	  .addrb( addr[INT_ROM_WIDTH-1:2]+1'b1),
	  .doutb( data1)
	);

`else

`ifdef LP805X_ALTERA

reg [31:0] data_o;
parameter INT_ROM_WIDTH = (`LP805X_IROMLEN+2);
assign ea = | addr[15:INT_ROM_WIDTH];

wire [31:0] data0;
wire [31:0] data1;
	
reg [INT_ROM_WIDTH-1:0] addr_r;
	
always @(posedge clk or posedge rst)
begin
	if ( rst)
	begin
		addr_r <= 0;
	end
	else
	begin
		addr_r <= addr[INT_ROM_WIDTH-1:0];
	end
end
  
always @(*)
begin
	case ( addr_r[1:0])
	2'b00: data_o = data0[31:0];
	2'b01: data_o = { data1[7:0], data0[31:8] };
	2'b10: data_o = { data1[15:0], data0[31:16] };
	2'b11: data_o = { data1[23:0], data0[31:24] };
	endcase
end

	 //9:0
`ifdef LP805X_ROM_INFER
lp5xRomI romA
	(
	  .clka( clk),
	  .ena( 1'b1),
	  .addra( addr[INT_ROM_WIDTH-1:2]),
	  .douta( data0),
	  .clkb( clk),
	  .enb( 1'b1),
	  .addrb( addr[INT_ROM_WIDTH-1:2]+1'b1),
	  .doutb( data1)
	);
`else
lp805x_rom romA
	(
	  .clock( clk),
	  .enable( 1'b1),
	  .address_a( addr[INT_ROM_WIDTH-1:2]),
	  .q_a( data0),
	  .address_b( addr[INT_ROM_WIDTH-1:2]+1'b1),
	  .q_b( data1)
	);
`endif

	
always @(posedge clk or posedge rst)
begin
 if (rst)
   ea_int <= #1 1'b1;
  else ea_int <= #1 !ea;
end


`else

reg [7:0] buff [0:4095] /* synopsys syn_preserve */; //4kb

reg [31:0] data_o;

assign ea = 1'b0;

// synthesis translate_off
integer i;
initial
begin
	for ( i=0; i<4095; i=i+1)
		buff[i] <= 8'h00;
#5		
	$readmemh("LP805X_rom.in", buff);
end
// synthesis translate_on

always @(posedge clk or posedge rst)
 if (rst)
   ea_int <= #1 1'b1;
  else ea_int <= #1 !ea;

always @(posedge clk)
begin
  data_o <= #1 {buff[addr+3], buff[addr+2], buff[addr+1], buff[addr]};
end


	`endif /* XILINX ROM */
`endif /* ALTERA ROM */

endmodule

module lp5xRomI(
  clka,
  ena,
  addra,
  douta,
  clkb,
  enb,
  addrb,
  doutb
);

parameter LP805X_ROM_LEN = `LP805X_IROMSIZE;
parameter LP805X_ADD_LEN = `LP805X_IROMLEN;

input clka;
input ena;
input [LP805X_ADD_LEN-1 : 0] addra;
output reg [31 : 0] douta;
input clkb;
input enb;
input [LP805X_ADD_LEN-1 : 0] addrb;
output reg [31 : 0] doutb;

reg [31:0] buff [0:LP805X_ROM_LEN-1] /* synthesis syn_preserve=true */; //4kb

// synthesis translate_off
integer i;
initial
begin
	for ( i=0; i<LP805X_ROM_LEN; i=i+1)
		buff[i] = 32'h00000000;
end
// synthesis translate_on

initial
begin
	$readmemh("lp805x_rom.in", buff);
end


always @(posedge clka)
begin
	douta <= buff[addra];
	doutb <= buff[addrb];
end

endmodule
