// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"


module lp805x_clker( rsti, clki,
							wr_addr, rd_addr,
							data_in, data_out, 
							wr, rd, 
							bit_in, bit_out,
							wr_bit, rd_bit,

							rst, clk //[SPECIAL FEATURE]
							); //clock selection

//
// clki         (in)  clock source
// clk          (out) running clock
// rsto         (in)  reset source
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

input 			rsti, clki;
input [7:0] 	wr_addr, rd_addr;
input [7:0]		data_in;
input				bit_in;
input 			wr,rd;
input				wr_bit,rd_bit;

output			bit_out;
output [7:0] 	data_out;

reg [7:0] clock_select; //SFR register

// [SPECIAL FEATURE] = clock control!
output wire clk;
output wire rst;


//
//case writing to clk select register
always @(posedge clk or posedge rst)
begin
  if (rst)
    clock_select <= #1 `LP805X_RST_CLKSR;
//
// write to clksr (byte addressable)
  else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_CLKSR))
    clock_select <= #1 data_in;
//
// write to clksr (bit addressable)
  else if (wr & wr_bit & (wr_addr[7:3]==`LP805X_SFR_CLKSR))
    clock_select[wr_addr[2:0]] <= #1 bit_in;
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
      `LP805X_SFR_B_CLKSR:    {bit_outc,bit_outd} <= #1 {1'b1,clock_select[rd_addr[2:0]]};
	default:		{bit_outc,bit_outd} <= #1 {1'b0,1'b0};
    endcase
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
      `LP805X_SFR_CLKSR: 		{output_data,data_read} <= #1 {1'b1,clock_select};
      default:             {output_data,data_read} <= #1 {1'b0,8'h0};
    endcase
end

assign data_out = output_data ? data_read : 8'hzz;


`ifdef LP805X_ALTERA

	wire	  pllena=1'b1; //for now
	wire 	  c0;
	wire	  c1;
	wire	  c2;
	wire	  locked;
	wire [7:0] select;

`ifdef LP805X_USEPLL
	
lp805x_pll clker
	(
		.areset( rsti),
		.inclk0( clki),
		.pllena( pllena),
		.c0( c0),
		.c1( c1),
		.c2( c2),
		.locked( locked)
	);
	
	//wait until sync! @[StartUp]
	assign
			rst = rsti | ~locked,
			select = clock_select[1:0] != 2'b00 ? clock_select[1:0] : 2'b01;

lp805x_clkctrl clkctrl
	(
		.clkselect( select),
		.ena( locked),
		//.inclk0x( clki),
		.inclk1x( clki),
		.inclk2x( c1),
		.inclk3x( c2),
		.outclk( clk)
	);
`endif

assign
		rst = rsti;

lp805x_clkdiv clkdiv_1( .rst(rsti), .clki(clki), ._pres_factor(clock_select), .clk_div(clk));	
	
	
`else 
	`ifdef LP805X_XILINX

		`ifdef LP805X_USELL
	wire 	  c0;
	wire	  c1;
	wire	  c2;
	wire	  locked;
	wire	[7:0]  select;
	
	
lp805x_xpllcg clker
	(// Clock in ports
		.CLK_IN1( clki),
		// Clock out ports
		.CLK_OUT1( c0),
		.CLK_OUT2( c1), 
		.CLK_OUT3( c2),
		// Status and control signals
		.RESET( rsti),
		.LOCKED( locked)
	);
	
	//wait until sync! @[StartUp]
	assign
			rst = rsti | ~locked,
			select = clock_select[0];
	
	BUFGMUX #(
      .CLK_SEL_TYPE("SYNC")  // Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
	clkctrl
	(
		.I0( c0),
		.I1( c2),
		.S( select),
		.O( clk)	
	);	
		`else

	assign
		rst = rsti;

	wire clk_;
		
	lp805x_clkdiv clkdiv_1( .rst(rsti), .clki(clki), ._pres_factor(clock_select), .clk_div(clk_));
		
	assign clk = clk_; //will xise be smart?
	/*
	BUFG
	clkctrl
	(
		.I( clk_),
		.O( clk)	
	);
	*/
	
		`endif //PLL
	`endif // Xilinx
`endif // Altera
endmodule

module lp805x_clkdiv( rst, clki, _pres_factor, clk_div) ;
    input rst;
    input clki;
	 input [PRESCALE_LEN-1:0] _pres_factor;
    output clk_div;
	 
	 parameter PRESCALE_LEN = 3;
	 parameter COUNTER_LEN = 8;
	 
	 reg [COUNTER_LEN-1:0] pres_counter;
	 
	 assign clk_div = pres_counter[ _pres_factor];
	 
	 always @(posedge clki or posedge rst)
	 begin
		if ( rst)
			pres_counter <= #1 0;
		else
			pres_counter <= #1 pres_counter + 1;
	 end
	 
endmodule
