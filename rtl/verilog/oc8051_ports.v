//////////////////////////////////////////////////////////////////////
////                                                              ////
////  8051 port output                                            ////
////                                                              ////
////  This file is part of the 8051 cores project                 ////
////  http://www.opencores.org/cores/8051/                        ////
////                                                              ////
////  Description                                                 ////
////   8051 special function registers: port 0:3 - output         ////
////                                                              ////
////  To Do:                                                      ////
////   nothing                                                    ////
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
// Revision 1.9  2003/04/10 12:43:19  simont
// defines for pherypherals added
//
// Revision 1.8  2003/04/07 14:58:02  simont
// change sfr's interface.
//
// Revision 1.7  2003/01/13 14:14:41  simont
// replace some modules
//
// Revision 1.6  2002/09/30 17:33:59  simont
// prepared header
//
//


// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"


`ifdef OC8051_PORTS

module oc8051_ports(
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

	`ifdef OC8051_PORT0
		    p0_out,
          p0_in,
	`endif

	`ifdef OC8051_PORT1
		    p1_out,
		    p1_in,
	`endif

	`ifdef OC8051_PORT2
		    p2_out,
		    p2_in,
	`endif

	`ifdef OC8051_PORT3
		    p3_out,
		    p3_in,
	`endif
	
		   rmw);

input   clk,	//clock
        rst,	//reset
	     wr,	//write [oc8051_decoder.wr -r]
		  rd,
	     wr_bit,	//write bit addresable [oc8051_decoder.bit_addr -r]
		  rd_bit,
	     bit_in,	//bit input [oc8051_alu.desCy]
	     rmw;	//read modify write feature [oc8051_decoder.rmw]
		  
output 	bit_out;
		  
input [7:0]  wr_addr,	//write address [oc8051_ram_wr_sel.out]
				 rd_addr,
             data_in; 	//data input (from alu destiantion 1) [oc8051_alu.des1]
				 
output tri [7:0] data_out;

reg [7:0] data_read;


`ifdef OC8051_PORT0
  input  [7:0] p0_in;
  output [7:0] p0_out;
  wire    [7:0] p0_data;
  reg    [7:0] p0_out;

  assign p0_data = rmw ? p0_out : p0_in;
`endif


`ifdef OC8051_PORT1
  input  [7:0] p1_in;
  output [7:0] p1_out;
  wire    [7:0] p1_data;
  reg    [7:0] p1_out;

  assign p1_data = rmw ? p1_out : p1_in;
`endif


`ifdef OC8051_PORT2
  input  [7:0] p2_in;
  output [7:0] p2_out;
  wire    [7:0] p2_data;
  reg    [7:0] p2_out;

  assign p2_data = rmw ? p2_out : p2_in;
`endif


`ifdef OC8051_PORT3
  input  [7:0] p3_in;
  output [7:0] p3_out;
  wire    [7:0] p3_data;
  reg    [7:0] p3_out;

  assign p3_data = rmw ? p3_out : p3_in;
`endif

//
// case of writing to port
always @(posedge clk or posedge rst)
begin
  if (rst) begin
`ifdef OC8051_PORT0
    p0_out <= #1 `OC8051_RST_P0;
`endif

`ifdef OC8051_PORT1
    p1_out <= #1 `OC8051_RST_P1;
`endif

`ifdef OC8051_PORT2
    p2_out <= #1 `OC8051_RST_P2;
`endif

`ifdef OC8051_PORT3
    p3_out <= #1 `OC8051_RST_P3;
`endif
  end else if (wr) begin
    if (!wr_bit) begin
      case (wr_addr)
//
// bytaddresable
`ifdef OC8051_PORT0
        `OC8051_SFR_P0: p0_out <= #1 data_in;
`endif

`ifdef OC8051_PORT1
        `OC8051_SFR_P1: p1_out <= #1 data_in;
`endif

`ifdef OC8051_PORT2
        `OC8051_SFR_P2: p2_out <= #1 data_in;
`endif

`ifdef OC8051_PORT3
        `OC8051_SFR_P3: p3_out <= #1 data_in;
`endif
      endcase
    end else begin
      case (wr_addr[7:3])
//
// bit addressable
`ifdef OC8051_PORT0
        `OC8051_SFR_B_P0: p0_out[wr_addr[2:0]] <= #1 bit_in;
`endif

`ifdef OC8051_PORT1
        `OC8051_SFR_B_P1: p1_out[wr_addr[2:0]] <= #1 bit_in;
`endif

`ifdef OC8051_PORT2
        `OC8051_SFR_B_P2: p2_out[wr_addr[2:0]] <= #1 bit_in;
`endif

`ifdef OC8051_PORT3
        `OC8051_SFR_B_P3: p3_out[wr_addr[2:0]] <= #1 bit_in;
`endif
      endcase
    end
  end
end


tri bit_out;

reg bit_outc;
reg bit_outd;
assign bit_out = bit_outc ? bit_outd : 1'bz;
//
// case of reading bit from port
always @(posedge clk or posedge rst)
begin
  if (rst)
   {bit_outc,bit_outd} <= #1 {1'b0,1'b0};
  else
   if ( rd_bit)
    case (rd_addr[7:3])
`ifdef OC8051_PORTS
  `ifdef OC8051_PORT0
      `OC8051_SFR_B_P0:    {bit_outc,bit_outd} <= #1 {1'b1,p0_data[rd_addr[2:0]]};
  `endif

  `ifdef OC8051_PORT1
      `OC8051_SFR_B_P1:    {bit_outc,bit_outd} <= #1 {1'b1,p1_data[rd_addr[2:0]]};
  `endif

  `ifdef OC8051_PORT2
      `OC8051_SFR_B_P2:    {bit_outc,bit_outd} <= #1 {1'b1,p2_data[rd_addr[2:0]]};
  `endif

  `ifdef OC8051_PORT3
      `OC8051_SFR_B_P3:    {bit_outc,bit_outd} <= #1 {1'b1,p3_data[rd_addr[2:0]]};
  `endif
`endif
	default:		{bit_outc,bit_outd} <= #1 {1'b0,1'b0};
    endcase
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
`ifdef OC8051_PORTS
  `ifdef OC8051_PORT0
      `OC8051_SFR_P0: 		{output_data,data_read} <= #1 {1'b1,p0_data};
  `endif

  `ifdef OC8051_PORT1
      `OC8051_SFR_P1: 		{output_data,data_read} <= #1 {1'b1,p1_data};
  `endif

  `ifdef OC8051_PORT2
      `OC8051_SFR_P2: 		{output_data,data_read} <= #1 {1'b1,p2_data};
  `endif

  `ifdef OC8051_PORT3
      `OC8051_SFR_P3: 		{output_data,data_read} <= #1 {1'b1,p3_data};
  `endif
`endif
      default:             {output_data,data_read} <= #1 {1'b0,8'h0};
    endcase
end

assign data_out = output_data ? data_read : 8'hzz;


endmodule

`endif 