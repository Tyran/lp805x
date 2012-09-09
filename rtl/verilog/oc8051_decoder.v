//////////////////////////////////////////////////////////////////////
////                                                              ////
////  8051 core decoder                                           ////
////                                                              ////
////  This file is part of the 8051 cores project                 ////
////  http://www.opencores.org/cores/8051/                        ////
////                                                              ////
////  Description                                                 ////
////   Main 8051 core module. decodes instruction and creates     ////
////   control sigals.                                            ////
////                                                              ////
////  To Do:                                                      ////
////   optimize state machine, especially IDS ASS and AS3         ////
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
// Revision 1.21  2003/06/03 17:09:57  simont
// pipelined acces to axternal instruction interface added.
//
// Revision 1.20  2003/05/06 11:10:38  simont
// optimize state machine.
//
// Revision 1.19  2003/05/06 09:41:35  simont
// remove define LP805X_AS2_PCL, chane signal src_sel2 to 2 bit wide.
//
// Revision 1.18  2003/05/05 15:46:36  simont
// add aditional alu destination to solve critical path.
//
// Revision 1.17  2003/04/25 17:15:51  simont
// change branch instruction execution (reduse needed clock periods).
//
// Revision 1.16  2003/04/09 16:24:03  simont
// change wr_sft to 2 bit wire.
//
// Revision 1.15  2003/04/09 15:49:42  simont
// Register LP805X_sfr dato output, add signal wait_data.
//
// Revision 1.14  2003/01/13 14:14:40  simont
// replace some modules
//
// Revision 1.13  2002/10/23 16:53:39  simont
// fix bugs in instruction interface
//
// Revision 1.12  2002/10/17 18:50:00  simont
// cahnge interface to instruction rom
//
// Revision 1.11  2002/09/30 17:33:59  simont
// prepared header
//
//

// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"


module lp805x_decoder (clk, rst, op_in, op1_c,
  ram_rd_sel_o, ram_wr_sel_o,
  bit_addr, wr_o, wr_sfr_o,
  src_sel1, src_sel2, src_sel3,
  alu_op_o, psw_set, eq, cy_sel, comp_sel,
  pc_wr, pc_sel, rd, rmw, istb, mem_act, mem_wait,
  wait_data
  );

//
// clk          (in)  clock
// rst          (in)  reset
// op_in        (in)  operation code [LP805X_op_select.op1]
// eq           (in)  compare result [LP805X_comp.eq]
// ram_rd_sel   (out) select, whitch address will be send to ram for read [LP805X_ram_rd_sel.sel, LP805X_sp.ram_rd_sel]
// ram_wr_sel   (out) select, whitch address will be send to ram for write [LP805X_ram_wr_sel.sel -r, LP805X_sp.ram_wr_sel -r]
// wr           (out) write - if 1 then we will write to ram [LP805X_ram_top.wr -r, LP805X_acc.wr -r, LP805X_b_register.wr -r, LP805X_sp.wr-r, LP805X_dptr.wr -r, LP805X_psw.wr -r, LP805X_indi_addr.wr -r, LP805X_ports.wr -r]
// src_sel1     (out) select alu source 1 [LP805X_alu_src1_sel.sel -r]
// src_sel2     (out) select alu source 2 [LP805X_alu_src2_sel.sel -r]
// src_sel3     (out) select alu source 3 [LP805X_alu_src3_sel.sel -r]
// alu_op       (out) alu operation [LP805X_alu.op_code -r]
// psw_set      (out) will we remember cy, ac, ov from alu [LP805X_psw.set -r]
// cy_sel       (out) carry in alu select [LP805X_cy_select.cy_sel -r]
// comp_sel     (out) compare source select [LP805X_comp.sel]
// bit_addr     (out) if instruction is bit addresable [LP805X_ram_top.bit_addr -r, LP805X_acc.wr_bit -r, LP805X_b_register.wr_bit-r, LP805X_sp.wr_bit -r, LP805X_dptr.wr_bit -r, LP805X_psw.wr_bit -r, LP805X_indi_addr.wr_bit -r, LP805X_ports.wr_bit -r]
// pc_wr        (out) pc write [LP805X_pc.wr]
// pc_sel       (out) pc select [LP805X_pc.pc_wr_sel]
// rd           (out) read from rom [LP805X_pc.rd, LP805X_op_select.rd]
// reti         (out) return from interrupt [pin]
// rmw          (out) read modify write feature [LP805X_ports.rmw]
// pc_wait      (out)
//

input clk, rst, eq, mem_wait, wait_data;
input [7:0] op_in;

output wr_o, bit_addr, pc_wr, rmw, istb;
output [1:0] psw_set, cy_sel, wr_sfr_o, comp_sel, src_sel3;
output [2:0] mem_act, ram_rd_sel_o, ram_wr_sel_o, pc_sel, op1_c, src_sel2;
output [3:0] alu_op_o, src_sel1;
output rd;

reg rmw;
reg wr,  bit_addr, pc_wr;
reg [1:0] src_sel3;
reg [3:0] alu_op;
reg [1:0] comp_sel, psw_set, cy_sel, wr_sfr;
reg [2:0] src_sel2;
reg [2:0] ram_wr_sel, ram_rd_sel, pc_sel;
reg [3:0] src_sel1;
//reg mem_act, 
//
// state        if 2'b00 then normal execution, sle instructin that need more than one clock
// op           instruction buffer
reg  [1:0] state;
wire [1:0] state_dec;
reg  [7:0] op;
wire [7:0] op_cur;
reg  [2:0] ram_rd_sel_r;

reg stb_i;

assign rd = !state[0] && !state[1] && !wait_data;// && !stb_o;

assign istb = (!state[1]) && stb_i;

assign state_dec = wait_data ? 2'b00 : state;

assign op_cur = mem_wait ? 8'h00
                : (state[0] || state[1] || mem_wait || wait_data) ? op : op_in;
//assign op_cur = (state[0] || state[1] || mem_wait || wait_data) ? op : op_in;

assign op1_c = op_cur[2:0];

assign alu_op_o     = wait_data ? `LP805X_ALU_NOP : alu_op;
assign wr_sfr_o     = wait_data ? `LP805X_WRS_N   : wr_sfr;
assign ram_rd_sel_o = wait_data ? ram_rd_sel_r    : ram_rd_sel;
assign ram_wr_sel_o = wait_data ? `LP805X_RWS_DC  : ram_wr_sel;
assign wr_o         = wait_data ? 1'b0            : wr;

//
// main block
// unregisterd outputs
always @(op_cur or eq or state_dec or mem_wait)
begin
    case (state_dec) /* previous full_mask parallel_mask */
      2'b01: begin
        casex (op_cur) /* previous parallell_mask */
          `LP805X_DIV : begin
              ram_rd_sel = `LP805X_RRS_B;
            end
          `LP805X_MUL : begin
              ram_rd_sel = `LP805X_RRS_B;
            end
          default begin
              ram_rd_sel = `LP805X_RRS_DC;
          end
        endcase
        stb_i = 1'b1;
        bit_addr = 1'b0;
        pc_wr = `LP805X_PCW_N;
        pc_sel = `LP805X_PIS_DC;
        comp_sel =  `LP805X_CSS_DC;
        rmw = `LP805X_RMW_N;
      end
      2'b10: begin
        casex (op_cur) /* previous parallell_mask */
          `LP805X_SJMP : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_DC;
              bit_addr = 1'b0;
            end
          `LP805X_JC : begin
              ram_rd_sel = `LP805X_RRS_PSW;
              pc_wr = eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_CY;
              bit_addr = 1'b0;
            end
          `LP805X_JNC : begin
              ram_rd_sel = `LP805X_RRS_PSW;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_CY;
              bit_addr = 1'b0;
            end
          `LP805X_JNZ : begin
              ram_rd_sel = `LP805X_RRS_ACC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_AZ;
              bit_addr = 1'b0;
            end
          `LP805X_JZ : begin
              ram_rd_sel = `LP805X_RRS_ACC;
              pc_wr = eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_AZ;
              bit_addr = 1'b0;
            end

          `LP805X_RET : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_AL;
              comp_sel =  `LP805X_CSS_DC;
              bit_addr = 1'b0;
            end
          `LP805X_RETI : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_AL;
              comp_sel =  `LP805X_CSS_DC;
              bit_addr = 1'b0;
            end
          `LP805X_CJNE_R : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_DES;
              bit_addr = 1'b0;
            end
          `LP805X_CJNE_I : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_DES;
              bit_addr = 1'b0;
            end
          `LP805X_CJNE_D : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_DES;
              bit_addr = 1'b0;
            end
          `LP805X_CJNE_C : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_DES;
              bit_addr = 1'b0;
            end
          `LP805X_DJNZ_R : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_DES;
              bit_addr = 1'b0;
            end
          `LP805X_DJNZ_D : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_DES;
              bit_addr = 1'b0;
            end
          `LP805X_JB : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_BIT;
              bit_addr = 1'b0;
            end
          `LP805X_JBC : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_BIT;
              bit_addr = 1'b1;
            end
          `LP805X_JMP_D : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_ALU;
              comp_sel =  `LP805X_CSS_DC;
              bit_addr = 1'b0;
            end
          `LP805X_JNB : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_BIT;
              bit_addr = 1'b1;
            end
          `LP805X_DIV : begin
              ram_rd_sel = `LP805X_RRS_B;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              bit_addr = 1'b0;
            end
          `LP805X_MUL : begin
              ram_rd_sel = `LP805X_RRS_B;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              bit_addr = 1'b0;
            end
          default begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              bit_addr = 1'b0;
          end
        endcase
        rmw = `LP805X_RMW_N;
        stb_i = 1'b1;
      end
      2'b11: begin
        casex (op_cur) /* previous parallell_mask */
          `LP805X_CJNE_R : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
          `LP805X_CJNE_I : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
          `LP805X_CJNE_D : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
          `LP805X_CJNE_C : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
          `LP805X_DJNZ_R : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
          `LP805X_DJNZ_D : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
          `LP805X_RET : begin
              ram_rd_sel = `LP805X_RRS_SP;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_AH;
            end
          `LP805X_RETI : begin
              ram_rd_sel = `LP805X_RRS_SP;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_AH;
            end
          `LP805X_DIV : begin
              ram_rd_sel = `LP805X_RRS_B;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
          `LP805X_MUL : begin
              ram_rd_sel = `LP805X_RRS_B;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
            end
         default begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
          end
        endcase
        comp_sel =  `LP805X_CSS_DC;
        rmw = `LP805X_RMW_N;
        stb_i = 1'b1;
        bit_addr = 1'b0;
      end
      2'b00: begin
        casex (op_cur) /* previous parallell_mask */
		  `LP805X_MOV_DD : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ACALL :begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_I11;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_AJMP : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_I11;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_ADD_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ADDC_R : begin
             ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ANL_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_CJNE_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_DEC_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_DJNZ_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_INC_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_MOV_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_MOV_DR : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_MOV_RD : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ORL_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_SUBB_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XCH_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XRL_R : begin
              ram_rd_sel = `LP805X_RRS_RN;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
    
    //op_code [7:1]
          `LP805X_ADD_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ADDC_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ANL_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_CJNE_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_DEC_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_INC_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_MOV_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_MOV_ID : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_MOV_DI : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_MOVX_IA : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_MOVX_AI :begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_ORL_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_SUBB_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XCH_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XCHD :begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XRL_I : begin
              ram_rd_sel = `LP805X_RRS_I;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
    
    //op_code [7:0]
          `LP805X_ADD_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ADDC_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ANL_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ANL_C : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ANL_DD : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ANL_DC : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ANL_B : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_ANL_NB : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_CJNE_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_CJNE_C : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_CLR_B : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_CPL_B : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_DEC_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_DIV : begin
              ram_rd_sel = `LP805X_RRS_B;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_DJNZ_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_INC_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_INC_DP : begin
              ram_rd_sel = `LP805X_RRS_DPTR;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_JB : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_BIT;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b1;
            end
          `LP805X_JBC : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_BIT;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b1;
            end
/*          `LP805X_JC : begin
              ram_rd_sel = `LP805X_RRS_PSW;
              pc_wr = eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_CY;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end*/
          `LP805X_JMP_D : begin
              ram_rd_sel = `LP805X_RRS_DPTR;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
    
          `LP805X_JNB : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_SO2;
              comp_sel =  `LP805X_CSS_BIT;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b1;
            end
/*          `LP805X_JNC : begin
              ram_rd_sel = `LP805X_RRS_PSW;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_CY;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_JNZ : begin
              ram_rd_sel = `LP805X_RRS_ACC;
              pc_wr = !eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_AZ;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_JZ : begin
              ram_rd_sel = `LP805X_RRS_ACC;
              pc_wr = eq;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_AZ;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end*/
          `LP805X_LCALL :begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_I16;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_LJMP : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_I16;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_MOV_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
//          `LP805X_MOV_DD : begin
//              ram_rd_sel = `LP805X_RRS_D;
//              pc_wr = `LP805X_PCW_N;
//              pc_sel = `LP805X_PIS_DC;
//              comp_sel =  `LP805X_CSS_DC;
//              rmw = `LP805X_RMW_N;
//              stb_i = 1'b1;
//              bit_addr = 1'b0;
//            end
          `LP805X_MOV_BC : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_MOV_CB : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_MOVC_DP :begin
              ram_rd_sel = `LP805X_RRS_DPTR;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_MOVC_PC : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_MOVX_PA : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_MOVX_AP : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_MUL : begin
              ram_rd_sel = `LP805X_RRS_B;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_ORL_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ORL_AD : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ORL_CD : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_ORL_B : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_ORL_NB : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
          `LP805X_POP : begin
              ram_rd_sel = `LP805X_RRS_SP;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_PUSH : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_RET : begin
              ram_rd_sel = `LP805X_RRS_SP;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_RETI : begin
              ram_rd_sel = `LP805X_RRS_SP;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end
          `LP805X_SETB_B : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b1;
            end
/*          `LP805X_SJMP : begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_Y;
              pc_sel = `LP805X_PIS_SO1;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b0;
              bit_addr = 1'b0;
            end*/
          `LP805X_SUBB_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XCH_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XRL_D : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XRL_AD : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          `LP805X_XRL_CD : begin
              ram_rd_sel = `LP805X_RRS_D;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_Y;
              stb_i = 1'b1;
              bit_addr = 1'b0;
            end
          default: begin
              ram_rd_sel = `LP805X_RRS_DC;
              pc_wr = `LP805X_PCW_N;
              pc_sel = `LP805X_PIS_DC;
              comp_sel =  `LP805X_CSS_DC;
              rmw = `LP805X_RMW_N;
              stb_i = 1'b1;
              bit_addr = 1'b0;
           end
        endcase
      end
    endcase
end










//
//
// registerd outputs

always @(posedge clk or posedge rst)
begin
  if (rst) begin
    ram_wr_sel <= #1 `LP805X_RWS_DC;
    src_sel1 <= #1 `LP805X_AS1_DC;
    src_sel2 <= #1 `LP805X_AS2_DC;
    alu_op <= #1 `LP805X_ALU_NOP;
    wr <= #1 1'b0;
    psw_set <= #1 `LP805X_PS_NOT;
    cy_sel <= #1 `LP805X_CY_0;
    src_sel3 <= #1 `LP805X_AS3_DC;
    wr_sfr <= #1 `LP805X_WRS_N;
  end else if (!wait_data) begin
    case (state_dec) /* previous parallell_mask */
      2'b01: begin
        casex (op_cur) /* previous parallell_mask */
          `LP805X_MOVC_DP :begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP1;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_MOVC_PC :begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP1;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_MOVX_PA : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP1;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_MOVX_IA : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP1;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
/*          `LP805X_ACALL :begin
              ram_wr_sel <= #1 `LP805X_RWS_SP;
              src_sel1 <= #1 `LP805X_AS1_PCH;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_AJMP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_LCALL :begin
              ram_wr_sel <= #1 `LP805X_RWS_SP;
              src_sel1 <= #1 `LP805X_AS1_PCH;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_N;
            end*/
          `LP805X_DIV : begin
              ram_wr_sel <= #1 `LP805X_RWS_B;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_DIV;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_OV;
              wr_sfr <= #1 `LP805X_WRS_ACC2;
            end
          `LP805X_MUL : begin
              ram_wr_sel <= #1 `LP805X_RWS_B;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_MUL;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_OV;
              wr_sfr <= #1 `LP805X_WRS_ACC2;
            end
          default begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              wr_sfr <= #1 `LP805X_WRS_N;
          end
        endcase
        cy_sel <= #1 `LP805X_CY_0;
        src_sel3 <= #1 `LP805X_AS3_DC;
      end
      2'b10: begin
        casex (op_cur) /* previous parallell_mask */
          `LP805X_ACALL :begin
              ram_wr_sel <= #1 `LP805X_RWS_SP;
              src_sel1 <= #1 `LP805X_AS1_PCH;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
            end
          `LP805X_LCALL :begin
              ram_wr_sel <= #1 `LP805X_RWS_SP;
              src_sel1 <= #1 `LP805X_AS1_PCH;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
            end
          `LP805X_JBC : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
            end
          `LP805X_DIV : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_DIV;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_OV;
            end
          `LP805X_MUL : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_MUL;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_OV;
            end
          default begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
          end
        endcase
        cy_sel <= #1 `LP805X_CY_0;
        src_sel3 <= #1 `LP805X_AS3_DC;
        wr_sfr <= #1 `LP805X_WRS_N;
      end

      2'b11: begin
        casex (op_cur) /* previous parallell_mask */
          `LP805X_RET : begin
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              psw_set <= #1 `LP805X_PS_NOT;
            end
          `LP805X_RETI : begin
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              psw_set <= #1 `LP805X_PS_NOT;
            end
          `LP805X_DIV : begin
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_DIV;
              psw_set <= #1 `LP805X_PS_OV;
            end
          `LP805X_MUL : begin
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_MUL;
              psw_set <= #1 `LP805X_PS_OV;
            end
         default begin
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              psw_set <= #1 `LP805X_PS_NOT;
          end
        endcase
        ram_wr_sel <= #1 `LP805X_RWS_DC;
        wr <= #1 1'b0;
        cy_sel <= #1 `LP805X_CY_0;
        src_sel3 <= #1 `LP805X_AS3_DC;
        wr_sfr <= #1 `LP805X_WRS_N;
      end
      default: begin
        casex (op_cur) /* previous parallell_mask */
		  `LP805X_MOV_DD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D3;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ACALL :begin
              ram_wr_sel <= #1 `LP805X_RWS_SP;
              src_sel1 <= #1 `LP805X_AS1_PCL;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_AJMP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ADD_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ADDC_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ANL_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_AND;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_CJNE_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_OP2;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_DEC_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_RN;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_DJNZ_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_RN;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_INC_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_RN;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_MOV_AR : begin
              ram_wr_sel <= #1 `LP805X_RWS_RN;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_DR : begin
              ram_wr_sel <= #1 `LP805X_RWS_RN;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_CR : begin
              ram_wr_sel <= #1 `LP805X_RWS_RN;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_RD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ORL_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_OR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_SUBB_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_XCH_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_RN;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XCH;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC2;
            end
          `LP805X_XRL_R : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XOR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
    
    //op_code [7:1]
          `LP805X_ADD_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ADDC_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ANL_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_AND;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_CJNE_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_OP2;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_DEC_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_I;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_INC_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_I;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_MOV_ID : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_AI : begin
              ram_wr_sel <= #1 `LP805X_RWS_I;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_DI : begin
              ram_wr_sel <= #1 `LP805X_RWS_I;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_CI : begin
              ram_wr_sel <= #1 `LP805X_RWS_I;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOVX_IA : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOVX_AI :begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ORL_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_OR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_SUBB_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_XCH_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_I;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XCH;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC2;
            end
          `LP805X_XCHD :begin
              ram_wr_sel <= #1 `LP805X_RWS_I;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XCH;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC2;
            end
          `LP805X_XRL_I : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XOR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
    
    //op_code [7:0]
          `LP805X_ADD_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ADD_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ADDC_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ADDC_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ANL_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_AND;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ANL_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_AND;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ANL_DD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_AND;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ANL_DC : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_OP3;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_AND;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ANL_B : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_AND;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ANL_NB : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_RR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_CJNE_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_CJNE_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_OP2;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_CLR_A : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_CLR_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_CLR_B : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_CPL_A : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOT;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_CPL_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOT;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_CPL_B : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOT;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_RAM;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_DA : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_DA;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_DEC_A : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_DEC_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_DIV : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_DIV;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_OV;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_DJNZ_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_INC_A : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_INC_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_INC;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_INC_DP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ZERO;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DP;
              wr_sfr <= #1 `LP805X_WRS_DPTR;
            end
          `LP805X_JB : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_JBC :begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_JC : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_JMP_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DP;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_JNB : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_JNC : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_JNZ :begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_JZ : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_LCALL :begin
              ram_wr_sel <= #1 `LP805X_RWS_SP;
              src_sel1 <= #1 `LP805X_AS1_PCL;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_LJMP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_MOV_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_MOV_DA : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
//          `LP805X_MOV_DD : begin
//              ram_wr_sel <= #1 `LP805X_RWS_D3;
//              src_sel1 <= #1 `LP805X_AS1_RAM;
//              src_sel2 <= #1 `LP805X_AS2_DC;
//              alu_op <= #1 `LP805X_ALU_NOP;
//              wr <= #1 1'b1;
//              psw_set <= #1 `LP805X_PS_NOT;
//              cy_sel <= #1 `LP805X_CY_0;
//              src_sel3 <= #1 `LP805X_AS3_DC;
//              wr_sfr <= #1 `LP805X_WRS_N;
//            end
          `LP805X_MOV_CD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_OP3;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_BC : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_RAM;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_CB : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOV_DP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP3;
              src_sel2 <= #1 `LP805X_AS2_OP2;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_DPTR;
            end
          `LP805X_MOVC_DP :begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DP;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOVC_PC : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_PCL;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_ADD;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOVX_PA : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MOVX_AP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_MUL : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_MUL;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_OV;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ORL_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_OR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ORL_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_OR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_ORL_AD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_OR;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ORL_CD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_OP3;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_OR;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ORL_B : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_OR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_ORL_NB : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_RL;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_POP : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_PUSH : begin
              ram_wr_sel <= #1 `LP805X_RWS_SP;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_RET : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_RETI : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_RL : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_RL;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_RLC : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_RLC;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_RR : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_RR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_RRC : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_RRC;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_SETB_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_CY;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_SETB_B : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_SJMP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_PC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_SUBB_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_SUBB_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_OP2;
              alu_op <= #1 `LP805X_ALU_SUB;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_AC;
              cy_sel <= #1 `LP805X_CY_PSW;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_SWAP : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_ACC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_RLC;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC2;
            end
          `LP805X_XCH_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XCH;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_1;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC2;
            end
          `LP805X_XRL_D : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XOR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_XRL_C : begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_OP2;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XOR;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_ACC1;
            end
          `LP805X_XRL_AD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_RAM;
              src_sel2 <= #1 `LP805X_AS2_ACC;
              alu_op <= #1 `LP805X_ALU_XOR;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          `LP805X_XRL_CD : begin
              ram_wr_sel <= #1 `LP805X_RWS_D;
              src_sel1 <= #1 `LP805X_AS1_OP3;
              src_sel2 <= #1 `LP805X_AS2_RAM;
              alu_op <= #1 `LP805X_ALU_XOR;
              wr <= #1 1'b1;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
            end
          default: begin
              ram_wr_sel <= #1 `LP805X_RWS_DC;
              src_sel1 <= #1 `LP805X_AS1_DC;
              src_sel2 <= #1 `LP805X_AS2_DC;
              alu_op <= #1 `LP805X_ALU_NOP;
              wr <= #1 1'b0;
              psw_set <= #1 `LP805X_PS_NOT;
              cy_sel <= #1 `LP805X_CY_0;
              src_sel3 <= #1 `LP805X_AS3_DC;
              wr_sfr <= #1 `LP805X_WRS_N;
           end
        endcase
      end
      endcase
  end
end


//
// remember current instruction
always @(posedge clk or posedge rst)
  if (rst) op <= #1 2'b00;
  else if (state==2'b00 & !wait_data) op <= #1 op_in;

//
// in case of instructions that needs more than one clock set state
always @(posedge clk or posedge rst)
begin
  if (rst)
    state <= #1 2'b01;
  else if  (!mem_wait & !wait_data) begin
    case (state) /* previous parallell_mask */
      2'b10: state <= #1 2'b01;
      2'b11: state <= #1 2'b10;
      2'b00:
          casex (op_in) /* previous full_mask parallel_mask */
            `LP805X_ACALL   : state <= #1 2'b10;
            `LP805X_AJMP    : state <= #1 2'b10;
            `LP805X_CJNE_R  : state <= #1 2'b10;
            `LP805X_CJNE_I  : state <= #1 2'b10;
            `LP805X_CJNE_D  : state <= #1 2'b10;
            `LP805X_CJNE_C  : state <= #1 2'b10;
            `LP805X_LJMP    : state <= #1 2'b10;
            `LP805X_DJNZ_R  : state <= #1 2'b10;
            `LP805X_DJNZ_D  : state <= #1 2'b10;
            `LP805X_LCALL   : state <= #1 2'b10;
            `LP805X_MOVC_DP : state <= #1 2'b10;
            `LP805X_MOVC_PC : state <= #1 2'b10;
            `LP805X_MOVX_IA : state <= #1 2'b10;
            `LP805X_MOVX_AI : state <= #1 2'b01;
            `LP805X_MOVX_PA : state <= #1 2'b10;
            `LP805X_MOVX_AP : state <= #1 2'b01;
            `LP805X_RET     : state <= #1 2'b11;
            `LP805X_RETI    : state <= #1 2'b11;
            `LP805X_SJMP    : state <= #1 2'b10;
            `LP805X_JB      : state <= #1 2'b10;
            `LP805X_JBC     : state <= #1 2'b10;
            `LP805X_JC      : state <= #1 2'b10;
            `LP805X_JMP_D   : state <= #1 2'b10;
            `LP805X_JNC     : state <= #1 2'b10;
            `LP805X_JNB     : state <= #1 2'b10;
            `LP805X_JNZ     : state <= #1 2'b10;
            `LP805X_JZ      : state <= #1 2'b10;
            `LP805X_DIV     : state <= #1 2'b11;
            `LP805X_MUL     : state <= #1 2'b11;
				`LP805X_MOV_CD  : state <= #1 2'b01;
				`LP805X_MOV_DA  : state <= #1 2'b01;
				`LP805X_MOV_DD  : state <= #1 2'b01;
//            default         : state <= #1 2'b00;
          endcase
      default: state <= #1 2'b00;
    endcase
  end
end

//reg [2:0] mem_act;

//
//in case of writing to external ram
//always @(posedge clk or posedge rst)
//begin
//  if (rst) begin
//    mem_act <= #1 `LP805X_MAS_NO;
//  end else if (!rd) begin
//    mem_act <= #1 `LP805X_MAS_NO;
//  end else
//    casex (op_cur) /* previous parallell_mask */
//      `LP805X_MOVX_AI : mem_act <= #1 `LP805X_MAS_RI_W;
//      `LP805X_MOVX_AP : mem_act <= #1 `LP805X_MAS_DPTR_W;
//      `LP805X_MOVX_IA : mem_act <= #1 `LP805X_MAS_RI_R;
//      `LP805X_MOVX_PA : mem_act <= #1 `LP805X_MAS_DPTR_R;
//      `LP805X_MOVC_DP : mem_act <= #1 `LP805X_MAS_CODE;
//      `LP805X_MOVC_PC : mem_act <= #1 `LP805X_MAS_CODE;
//      default : mem_act <= #1 `LP805X_MAS_NO;
//    endcase
//end

//assign mem_act = !rd								 ? `LP805X_MAS_NO   :
//					  op_cur[7:1] == 7'b1111001 ? `LP805X_MAS_RI_W : 
//					  op_cur[7:1] == 7'b1110001 ? `LP805X_MAS_RI_R : 
//						`LP805X_MAS_NO;

reg [2:0] mem_act;

always @(*)
begin
	 if ( !rd)
		mem_act = `LP805X_MAS_NO;
	 else 
	 begin
		 casex (op_cur) /* previous parallell_mask */
			`LP805X_MOVX_AI : mem_act = `LP805X_MAS_RI_W;
			`LP805X_MOVX_AP : mem_act = `LP805X_MAS_DPTR_W;
			`LP805X_MOVX_IA : mem_act = `LP805X_MAS_RI_R;
			`LP805X_MOVX_PA : mem_act = `LP805X_MAS_DPTR_R;
			`LP805X_MOVC_DP : mem_act = `LP805X_MAS_CODE;
			`LP805X_MOVC_PC : mem_act = `LP805X_MAS_CODE;
			default : mem_act = `LP805X_MAS_NO;
		 endcase
	 end
end

always @(posedge clk or posedge rst)
begin
  if (rst) begin
    ram_rd_sel_r <= #1 3'h0;
  end else begin
    ram_rd_sel_r <= #1 ram_rd_sel;
  end
end



`ifdef LP805X_SIMULATION
// synthesis translate_off
always @(op_cur)
  if (op_cur===8'hxx) begin
    $display("time %t => invalid instruction (LP805X_decoder)", $time);
#22
    $finish;
  end
// synthesis translate_on
`endif




endmodule


