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
// add module lp805x_wb_iinterface
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

module lp805x_tb();


//parameter FREQ  = 12000; // frequency in kHz
parameter FREQ  = 30000; // frequency in kHz
//parameter FREQ  = 3500; // frequency in kHz

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
wire				clk_div;
wire 	[7:0]		accr,acc;
wire	[7:0]		data_in;
wire				wr_acc;


wire  [7:0] 	rd_addr,rd_data,wr_addr,wr_data;
wire				rd_en,wr;


wire  [15:0] 	xd_addr;
wire	[7:0]		xd_datai, xd_datao;
wire				xd_wr, xd_stb, xd_ack;


//wire	[12:0]	addr_sel0, addr_sel1, addr_sel2, addr_sel3;
wire	[15:0] 	pc_out;

wire 	[1:0]		state;

wire 				rd;

wire [7:0] p0_in, p0_out;
wire [7:0] p1_in, p1_out;

assign p0_in=8'h53;
assign p1_in=8'hAA;

parameter PWMS_LEN=1;
`ifdef LP805X_NTC
wire  pin_cnt;
wire 	[PWMS_LEN-1:0] pin;
`endif

`ifndef POST_ROUTE

//assign clk_div = lp805x_top_1.wb_clk_s;

assign xd_addr = lp805x_top_1.xdatai_1.addr;
assign xd_datai = lp805x_top_1.xdatai_1.data_i;
assign xd_datao = lp805x_top_1.xdatai_1.data_o;
assign xd_wr = lp805x_top_1.xdatai_1.wr;
assign xd_stb = lp805x_top_1.xdatai_1.stb;
assign xd_ack = lp805x_top_1.xdatai_1.ack;

//assign ea_rom_sel = lp805x_top_1.control_interface_1.ea_rom_sel;
assign op1 = lp805x_top_1.control_interface_1.op1;
assign op2 = lp805x_top_1.control_interface_1.op2;
assign op3 = lp805x_top_1.control_interface_1.op3;
//assign op1_o = lp805x_top_1.control_interface_1.op1_o;
//assign op2_o = lp805x_top_1.control_interface_1.op2_o;
//assign op3_o = lp805x_top_1.control_interface_1.op3_o;
assign op_pos = lp805x_top_1.control_interface_1.op_pos;
//assign op1_out = lp805x_top_1.control_interface_1.op1_out;//assign op2_out = lp805x_top_1.control_interface_1.op2_out;
//assign op3_out = lp805x_top_1.control_interface_1.op3_out;
assign op_cur = lp805x_top_1.decoder_1.op_cur;
assign mem_act = lp805x_top_1.decoder_1.mem_act;
assign op_in = lp805x_top_1.decoder_1.op_in;
assign state = lp805x_top_1.decoder_1.state;
assign imm = lp805x_top_1.control_interface_1.imm;
assign imm2 = lp805x_top_1.control_interface_1.imm2;
assign imm_r = lp805x_top_1.control_interface_1.imm_r;
assign imm2_r = lp805x_top_1.control_interface_1.imm2_r;
assign cdata = lp805x_top_1.control_interface_1.cdata;
assign cdone = lp805x_top_1.control_interface_1.cdone;
assign idat_cur = lp805x_top_1.control_interface_1.idat_cur;
assign idat_old = lp805x_top_1.control_interface_1.idat_old;
`ifdef LP805X_ROM_ONCHIP
assign addr = lp805x_top_1.rom_1.addr;
assign data_o = lp805x_top_1.rom_1.data_o;
`endif
//assign addr_sel0 = lp805x_top_1.rom_1.addr_sel0;
//assign addr_sel1 = lp805x_top_1.rom_1.addr_sel1;
//assign addr_sel2 = lp805x_top_1.rom_1.addr_sel2;
//assign addr_sel3 = lp805x_top_1.rom_1.addr_sel3;
assign accr = lp805x_top_1.sfr_1.acc_1.data_out;
assign acc = lp805x_top_1.sfr_1.acc_1.acc;
assign wr_acc = lp805x_top_1.sfr_1.acc_1.wr_acc;
assign data_in = lp805x_top_1.sfr_1.acc_1.data_in;
assign pc_out = lp805x_top_1.control_interface_1.pc_out;
assign rd = lp805x_top_1.rd;
assign rd_addr = lp805x_top_1.dataram_1.idata_1.rd_addr;
assign rd_data = lp805x_top_1.dataram_1.idata_1.rd_data;
assign wr_addr = lp805x_top_1.dataram_1.idata_1.wr_addr;
assign wr_data = lp805x_top_1.dataram_1.idata_1.wr_data;
assign rd_en = lp805x_top_1.dataram_1.idata_1.rd_en;
assign wr = lp805x_top_1.dataram_1.idata_1.wr;

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

lp805x_rom romx
			(
				.rst( rst),
				.clk( clk),
				.addr( iadr_o),
				.data_o( idat_i)
			);
`endif

//
// lp805x controller
//
lp805x_top #(.PWMS_LEN(PWMS_LEN)) lp805x_top_1(
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

  `ifdef LP805X_PORTS

   `ifdef LP805X_PORT0
	 .p0_i(p0_in),
	 .p0_o(p0_out),
   `endif

   `ifdef LP805X_PORT1
	 .p1_i(p1_in),
	 .p1_o(p1_out),
   `endif

   `ifdef LP805X_PORT2
	 .p2_i(p2_in),
	 .p2_o(p2_out),
   `endif

   `ifdef LP805X_PORT3
	 .p3_i(p3_in),
	 .p3_o(p3_out),
   `endif
  `endif


   `ifdef LP805X_UART
	 .rxd_i(rxd), .txd_o(txd),
   `endif

   `ifdef LP805X_TC01
	 .t0_i(t0), .t1_i(t1),
   `endif

   `ifdef LP805X_TC2
	 .t2_i(t2), .t2ex_i(t2ex),
   `endif
	
	`ifdef LP805X_NTC
		.pin_cnt(pin_cnt),
		.pin(pin),
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
//lp805x_xram lp805x_xram1 (.clk(clk), .rst(rst), .wr(write_xram), .addr(ext_addr), 
//.data_in(data_out), .data_out(data_out_xram), .ack(ack_xram), .stb(stb_o));

//myaltera_xram lp805x_xram1(
//	.aclr(rst),
//	.address(ext_addr),
//	.clock(clk),
//	.data(data_out),
//	.rden(1'b1),
//	.wren(write_xram),
//	.q(data_out_xram)
//	);

//defparam lp805x_xram1.DELAY = 2;

`ifdef LP805X_SERIAL

//
// test programs with serial interface
//
lp805x_serial lp805x_serial1(.clk(clk), .rst(rst), .rxd(txd), .txd(rxd));

defparam lp805x_serial1.FREQ  = FREQ;
//defparam lp805x_serial1.BRATE = 9.6;
defparam lp805x_serial1.BRATE = 4.8;


`else

//
// external uart
//
//lp805x_uart_test lp805x_uart_test1(.clk(clk), .rst(rst), .addr(ext_addr[7:0]), .wr(write_uart),
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
repeat(2)@(posedge clk);
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
  
  /*
always @(posedge clk)
  if (op_cur===8'h8b) begin
  
	if ( op2===8'h09) begin
    $display("time %t => Catch ADEOS main! Nice", $time);
	
    $finish;
	 end
	 
  end
  */
  /*
    always @(posedge clk)
  if (op_cur===8'h8a) begin
  
	if ( op2===8'h08) begin
		
	//if ( op3===8'heb) begin
    $display("time %t => Catch 211A mov v0,r2", $time);
	
    $finish;
	 //end
	 
	 end
	 
  end
  */
 /* 
  always @(posedge clk)
  if (op_cur===8'h12) begin
  
	if ( op2===8'h26) begin
		if ( op3===8'h0c) begin
    $display("time %t => Catch pStack = new char[stacksize]", $time);
	
    $finish;
	 end
	 end
	 
  end
  */
/*
always @(addr)
  if (addr===16'h20da) begin
    $display("time %t => Catch 20da add!", $time);
	
    $finish;
  end
*/
/*
always @(posedge clk)
  if (data_in===8'hzz) begin
    $display("time %t => Z in data_in!", $time);
	
    $finish;
  end
  */
  
  // synthesis translate_off

// catch P0=II
always @(op_cur or imm)
  if ((op_cur==8'h75) && (imm==8'h80)) begin
    $display("time %t => catch P0=!!!", $time);

  end
  
//catch a LCALL ?FLT_MUL
always @(op_cur or imm or imm2)
  if ((op1==8'h12) && (imm==8'h02) && (imm2==8'h40)) begin
    $display("time %t => catch LCALL ?FLT_MUL", $time);

  end
  
//catch a LCALL __start_call_ctors
always @(op_cur or imm or imm2)
  if ((op1==8'h12) && (imm==8'h25) && (imm2==8'hA8)) begin
    $display("time %t => catch LCALL __start_call_ctors", $time);

  end

//catch a LCALL main
always @(op_cur or imm or imm2)
  if ((op_cur==8'h12) && (imm==8'h1E) && (imm2==8'h1A)) begin
    $display("time %t => catch LCALL main", $time);

  end
  
//catch a LCALL ?CALL_IND
always @(op_cur or imm or imm2)
  if ((op_cur==8'h12) && (imm==8'h0A) && (imm2==8'h29)) begin
    $display("time %t => catch LCALL ?CALL_IND", $time);

  end
  
//catch a LCALL ?FUNC_ENTER_XDATA
always @(op_cur or imm or imm2)
  if ((op_cur==8'h12) && (imm==8'h0A) && (imm2==8'h2B)) begin
    $display("time %t => catch LCALL ?FUNC_ENTER_XDATA", $time);

  end
  
//catch a LJMP ?FUNC_LEAVE_XDATA
always @(op_cur or imm or imm2)
  if ((op_cur==8'h02) && (imm==8'h0A) && (imm2==8'h91)) begin
    $display("time %t => catch LJMP ?FUNC_LEAVE_XDATA", $time);

  end
// synthesis translate_on



endmodule
