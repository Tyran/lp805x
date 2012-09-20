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

// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"

module lp805x_top (
		wb_rst_i, 
		wb_clk_i,
//interface to instruction rom
`ifndef LP805X_ROM_ONCHIP
		wbi_adr_o, 
		wbi_dat_i, 
		wbi_stb_o, 
		wbi_ack_i, 
		wbi_cyc_o, 
		wbi_err_i,
`endif		
//interface to data ram
`ifndef LP805X_XRAM_ONCHIP
		wbd_dat_i, 
		wbd_dat_o,
		wbd_adr_o, 
		wbd_we_o, 
		wbd_ack_i,
		wbd_stb_o, 
		wbd_cyc_o, 
		wbd_err_i,
`endif

// interrupt interface
	//	int0_i, 
	//	int1_i,

// port interface
  `ifdef LP805X_PORTS
	`ifdef LP805X_PORT0
		p0_i,
		p0_o,
	`endif

	`ifdef LP805X_PORT1
		p1_i,
		p1_o,
	`endif

	`ifdef LP805X_PORT2
		p2_i,
		p2_o,
	`endif

	`ifdef LP805X_PORT3
		p3_i,
		p3_o,
	`endif
  `endif

// serial interface
	`ifdef LP805X_UART
		rxd_i, txd_o,
	`endif

// counter interface
	`ifdef LP805X_TC01
		t0_i, t1_i,
	`endif

	`ifdef LP805X_TC2
		t2_i, t2ex_i,
	`endif
	
	`ifdef LP805X_NTC
		pin_cnt,
		pin,
	`endif

// external access (active low)
		ea_in
		);

input				wb_rst_i,		// reset input
					wb_clk_i;		// clock input		
				  
wire				wb_rst_s;
wire				wb_rst_w;
wire				wb_clk_cpu;				  
				  
wire           int0_i,		// interrupt 0
					int1_i;		// interrupt 1
input				ea_in;		// external access
			  
`ifndef LP805X_ROM_ONCHIP		  
		input   			wbi_ack_i,	// instruction acknowlage
							wbi_err_i;	// instruction error
		input [31:0]	wbi_dat_i;	// rom data input
		output	      wbi_stb_o,	// instruction strobe
							wbi_cyc_o;	// instruction cycle
		output [15:0]	wbi_adr_o;	// instruction address
		output 			wbd_we_o,	// data write enable
							wbd_stb_o,	// data strobe
							wbd_cyc_o;	// data cycle
`endif

//
// cpu to cache/wb_interface
wire        iack_i,
				istb_o;
//wire			icyc_o;
wire [31:0]	idat_i;
wire [15:0] iadr_o;

`ifndef LP805X_XRAM_ONCHIP
	input [7:0]		wbd_dat_i;	// ram data input
	input				wbd_ack_i,	// data acknowledge
						wbd_err_i;	// data error
	output [7:0]	wbd_dat_o;	// data output
	output [15:0]	wbd_adr_o;	// data address
`else
	wire [7:0]		wbd_dat_i;	// ram data input
	wire				wbd_ack_i,	// data acknowledge
						wbd_err_i;	// data error
	wire [7:0]		wbd_dat_o;	// data output
	wire [15:0]		wbd_adr_o;	// data address
`endif

`ifdef LP805X_PORTS

	`ifdef LP805X_PORT0
	input  [7:0]  p0_i;		// port 0 input
	output [7:0]  p0_o;		// port 0 output
	`endif

	`ifdef LP805X_PORT1
	input  [7:0]  p1_i;		// port 1 input
	output [7:0]  p1_o;		// port 1 output
	`endif

	`ifdef LP805X_PORT2
	input  [7:0]  p2_i;		// port 2 input
	output [7:0]  p2_o;		// port 2 output
	`endif

	`ifdef LP805X_PORT3
	input  [7:0]  p3_i;		// port 3 input
	output [7:0]  p3_o;		// port 3 output
	`endif

`endif


`ifdef LP805X_UART
	input         rxd_i;		// receive
	output        txd_o;		// transnmit
`endif

`ifdef LP805X_TC01
	input         t0_i,		// counter 0 input
					  t1_i;		// counter 1 input
`endif

`ifdef LP805X_TC2
	input         t2_i,		// counter 2 input
					  t2ex_i;		//
`endif

wire [7:0]	dptr_hi,
				dptr_lo, 
				ri, 
				data_out,
            op1,
            op2,
				op3,
            acc,
				acc_bypass,
            p0_out,
				p1_out,
				p2_out,
				p3_out,
            sp,
            sp_w;

wire [31:0] idat_onchip;

wire [15:0] pc,dptr;

//assign wbd_cyc_o = wbd_stb_o;

wire [1:0]  src_sel3;
wire [1:0]  wr_sfr;
wire [2:0]  src_sel2;
wire [2:0]  ram_rd_sel,	// ram read
            ram_wr_sel;	// ram write
wire [3:0]  src_sel1;

wire [7:0]  ram_data,
            ram_out,	//data from ram
				wr_dat,
            wr_addr,	//ram write addres
            rd_addr;	//data ram read addres

tri [7:0] 	sfr_out;				
				
wire        sfr_bit;

wire [1:0]  cy_sel,	//carry select; from decoder to cy_selct1
            bank_sel;
wire        rom_addr_sel,	//rom addres select; alu or pc
            rmw,
				ea_int;

wire        reti,
            intr,
				int_ack,
				istb;
wire [7:0]  int_src;

wire        mem_wait;
wire [2:0]  mem_act;
wire [3:0]  alu_op;	//alu operation (from decoder)
wire [1:0]  psw_set;    //write to psw or not; from decoder to psw (through register)

wire [7:0]  src1,	//alu sources 1
            src2,	//alu sources 2
            src3,	//alu sources 3
				des_acc,
				des1,	//alu destination 1
				des2;	//alu destinations 2
wire        desCy,	//carry out
            desAc,
				desOv,	//overflow
				alu_cy,
				wr,		//write to data ram
				wr_o;

wire        rd,		//read program rom
            pc_wr;
wire [2:0]  pc_wr_sel;	//program counter write select (from decoder to pc)

wire [7:0]  op1_n, //from memory_interface to decoder
            op2_n,
				op3_n;

wire [1:0]  comp_sel;	//select source1 and source2 to compare
wire        eq,		//result (from comp1 to decoder)
            srcAc,
				cy,
				//rd_ind,
				wr_ind,
				comp_wait;
wire [2:0]  op1_cur;

wire        bit_addr,	//bit addresable instruction
            bit_data,	//bit data from ram to ram_select
				bit_out,	//bit data from ram_select to alu and cy_select
				bit_addr_o,
				wait_data;
reg 			wr_bit_r;

//always @(posedge wb_clk_cpu or posedge wb_rst_w)
//begin
//  if (wb_rst_w) begin
//    wr_bit_r <= 1'b0;
//  end else begin
//    wr_bit_r <= #1 bit_addr_o;
//  end
//end

wire sfr_wait;	
wire need_sync;

// sfr bus for peripherals...
// sync to async, not suited for cpu sync sfr's
	wire [28:0] sfr_bus_I;
`ifdef LP805X_MULTIFREQ
	lp805x_sfrbuse sfrbusI_1
	(
		.clk(wb_clk_cpu),
		.wr_addr(wr_addr[7:0]),
		.rd_addr(rd_addr[7:0]),
		.data_in(wr_dat),
		.wr(wr_o && !wr_ind),
		.rd(!(wr_o && !wr_ind)),
		.bit_in(desCy),
		.wr_bit(wr_bit_r),
		.rd_bit(1'b1),
		.load( need_sync),
		.sfr_bus( sfr_bus_I)
   );
`endif
	
`ifdef LP805X_CLKER

wire wb_rst_p1;
wire wb_clk_p1;

	lp805x_clker clkctrl
		( 
			.rsti( ~wb_rst_i),
			.clki( wb_clk_i),
			.bit_in(desCy),
			.bit_out(sfr_bit),
			.data_in(wr_dat),
			.data_out(sfr_out),
			.wr(wr_o && !wr_ind),
			.rd(!(wr_o && !wr_ind)),
			.wr_bit(wr_bit_r),
			.rd_bit(1'b1),
			.wr_addr(wr_addr[7:0]),
			.rd_addr(rd_addr[7:0]),

			.rst( wb_rst_s), .clk( wb_clk_cpu), //[SPECIAL FEATURE]
			.rst_p1( wb_rst_p1), .clk_p1o( wb_clk_p1) //[SPECIAL FEATURE]
		);

`else

	assign 
		wb_rst_s = ~wb_rst_i,
		wb_clk_cpu = wb_clk_i;
		
`endif	

`ifdef LP805X_HWSCHED

	lp805x_schedfs hwsched_1
		(
			.rst( wb_rst_w),
			.clk( wb_clk_cpu),
			.bit_in(desCy),
			.bit_out(sfr_bit),
			.data_in(wr_dat),
			.data_out(sfr_out),
			.wr(wr_o && !wr_ind),
			.rd(!(wr_o && !wr_ind)),
			.wr_bit(wr_bit_r),
			.rd_bit(1'b1),
			.wr_addr(wr_addr[7:0]),
			.rd_addr(rd_addr[7:0])
		);

`endif

`ifdef LP805X_WDT

	lp805x_wdt wdt_1
		(
			.rsti( wb_rst_s),
			.clk( wb_clk_cpu),
			.bit_in(desCy),
			.bit_out(sfr_bit),
			.data_in(wr_dat),
			.data_out(sfr_out),
			.wr(wr_o && !wr_ind),
			.rd(!(wr_o && !wr_ind)),
			.wr_bit(wr_bit_r),
			.rd_bit(1'b1),
			.wr_addr(wr_addr[7:0]),
			.rd_addr(rd_addr[7:0]),
			.rst( wb_rst_w)
		);

`else
	assign wb_rst_w = wb_rst_s;

`endif

`ifdef LP805X_AES

	lp805x_aes aesp_1
		(
			.rst( wb_rst_w),
			.clk( wb_clk_cpu),
			.bit_in(desCy),
			.bit_out(sfr_bit),
			.data_in(wr_dat),
			.data_out(sfr_out),
			.wr(wr_o && !wr_ind),
			.rd( !sfr_wait & (ram_rd_sel == `LP805X_RRS_D)),
			.wr_bit(wr_bit_r),
			.rd_bit(1'b1),
			.wr_addr(wr_addr[7:0]),
			.rd_addr(rd_addr[7:0])
		);

`endif

`ifdef LP805X_RAND

	lp805x_rand rnd_1
		(
			.rst( wb_rst_w),
			.clk( wb_clk_cpu),
			.bit_in(desCy),
			.bit_out(sfr_bit),
			.data_in(wr_dat),
			.data_out(sfr_out),
			.wr(wr_o && !wr_ind),
			.rd( !sfr_wait & (ram_rd_sel == `LP805X_RRS_D)),
			.wr_bit(wr_bit_r),
			.rd_bit(1'b1),
			.wr_addr(wr_addr[7:0]),
			.rd_addr(rd_addr[7:0])
		);

`endif

//
// decoder
lp805x_decoder decoder_1
					(
					 .clk(wb_clk_cpu), 
                .rst(wb_rst_w), 
			       .op_in(op1_n), 
			       .op1_c(op1_cur),
			       .ram_rd_sel_o(ram_rd_sel), 
			       .ram_wr_sel_o(ram_wr_sel), 
			       .bit_addr(bit_addr),

			       .src_sel1(src_sel1),
			       .src_sel2(src_sel2),
			       .src_sel3(src_sel3),

			       .alu_op_o(alu_op),
			       .psw_set(psw_set),
			       .cy_sel(cy_sel),
			       .wr_o(wr),
			       .pc_wr(pc_wr),
			       .pc_sel(pc_wr_sel),
			       .comp_sel(comp_sel),
			       .eq(eq),
			       .wr_sfr_o(wr_sfr),
			       .rd(rd),
					 `ifdef LP805X_PORTS
			       .rmw(rmw),
					 `endif
			       .istb(istb),
			       .mem_act(mem_act),
			       .mem_wait(mem_wait),
			       .wait_data(wait_data | sfr_wait)
					);


wire [7:0] sub_result;
//
//alu
lp805x_alu  alu_1(.rst(wb_rst_w),
                       .clk(wb_clk_cpu),
		       .op_code(alu_op),
		       .src1(src1),
		       .src2(src2),
		       .src3(src3),
		       .srcCy(alu_cy),
		       .srcAc(srcAc),
		       .des_acc(des_acc),
		       .sub_result(sub_result),
		       .des1(des1),
		       .des2(des2),
		       .desCy(desCy),
		       .desAc(desAc),
		       .desOv(desOv),
		       .bit_in(bit_out));

//
//data ram
lp805x_ram_top  dataram_1(.clk(wb_clk_cpu),
                               .rst(wb_rst_w),
			       .rd_addr(rd_addr),
			       .rd_data(ram_data),
			       .wr_addr(wr_addr),
			       .bit_addr(bit_addr_o),
			       .wr_data(wr_dat),
			       .wr(wr_o && (!wr_addr[7] || wr_ind)),
			       .bit_data_in(desCy),
			       .bit_data_out(bit_data)
			       );

//

lp805x_alu_src_sel alu_src_sel_1(.clk(wb_clk_cpu),
                                       .rst(wb_rst_w),
				       .rd(rd),

				       .sel1(src_sel1),
				       .sel2(src_sel2),
				       .sel3(src_sel3),

				       .acc(acc),
				       .ram(ram_out),
				       .pc(pc),
				       .dptr({dptr_hi, dptr_lo}),
				       .op1(op1_n),
				       .op2(op2_n),
				       .op3(op3_n),

				       .src1(src1),
				       .src2(src2),
				       .src3(src3));


//
//
lp805x_comp compare_1(.sel(comp_sel),
                         .eq(eq),
			 .b_in(bit_out),
			 .cy(cy),
			 .acc(acc),
			 .des(sub_result)
			 );


//
//program rom
`ifdef LP805X_ROM_ONCHIP
  lp805x_rom rom_1
			(
				.rst(wb_rst_w),
				.clk(wb_clk_cpu),
				.ea_int(ea_int),
				.addr(iadr_o),
				.data_o(idat_onchip)
			);
`else
	assign ea_int = 1'b1;
	assign idat_onchip = 32'h0;
  
  `ifdef LP805X_SIMULATION

    initial
    begin
      $display("\t * ");
      $display("\t * Internal rom disabled!!!");
      $display("\t * ");
    end

  `endif

`endif

//
//
lp805x_cy_select cy_select_1(.cy_sel(cy_sel), 
                                   .cy_in(cy), 
				   .data_in(bit_out),
				   .data_out(alu_cy));
//
//
lp805x_indi_addr indi_addr_1 (.clk(wb_clk_cpu), 
                                    .rst(wb_rst_w), 
				    .wr_addr(wr_addr),
				    .data_in(wr_dat),
				    .wr(wr_o),
				    .wr_bit(bit_addr_o), 
				    .ri_out(ri),
				    .sel(op1_cur[0]),
				    .bank(bank_sel));

//
// ports
// P0, P1, P2, P3
`ifdef LP805X_PORTS

wire sfr_wrdy_io;
wire sfr_rrdy_io;
	 	
  lp805x_ports ports_1(
				.clk_cpu(wb_clk_cpu),
				.clk(wb_clk_p1),
            .rst(wb_rst_w),
				.sfr_bus( sfr_bus_I),
				.bit_out(sfr_bit),
				.data_out(sfr_out),
				.sfr_get(sfr_get),
				.sfr_wrdy(sfr_wrdy_io),
				.sfr_rrdy(sfr_rrdy_io),
				.sfr_put(sfr_put),

		`ifdef LP805X_PORT0
			   .p0_out(p0_o),
			   .p0_in(p0_i),
		`endif

		`ifdef LP805X_PORT1
			   .p1_out(p1_o),
			   .p1_in(p1_i),
		`endif

		`ifdef LP805X_PORT2
			   .p2_out(p2_o),
			   .p2_in(p2_i),
		`endif

		`ifdef LP805X_PORT3
			   .p3_out(p3_o),
			   .p3_in(p3_i),
		`endif

			   .rmw(rmw));
`endif	

`ifdef LP805X_NTC
// new timer
wire ntf0,ntr0;

wire sfr_wrdy_nt;
wire sfr_rrdy_nt;

	parameter PWMS_LEN=1;
	input				pin_cnt;
	output 	[PWMS_LEN-1:0]		pin;

lp805x_newtimer #(.PWMS_LEN(PWMS_LEN)) ntimer_1
	(
		.clk_cpu(wb_clk_cpu),
		.clk(wb_clk_p1),
		.rst(wb_rst_w),
		.sfr_bus( sfr_bus_I),
		.bit_out(sfr_bit),
		.data_out(sfr_out),
		.sfr_get(sfr_get),
		.sfr_wrdy(sfr_wrdy_nt),
		.sfr_rrdy(sfr_rrdy_nt),
		.sfr_put(sfr_put),
		
		.ntf(ntf0),
		.ntr(ntr0),
		.pin_cnt(pin_cnt),
		.pin(pin)
    );
`endif

//assign icyc_o = istb_o;
//
//
lp805x_control control_interface_1
		(
			.clk(wb_clk_cpu), 
         .rst(wb_rst_w),
// internal ram
			.wr_i(wr), 
			.wr_o(wr_o), 
			.wr_bit_i(bit_addr), 
			.wr_bit_o(bit_addr_o), 
			.wr_dat(wr_dat),
			.des_acc(des_acc),
			.des1(des1),
			.des2(des2),
			.rd_addr(rd_addr),
			.wr_addr(wr_addr),
			.wr_ind(wr_ind),
			.bit_in(bit_data),
			.in_ram(ram_data),
			.sfr(sfr_out),
			.sfr_bit(sfr_bit),
			.bit_out(bit_out),
			.iram_out(ram_out),

// external instruction rom
			.iack_i(iack_i),
			.iadr_o(iadr_o),
			.idat_i(idat_i),
			//.istb_o(istb_o),

// internal instruction rom
			.idat_onchip(idat_onchip),

// data memory
			.dadr_o(wbd_adr_o),
			.ddat_o(wbd_dat_o),
			.dwe_o(wbd_we_o),
			.dstb_o(wbd_stb_o),
			.ddat_i(wbd_dat_i),
			.dack_i(wbd_ack_i),

// from decoder
			.rd_sel(ram_rd_sel),
			.wr_sel(ram_wr_sel),
			.rn({bank_sel, op1_cur}),
			//.rd_ind(rd_ind),
			.rd(rd),
			.mem_act(mem_act),
			.mem_wait(mem_wait),

// external access
			.ea(ea_in),
			.ea_int(ea_int),

// instructions outputs to cpu
			.op1_out(op1_n),
			.op2_out(op2_n),
			.op3_out(op3_n),

// interrupt interface
			.intr(intr), 
			.int_v(int_src), 
			.int_ack(int_ack), 
			.istb(istb),
			.reti(reti),

//pc
			.pc_wr_sel(pc_wr_sel), 
			.pc_wr(pc_wr & comp_wait),
			.pc(pc),

// sfr's
			`ifdef LP805X_MULTIFREQ
			.sfr_put(sfr_put),
			.sfr_get(sfr_get),
			.sfr_wrdy({sfr_wrdy_io,sfr_wrdy_nt}),
			.sfr_rrdy({sfr_rrdy_io,sfr_rrdy_nt}),
			.need_sync(need_sync),
			.sfr_wait(sfr_wait),
			`endif
			.sp_w(sp_w), 
			.dptr({dptr_hi, dptr_lo}),
			.dptr_bypass( dptr),
			.ri(ri), 
			.acc(acc),
			.acc_bypass(acc_bypass),
			.sp(sp)
		);

				 
//
//			XDATA internal				 
				 
				 
lp805x_xdatai xdatai_1( 
				.clk(wb_clk_cpu), 
				.rst(wb_rst_w), 
				.addr(wbd_adr_o), 
				.data_i(wbd_dat_o), 
				.data_o(wbd_dat_i), 
				.wr(wbd_we_o), 
				.stb(wbd_stb_o), 
				.ack(wbd_ack_i)
				);					

//
//

lp805x_sfr sfr_1(
				.rst(wb_rst_w), 
				.clk(wb_clk_cpu), 
		      .adr0(rd_addr[7:0]), 
		      .adr1(wr_addr[7:0]),
		      .data_out(sfr_out),
		      .dat1(wr_dat),
		      .dat2(des2),
		      .des_acc(des_acc),
		      .we(wr_o && !wr_ind),
		      .bit_in(desCy),
		      .bit_out(sfr_bit), 
		      .wr_bit(bit_addr_o),
		      .ram_rd_sel(ram_rd_sel),
		      .ram_wr_sel(ram_wr_sel),
		      .wr_sfr(wr_sfr),
		      .comp_sel(comp_sel),
		      .comp_wait(comp_wait),
// acc
		      .acc(acc),
				.acc_bypass(acc_bypass),
// sp
		      .sp(sp), 
		      .sp_w(sp_w),
// psw
		      .bank_sel(bank_sel), 
		      .desAc(desAc), 
		      .desOv(desOv), 
		      .psw_set(psw_set),
		      .srcAc(srcAc), 
		      .cy(cy),
// uart
	`ifdef LP805X_UART
		       .rxd(rxd_i), .txd(txd_o),
	`endif

// int
		       .int_ack(int_ack),
		       .intr(intr),
		       .int0(int0_i),
		       .int1(int1_i),
		       .reti(reti),
		       .int_src(int_src),
				 
				 .ntf(ntf0),
				 .ntr(ntr0),

// t/c 0,1
	`ifdef LP805X_TC01
		       .t0(t0_i),
		       .t1(t1_i),
	`endif

// t/c 2
	`ifdef LP805X_TC2
		       .t2(t2_i),
		       .t2ex(t2ex_i),
	`endif

// dptr
		       .dptr_hi(dptr_hi),
		       .dptr_lo(dptr_lo),
				 .dptr(dptr),
		       .wait_data(wait_data)
		       );

  `ifdef LP805X_WB

    lp805x_wb_iinterface wb_iinterface_1(.rst(wb_rst_w), .clk(wb_clk_cpu),
    // cpu
        .adr_i(iadr_o),
	.dat_o(idat_i),
	.stb_i(istb_o),
	.ack_o(iack_i),
        .cyc_i(icyc_o),
    // external rom
        .dat_i(wbi_dat_i),
	.stb_o(wbi_stb_o),
	.adr_o(wbi_adr_o),
	.ack_i(wbi_ack_i),
        .cyc_o(wbi_cyc_o));

  `ifdef LP805X_SIMULATION

    initial
    begin
      #1
      $display("\t * ");
      $display("\t * External rom interface: WB interface");
      $display("\t * ");
    end

  `endif

  `else
`ifndef LP805X_ROM_ONCHIP
    assign wbi_adr_o = iadr_o    ;
	 //assign wbi_dat_i = idat_onchip;
    assign idat_i    = wbi_dat_i ;
    assign wbi_stb_o = 1'b1      ;
    assign iack_i    = wbi_ack_i ;
    assign wbi_cyc_o = 1'b1      ;
`endif
  `ifdef LP805X_SIMULATION

    initial
    begin
      #1
      $display("\t * ");
      $display("\t * External rom interface: Pipelined interface");
      $display("\t * ");
    end

  `endif


`endif



endmodule
