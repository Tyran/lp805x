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


`ifdef LP805X_PORTS

module lp805x_ports(
			clk_cpu,
			clk, 
			rst,
			sfr_bus,
			sfr_get,
			data_out,
			bit_out,
			sfr_wrdy,
			sfr_rrdy,
			sfr_put,

	`ifdef LP805X_PORT0
		    p0_out,
          p0_in,
	`endif

	`ifdef LP805X_PORT1
		    p1_out,
		    p1_in,
	`endif

	`ifdef LP805X_PORT2
		    p2_out,
		    p2_in,
	`endif

	`ifdef LP805X_PORT3
		    p3_out,
		    p3_in,
	`endif
	
		   rmw);

input   clk,	//clock
        rst;	//reset

input clk_cpu;

input [28:0] sfr_bus;

input sfr_get,sfr_put;
output sfr_wrdy,sfr_rrdy;
		  
wire    wr,	//write [LP805X_decoder.wr -r]
		  rd,
	     wr_bit,	//write bit addresable [LP805X_decoder.bit_addr -r]
		  rd_bit,
	     bit_in;	//bit input [LP805X_alu.desCy]

input rmw;	//read modify write feature [LP805X_decoder.rmw]
		  
output 	bit_out;
		  
wire [7:0]  wr_addr,	//write address [LP805X_ram_wr_sel.out]
				 rd_addr,
             data_in; 	//data input (from alu destiantion 1) [LP805X_alu.des1]
				 
output tri [7:0] data_out;

reg [7:0] data_read;

`ifdef LP805X_PORT0
  input  [7:0] p0_in;
  output [7:0] p0_out;
  wire    [7:0] p0_data;
  reg    [7:0] p0_out;

  assign p0_data = rmw ? p0_out : p0_in;
`endif


`ifdef LP805X_PORT1
  input  [7:0] p1_in;
  output [7:0] p1_out;
  wire    [7:0] p1_data;
  reg    [7:0] p1_out;

  assign p1_data = rmw ? p1_out : p1_in;
`endif


`ifdef LP805X_PORT2
  input  [7:0] p2_in;
  output [7:0] p2_out;
  wire    [7:0] p2_data;
  reg    [7:0] p2_out;

  assign p2_data = rmw ? p2_out : p2_in;
`endif


`ifdef LP805X_PORT3
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
`ifdef LP805X_PORT0
    p0_out <= #1 `LP805X_RST_P0;
`endif

`ifdef LP805X_PORT1
    p1_out <= #1 `LP805X_RST_P1;
`endif

`ifdef LP805X_PORT2
    p2_out <= #1 `LP805X_RST_P2;
`endif

`ifdef LP805X_PORT3
    p3_out <= #1 `LP805X_RST_P3;
`endif
  end else if (wr) begin
    if (!wr_bit) begin
      case (wr_addr)
//
// bytaddresable
`ifdef LP805X_PORT0
        `LP805X_SFR_P0: p0_out <= #1 data_in;
`endif

`ifdef LP805X_PORT1
        `LP805X_SFR_P1: p1_out <= #1 data_in;
`endif

`ifdef LP805X_PORT2
        `LP805X_SFR_P2: p2_out <= #1 data_in;
`endif

`ifdef LP805X_PORT3
        `LP805X_SFR_P3: p3_out <= #1 data_in;
`endif
      endcase
    end else begin
      case (wr_addr[7:3])
//
// bit addressable
`ifdef LP805X_PORT0
        `LP805X_SFR_B_P0: p0_out[wr_addr[2:0]] <= #1 bit_in;
`endif

`ifdef LP805X_PORT1
        `LP805X_SFR_B_P1: p1_out[wr_addr[2:0]] <= #1 bit_in;
`endif

`ifdef LP805X_PORT2
        `LP805X_SFR_B_P2: p2_out[wr_addr[2:0]] <= #1 bit_in;
`endif

`ifdef LP805X_PORT3
        `LP805X_SFR_B_P3: p3_out[wr_addr[2:0]] <= #1 bit_in;
`endif
      endcase
    end
  end
end


tri bit_out;

reg bit_outc;
reg bit_outd;
//assign bit_out = bit_outc ? bit_outd : 1'bz;
//
// case of reading bit from port
always @(posedge clk or posedge rst)
begin
  if (rst)
   {bit_outc,bit_outd} <= #1 {1'b0,1'b0};
  else
   if ( rd_bit)
    case (rd_addr[7:3])
`ifdef LP805X_PORTS
  `ifdef LP805X_PORT0
      `LP805X_SFR_B_P0:    {bit_outc,bit_outd} <= #1 {1'b1,p0_data[rd_addr[2:0]]};
  `endif

  `ifdef LP805X_PORT1
      `LP805X_SFR_B_P1:    {bit_outc,bit_outd} <= #1 {1'b1,p1_data[rd_addr[2:0]]};
  `endif

  `ifdef LP805X_PORT2
      `LP805X_SFR_B_P2:    {bit_outc,bit_outd} <= #1 {1'b1,p2_data[rd_addr[2:0]]};
  `endif

  `ifdef LP805X_PORT3
      `LP805X_SFR_B_P3:    {bit_outc,bit_outd} <= #1 {1'b1,p3_data[rd_addr[2:0]]};
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
`ifdef LP805X_PORTS
  `ifdef LP805X_PORT0
      `LP805X_SFR_P0: 		{output_data,data_read} <= #1 {1'b1,p0_data};
  `endif

  `ifdef LP805X_PORT1
      `LP805X_SFR_P1: 		{output_data,data_read} <= #1 {1'b1,p1_data};
  `endif

  `ifdef LP805X_PORT2
      `LP805X_SFR_P2: 		{output_data,data_read} <= #1 {1'b1,p2_data};
  `endif

  `ifdef LP805X_PORT3
      `LP805X_SFR_P3: 		{output_data,data_read} <= #1 {1'b1,p3_data};
  `endif
`endif
      default:             {output_data,data_read} <= #1 {1'b0,8'h0};
    endcase
end

wire [28:0] sfr_bus_1;
wire [8:0] sfr_bus_2;
wire [8:0] sfr_bus_2s;
wire sfr_pget, sfr_pput;
wire sfr_prrdy, sfr_pwrdy;
wire sfr_out;
wire sfr_wrdy,sfr_rrdy;

	lp805x_syncg #(.DATA_WIDTH(29)) sync_1tp
		(
			.wclk(clk_cpu),
			.wrst(rst),
			.data_in(sfr_bus),
			.wput(sfr_put),
			.wrdy(sfr_wrdy),
			.rclk(clk),
			.rrst(rst),
			.data_out(sfr_bus_1),
			.rget(sfr_pget),
			.rrdy(sfr_prrdy)
		);

	lp805x_sfrbused decode_1
		(
			.sfr_bus( sfr_bus_1),
			
			.bit_in(bit_in),
			.data_in(data_in),
			.wr(wr),
			.rd(rd),
			.wr_bit(wr_bit),
			.rd_bit(rd_bit),
			.wr_addr(wr_addr),
			.rd_addr(rd_addr)
		);

	lp805x_synctrl sync_1
		(
			.clk( clk),
			.rst( rst),
			.read( rd),
			.sfr_prrdy( sfr_prrdy),
			.sfr_pget( sfr_pget),
			.sfr_pwrdy( sfr_pwrdy),
			.sfr_pput( sfr_pput),
			.clk_cpu( clk_cpu),
			.sfr_get( sfr_get),
			.sfr_out( sfr_out),
			.sfr_rrdy( sfr_rrdy),
			.this( output_data | bit_outc)
		);

	lp805x_sfrbusd sfrbusO_1
		(
			.clk(clk),
			.data_out( data_read),
			.bit_out( bit_outd),
			.load( output_data | bit_outc),
			.sfr_bus( sfr_bus_2)
		);

	lp805x_syncg #(.DATA_WIDTH(9)) sync_1fp
		(
			.wclk(clk),
			.wrst(rst),
			.data_in(sfr_bus_2),
			.wput(sfr_pput),
			.wrdy(sfr_pwrdy),
			.rclk(clk_cpu),
			.rrst(rst),
			.data_out(sfr_bus_2s),
			.rget(sfr_get),
			.rrdy(sfr_rrdy)
		);
		
		assign 
			data_out = sfr_out ? sfr_bus_2s[8:1] : 8'hzz,
			bit_out = sfr_out ? sfr_bus_2s[0] : 1'bz;

endmodule

`endif 