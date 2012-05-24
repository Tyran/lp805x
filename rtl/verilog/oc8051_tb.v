//////////////////////////////////////////////////////////////////////
////                                                              ////
////  8051 top level test bench                                   ////
////                                                              ////
////  This file is part of the 8051 cores project                 ////
////  http://www.opencores.org/cores/8051/                        ////
////                                                              ////
////  Description                                                 ////
////   top level test bench.                                      ////
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
// Revision 1.15  2003/06/05 17:14:27  simont
// Change test monitor from ports to external data memory.
//
// Revision 1.14  2003/06/05 12:54:38  simont
// remove dumpvars.
//
// Revision 1.13  2003/06/05 11:13:39  simont
// add FREQ paremeter.
//
// Revision 1.12  2003/04/16 09:55:56  simont
// add support for external rom from xilinx ramb4
//
// Revision 1.11  2003/04/10 12:45:06  simont
// defines for pherypherals added
//
// Revision 1.10  2003/04/03 19:20:55  simont
// Remove instruction cache and wb_interface
//
// Revision 1.9  2003/04/02 15:08:59  simont
// rename signals
//
// Revision 1.8  2003/01/13 14:35:25  simont
// remove wb_bus_mon
//
// Revision 1.7  2002/10/28 16:43:12  simont
// add module oc8051_wb_iinterface
//
// Revision 1.6  2002/10/24 13:36:53  simont
// add instruction cache and DELAY parameters for external ram, rom
//
// Revision 1.5  2002/10/17 19:00:50  simont
// add external rom
//
// Revision 1.4  2002/09/30 17:33:58  simont
// prepared header
//
//

// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"


//`define POST_ROUTE

module oc8051_tb();


//parameter FREQ  = 12000; // frequency in kHz
parameter FREQ  = 1000; // frequency in kHz

parameter DELAY = 500000/FREQ;
parameter RSTDELAY = DELAY*2;

reg  rst;

//wire int0,int1;

//wire				ea_rom_sel;
wire 	[7:0] 	op1,op2,op3,
					//op1_o,op2_o,op3_o,
					op_pos,
					//op1_out,op2_out,op3_out,
					op_cur,
					op_in;
wire 	[7:0] 	imm,imm2,imm_r,imm2_r;
wire	[7:0]		cdata;
wire	 		  	cdone;
wire 	[31:0] 	idat_cur,idat_old;
wire 	[15:0]	addr;
wire 	[31:0] 	data_o;
wire 	[2:0] 	mem_act;
reg				clk;
wire 	[7:0]		accr,acc;
wire	[7:0]		data_in;
wire				wr_acc;


wire  [7:0] 	rd_addr,rd_data,wr_addr,wr_data;
wire				rd_en,wr;


wire	[7:0]		xd_addr, xd_datai, xd_datao;
wire				xd_wr, xd_stb, xd_ack;


//wire	[12:0]	addr_sel0, addr_sel1, addr_sel2, addr_sel3;
wire	[15:0] 	pc_out;

wire 	[1:0]		state;

wire 				rd;

wire [7:0] p0_in, p0_out;
wire [7:0] p1_in, p1_out;

assign p0_in=8'h53;
assign p1_in=8'hAA;

`ifndef POST_ROUTE

assign xd_addr = oc8051_top_1.oc8051_xdatai1.addr;
assign xd_datai = oc8051_top_1.oc8051_xdatai1.data_i;
assign xd_datao = oc8051_top_1.oc8051_xdatai1.data_o;
assign xd_wr = oc8051_top_1.oc8051_xdatai1.wr;
assign xd_stb = oc8051_top_1.oc8051_xdatai1.stb;
assign xd_ack = oc8051_top_1.oc8051_xdatai1.ack;

//assign ea_rom_sel = oc8051_top_1.oc8051_memory_interface1.ea_rom_sel;
assign op1 = oc8051_top_1.oc8051_memory_interface1.op1;
assign op2 = oc8051_top_1.oc8051_memory_interface1.op2;
assign op3 = oc8051_top_1.oc8051_memory_interface1.op3;
//assign op1_o = oc8051_top_1.oc8051_memory_interface1.op1_o;
//assign op2_o = oc8051_top_1.oc8051_memory_interface1.op2_o;
//assign op3_o = oc8051_top_1.oc8051_memory_interface1.op3_o;
assign op_pos = oc8051_top_1.oc8051_memory_interface1.op_pos;
//assign op1_out = oc8051_top_1.oc8051_memory_interface1.op1_out;//assign op2_out = oc8051_top_1.oc8051_memory_interface1.op2_out;
//assign op3_out = oc8051_top_1.oc8051_memory_interface1.op3_out;
assign op_cur = oc8051_top_1.oc8051_decoder1.op_cur;
assign mem_act = oc8051_top_1.oc8051_decoder1.mem_act;
assign op_in = oc8051_top_1.oc8051_decoder1.op_in;
assign state = oc8051_top_1.oc8051_decoder1.state;
assign imm = oc8051_top_1.oc8051_memory_interface1.imm;
assign imm2 = oc8051_top_1.oc8051_memory_interface1.imm2;
assign imm_r = oc8051_top_1.oc8051_memory_interface1.imm_r;
assign imm2_r = oc8051_top_1.oc8051_memory_interface1.imm2_r;
assign cdata = oc8051_top_1.oc8051_memory_interface1.cdata;
assign cdone = oc8051_top_1.oc8051_memory_interface1.cdone;
assign idat_cur = oc8051_top_1.oc8051_memory_interface1.idat_cur;
assign idat_old = oc8051_top_1.oc8051_memory_interface1.idat_old;
`ifdef LP805X_ROM_ONCHIP
assign addr = oc8051_top_1.oc8051_rom1.addr;
assign data_o = oc8051_top_1.oc8051_rom1.data_o;
`endif
//assign addr_sel0 = oc8051_top_1.oc8051_rom1.addr_sel0;
//assign addr_sel1 = oc8051_top_1.oc8051_rom1.addr_sel1;
//assign addr_sel2 = oc8051_top_1.oc8051_rom1.addr_sel2;
//assign addr_sel3 = oc8051_top_1.oc8051_rom1.addr_sel3;
assign accr = oc8051_top_1.oc8051_sfr1.oc8051_acc1.data_out;
assign acc = oc8051_top_1.oc8051_sfr1.oc8051_acc1.acc;
assign wr_acc = oc8051_top_1.oc8051_sfr1.oc8051_acc1.wr_acc;
assign data_in = oc8051_top_1.oc8051_sfr1.oc8051_acc1.data_in;
assign pc_out = oc8051_top_1.oc8051_memory_interface1.pc_out;
assign rd = oc8051_top_1.rd;
assign rd_addr = oc8051_top_1.oc8051_ram_top1.oc8051_idata.rd_addr;
assign rd_data = oc8051_top_1.oc8051_ram_top1.oc8051_idata.rd_data;
assign wr_addr = oc8051_top_1.oc8051_ram_top1.oc8051_idata.wr_addr;
assign wr_data = oc8051_top_1.oc8051_ram_top1.oc8051_idata.wr_data;
assign rd_en = oc8051_top_1.oc8051_ram_top1.oc8051_idata.rd_en;
assign wr = oc8051_top_1.oc8051_ram_top1.oc8051_idata.wr;

`endif


///
/// buffer for test vectors
///
//
// buffer
//reg [23:0] buff [0:255];

`ifndef LP805X_ROM_ONCHIP

wire [15:0] iadr_o;
wire [31:0] idat_i;
wire 			iack_i, wbi_err_i, istb_o, icyc_o;

assign 
	wbi_err_i = 1'b0,
	iack_i = 1'b1;

oc8051_rom romx
			(
				.rst( rst),
				.clk( clk),
				.addr( iadr_o),
				.data_o( idat_i)
			);
`endif

//
// oc8051 controller
//
oc8051_top oc8051_top_1(
		.wb_rst_i(~rst),
		.wb_clk_i(clk),
 //        .int0_i(int0), .int1_i(int1),
`ifndef LP805X_ROM_ONCHIP
		.wbi_adr_o( iadr_o),
		.wbi_dat_i( idat_i),
	   .wbi_stb_o( istb_o), 
		.wbi_ack_i( iack_i),
		.wbi_cyc_o( icyc_o), 
		.wbi_err_i( wbi_err_i),
`endif		

  `ifdef OC8051_PORTS

   `ifdef OC8051_PORT0
	 .p0_i(p0_in),
	 .p0_o(p0_out),
   `endif

   `ifdef OC8051_PORT1
	 .p1_i(p1_in),
	 .p1_o(p1_out),
   `endif

   `ifdef OC8051_PORT2
	 .p2_i(p2_in),
	 .p2_o(p2_out),
   `endif

   `ifdef OC8051_PORT3
	 .p3_i(p3_in),
	 .p3_o(p3_out),
   `endif
  `endif


   `ifdef OC8051_UART
	 .rxd_i(rxd), .txd_o(txd),
   `endif

   `ifdef OC8051_TC01
	 .t0_i(t0), .t1_i(t1),
   `endif

   `ifdef OC8051_TC2
	 .t2_i(t2), .t2ex_i(t2ex),
   `endif

	 `ifdef LP805X_ROM_ONCHIP
	 .ea_in( 1'b1) 
	 `else
	 .ea_in( 1'b0) 
	 `endif
	 );


//
// external data ram
//
//oc8051_xram oc8051_xram1 (.clk(clk), .rst(rst), .wr(write_xram), .addr(ext_addr), 
//.data_in(data_out), .data_out(data_out_xram), .ack(ack_xram), .stb(stb_o));

//myaltera_xram oc8051_xram1(
//	.aclr(rst),
//	.address(ext_addr),
//	.clock(clk),
//	.data(data_out),
//	.rden(1'b1),
//	.wren(write_xram),
//	.q(data_out_xram)
//	);

//defparam oc8051_xram1.DELAY = 2;

`ifdef OC8051_SERIAL

//
// test programs with serial interface
//
oc8051_serial oc8051_serial1(.clk(clk), .rst(rst), .rxd(txd), .txd(rxd));

defparam oc8051_serial1.FREQ  = FREQ;
//defparam oc8051_serial1.BRATE = 9.6;
defparam oc8051_serial1.BRATE = 4.8;


`else

//
// external uart
//
//oc8051_uart_test oc8051_uart_test1(.clk(clk), .rst(rst), .addr(ext_addr[7:0]), .wr(write_uart),
  //                .wr_bit(p3_out[0]), .data_in(data_out), .data_out(data_out_uart), .bit_out(bit_out), .rxd(txd),
	//	  .txd(rxd), .ow(p3_out[1]), .intr(int_uart), .stb(stb_o), .ack(ack_uart));


`endif

/*
assign write_xram = p3_out[7] & write;
assign write_uart = !p3_out[7] & write;
assign data_in = p3_out[7] ? data_out_xram : data_out_uart;
assign ack_i = p3_out[7] ? ack_xram : ack_uart;
assign p3_in = {6'h0, bit_out, int_uart};
assign t0 = p3_out[5];
assign t1 = p3_out[6];

assign int0 = p3_out[3];
assign int1 = p3_out[4];
assign t2 = p3_out[5];
assign t2ex = p3_out[2];
*/

initial begin
  rst= 1'b1;
  /*
  p0_in = 8'h00;
  p1_in = 8'h00;
  p2_in = 8'h00;
  */
#RSTDELAY
  rst = 1'b0;

//#20000
//  $display("time ",$time, "\n end of time\n \n");
//  $finish;
end


initial
begin
  clk = 0;
  forever #DELAY clk <= ~clk;
end



endmodule
