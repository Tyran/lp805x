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
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.3  2003/06/03 17:09:57  simont
// pipelined acces to axternal instruction interface added.
//
// Revision 1.2  2003/04/03 19:17:19  simont
// add `include "oc8051_defines.v"
//
// Revision 1.1  2003/04/02 11:16:22  simont
// initial inport
//
// Revision 1.4  2002/10/23 17:00:18  simont
// signal es_int=1'b0
//
// Revision 1.3  2002/09/30 17:34:01  simont
// prepared header
//
//
// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on
`include "oc8051_defines.v"

module oc8051_rom (rst, clk, addr, ea_int, data_o);

//parameter INT_ROM_WID= 15;

input rst, clk;
input [15:0] addr;
output ea_int;
output [31:0] data_o;


wire ea;

reg ea_int;


`ifdef OC8051_XILINX_ROM

reg [31:0] data_o;

assign ea = 1'b0;

always @(posedge clk or posedge rst)
begin
 if (rst)
   ea_int <= #1 1'b1;
  else ea_int <= #1 !ea;
end

wire [31:0] data0;
wire [31:0] data1;
	
reg [11:0] addr_r;
	
always @(posedge clk or posedge rst)
begin
	if ( rst)
	begin
		addr_r <= 12'h0;
	end
	else
	begin
		addr_r <= addr[11:0];
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
`ifdef _XILINX_ROM_INFER_
lp5xRomXI 
`else
lp5xRomX
`endif
romX
	(
	  .clka( clk),
	  .ena( 1'b1),
	  .addra( addr[11:2]),
	  .douta( data0),
	  .clkb( clk),
	  .enb( 1'b1),
	  .addrb( addr[11:2]+10'b1),
	  .doutb( data1)
	);

`else

`ifdef OC8051_ALTERA_ROM
wire [31:0] data_o;
parameter INT_ROM_WIDTH = 16;
assign ea = | addr[15:INT_ROM_WIDTH-1];

wire [7:0] data_0,data_1,data_2,data_3;
wire rom0_en,rom1_en,rom2_en,rom3_en;

/*
assign rom0_en = addr_sel[1:0] == 2'b00 ? 1'b1:1'b0;
assign rom1_en = addr_sel[1:0] == 2'b01 ? 1'b1:1'b0;
assign rom2_en = addr_sel[1:0] == 2'b20 ? 1'b1:1'b0;
assign rom3_en = addr_sel[1:0] == 2'b11 ? 1'b1:1'b0;
*/

wire [13:0] addr_sel0,addr_sel1,addr_sel2,addr_sel3;

assign addr_sel0 = addr[15:2] + (addr[1:0] > 2'b00 ? 13'b1 : 13'b0);
assign addr_sel1 = addr[15:2] + (addr[1:0] > 2'b01 ? 13'b1 : 13'b0);
assign addr_sel2 = addr[15:2] + (addr[1:0] > 2'b10 ? 13'b1 : 13'b0);
assign addr_sel3 = addr[15:2];

assign data_o =	addr[1:0] == 2'b00 ? {data_3,data_2,data_1,data_0} :
						addr[1:0] == 2'b01 ? {data_0,data_3,data_2,data_1} :
						addr[1:0] == 2'b10 ? {data_1,data_0,data_3,data_2} :
						addr[1:0] == 2'b11 ? {data_2,data_1,data_0,data_3} : {data_3,data_2,data_1,data_0} ;

assign rom0_en = 1'b1;
assign rom1_en = 1'b1;
assign rom2_en = 1'b1;
assign rom3_en = 1'b1;

	rom14kx8 #(.init_file("rom0.mif")) rom0(
	.address(addr_sel0),
	.clock(clk),
	.rden(rom0_en),
	.q(data_0)
	);
	
	rom14kx8 #(.init_file("rom1.mif")) rom1(
	.address(addr_sel1),
	.clock(clk),
	.rden(rom1_en),
	.q(data_1)
	);
	
	rom14kx8 #(.init_file("rom2.mif")) rom2(
	.address(addr_sel2),
	.clock(clk),
	.rden(rom2_en),
	.q(data_2)
	);	

	rom14kx8 #(.init_file("rom3.mif")) rom3(
	.address(addr_sel3),
	.clock(clk),
	.rden(rom3_en),
	.q(data_3)
	);

	always @(posedge clk or posedge rst)
	begin
	 if (rst)
		ea_int <= #1 1'b1;
	 else 
		ea_int <= #1 !ea;
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
	$readmemh("oc8051_rom.in", buff);
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

module lp5xRomXI(
  clka,
  ena,
  addra,
  douta,
  clkb,
  enb,
  addrb,
  doutb
);

input clka;
input ena;
input [9 : 0] addra;
output reg [31 : 0] douta;
input clkb;
input enb;
input [9 : 0] addrb;
output reg [31 : 0] doutb;

reg [31:0] buff [0:1023] /* synopsys syn_preserve */; //4kb

// synthesis translate_off
integer i;
initial
begin
	for ( i=0; i<1024; i=i+1)
		buff[i] <= 32'h00000000;
#5
	$readmemh("oc8051_rom.in", buff);
end
// synthesis translate_on

always @(posedge clka)
begin
	douta <= buff[addra];
	doutb <= buff[addrb];
end

endmodule
