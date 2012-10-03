//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:38:42 07/22/2012 
// Design Name: 
// Module Name:    lp805x_wtd 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: Watchdog
//
//////////////////////////////////////////////////////////////////////////////////
// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"

`define LP805X_SFR_WDTCON 8'ha7
`define LP805X_SFR_WDTRST 8'ha6
`define LP805X_SFR_WDTREG 8'ha5

module lp805x_wdt( rsti, 
						 clk,
						 wr_addr, rd_addr,
						 data_in, data_out, 
						 wr, rd, 
						 bit_in, bit_out,
						 wr_bit, rd_bit,
						 
						 rst //[SPECIAL FEATURE]
						); //reset control

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

parameter LP805X_RST_WDTCON = 8'b0;
//parameter LP805X_RST_WDTRST = 8'b0; virtual
parameter LP805X_WDTPres_LEN = 3;
parameter LP805X_WDTimer_LEN = 14;
parameter LP805X_WDTPres_DPH = 7;

input 			rsti, clk;
input [7:0] 	wr_addr, rd_addr;
input [7:0]		data_in;
input				bit_in;
input 			wr,rd;
input				wr_bit,rd_bit;

/*		internal SFR register		*/

reg [7:0] wdt_control = LP805X_RST_WDTCON;
//reg [7:0] wdt_reset; virtual

/*		internal SFR register		*/

/*		internal SFR control		*/

output tri [7:0] data_out;
output tri bit_out;

/*		internal SFR control		*/


/*		internal WDTimer		*/

reg [LP805X_WDTPres_DPH-1:0] wdtpres;
reg [LP805X_WDTimer_LEN-1:0] wdtimer;


reg [LP805X_WDTPres_DPH-1:0] wdtpres_src;
reg wdt_ovf = 0;

/*		internal WDTimer		*/


// [SPECIAL FEATURE] = reset control!
output wire rst;


wire [LP805X_WDTPres_LEN-1:0] wdtps;
wire widle,swrst,wdtov,wdten;

	assign
		wdtps = wdt_control[7:5],
		widle = wdt_control[4],
		swrst = wdt_control[2],
		wdtov = wdt_control[1],
		wdten = wdt_control[0];

wire por;
/* power on reset, or normal reset..?? */
assign por = rsti;// | ~wdt_ovf & ~swrst;

//
//case writing to clk select register
always @(posedge clk)
begin
	if ( por) begin
		wdt_control <= #1 LP805X_RST_WDTCON;
	 //wtd_reset <= #1 LP805X_RST_WDTRST; virtual
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_WDTCON)) begin
		wdt_control <= #1 {data_in[7:4],wdt_control[3:2],data_in[1],wdt_control[0]};
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_WDTRST)) begin

/* simplified wdt control, no explicit state machine, check later if needed */
		if ( ~wdten & (data_in==8'h1e))
			wdt_control[0] <= #1 1'b1;
		else if ( wdten & (data_in==8'he1))
			wdt_control[0] <= #1 1'b0;
		else if ( ~swrst & (data_in==8'h5a))
			wdt_control[2] <= #1 1'b1;
		else if ( swrst & (data_in==8'ha5))
			wdt_control[2] <= #1 1'b0;
		else /* wrong action, faulty sw? */
			wdt_control[2:1] <= #1 2'b11;
	end else begin
		wdt_control[1] <= wdt_ovf;
	end
end

wire wdt_rst;
reg wdt_event,wdt_r;
assign wdt_rst = wdtov | swrst;

always @(posedge clk)
begin
  if ( rsti) begin
    wdt_event <= #1 1'b0;
    wdt_r <= #1 1'b0;
  end else if ( ~wdt_rst) begin
    wdt_event <= #1 1'b0;
    wdt_r <= #1 1'b1;
  end else if ( wdt_rst & wdt_r) begin
    wdt_event <= #1 1'b1;
    wdt_r <= #1 1'b0;
  end else begin
    wdt_event <= #1 1'b0;
  end
end

// generate a wide system reset!
// wdt_control register can be checked for the reset reason!
	assign rst = rsti | wdt_event;

always @(*)
begin
	case ( wdtps)
	3'b000: wdtpres_src = 7'b1111111;
	3'b001: wdtpres_src = { wdtpres[0], 6'b111111 };
	3'b010: wdtpres_src = { wdtpres[1:0], 5'b11111 };
	3'b011: wdtpres_src = { wdtpres[2:0], 4'b1111 };
	3'b100: wdtpres_src = { wdtpres[3:0], 3'b111 };
	3'b101: wdtpres_src = { wdtpres[4:0], 2'b11 };
	3'b110: wdtpres_src = { wdtpres[5:0], 1'b1 };
	3'b111: wdtpres_src = wdtpres[6:0];
	endcase
end


reg [6:0] dummy; // decoy to control prescale adder outputs
always @(posedge clk)
begin
	if ( rst) begin
		wdt_ovf <= #1 1'b0;
		wdtimer <= #1 0;
		wdtpres <= #1 0;
		dummy <= #1 0;
	end else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_WDTREG)) begin
		wdtimer <= #1 data_in; /* decide this inclusion with xpand */
	end else if ( wdten) begin
		case ( wdtps)
			3'b000: { wdt_ovf, wdtimer, dummy[6:0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
			
			3'b001: { wdt_ovf, wdtimer, wdtpres[0], dummy[5:0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
			
			3'b010: { wdt_ovf, wdtimer, wdtpres[1:0], dummy[4:0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
			
			3'b011: { wdt_ovf, wdtimer, wdtpres[2:0], dummy[3:0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
			
			3'b100: { wdt_ovf, wdtimer, wdtpres[3:0], dummy[2:0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
			
			3'b101: { wdt_ovf, wdtimer, wdtpres[4:0], dummy[1:0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
			
			3'b110: { wdt_ovf, wdtimer, wdtpres[5:0], dummy[0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
			
			3'b111: { wdt_ovf, wdtimer, wdtpres[6:0] }
			<= #1 { 1'b0, wdtimer, wdtpres_src } + 1'b1;
	
			default: 
				begin
					wdt_ovf <= 1'b0;
					wdtimer <= #1 wdtimer;
					wdtpres <= #1 wdtpres;
					dummy <= #1 dummy;
				end
		endcase
	end
end


reg output_data;
reg [7:0] data_read;
//
// case of reading byte from port
always @(posedge clk or posedge rst)
begin
  if (rst) begin
    {output_data,data_read} <= #1 {1'b0,8'h0};
	end
  else
	if ( rd)
    case (rd_addr)
      `LP805X_SFR_WDTCON: 		{output_data,data_read} <= #1 {1'b1,wdt_control};
      default:             {output_data,data_read} <= #1 {1'b0,8'h0};
    endcase
end

assign data_out = output_data ? data_read : 8'hzz;

assign bit_out = 1'bz; //no bit addr

endmodule
