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

							`ifdef LP805X_MULTIFREQ
							rst_p1, clk_p1o,
							`endif
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

`ifdef LP805X_MULTIFREQ
output wire clk_p1o;
output wire rst_p1;
`endif

reg do_switch;

//
//case writing to clk select register
always @(posedge clk or posedge rst)
begin
  if (rst) begin
    clock_select <= #1 `LP805X_RST_CLKSR;
	 do_switch <= #1 1'b0;
  end
//
// write to clksr (byte addressable)
  else if (wr & ~wr_bit & (wr_addr==`LP805X_SFR_CLKSR)) begin
    clock_select <= #1 data_in;
	 do_switch <= #1 ~do_switch;
  end
end

tri bit_out;
assign bit_out = 1'bz;


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
	//if ( rd)
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
	`endif //PLL

assign
		rst = rsti;

parameter PRESCALE_LEN = 3;
		
	lp805x_clkdiv #(.PRESCALE_LEN(PRESCALE_LEN))
	clkdiv_1( .rst(rsti), .clki(clki), 
	._pres_factor(clock_select[PRESCALE_LEN-1:0]), .clk_div(clk_));
	
	
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

	parameter PRESCALE_LEN = 3;

	assign
		rst = rsti;
		
	`ifdef LP805X_MULTIFREQ
	assign
		rst_p1 = rsti;
	`endif

	wire clk_;
	wire last_clk;
	
	wire clk_0,clk_1;
	reg do_s_1;
	
	always @(posedge clk)
		do_s_1 <= #1 do_switch;
	
	assign clk_0 = do_s_1 ? clk_ : last_clk; 
	assign clk_1 = do_s_1 ? last_clk : clk_; 
	
	`ifdef LP805X_MULTIFREQ
	wire clk_p;
	wire last_clkp;
	wire clk_p0,clk_p1;
	reg do_s_p1;
	
	always @(posedge clk)
		do_s_p1 <= #1 do_switch;
	
	assign clk_p0 = do_s_p1 ? clk_p : last_clkp; 
	assign clk_p1 = do_s_p1 ? last_clkp : clk_p; 
	`endif
	
	lp805x_clkdiv #(.PRESCALE_LEN(PRESCALE_LEN))
	clkdiv_1
	( 
	.rst(rsti),
	.clki(clki),
	`ifdef LP805X_MULTIFREQ
	._pres_factor1(clock_select[(PRESCALE_LEN*2)-1:PRESCALE_LEN]),
	.clk_div1(clk_p),
	.clk_divl1(last_clkp),
	`endif
	._pres_factor(clock_select[PRESCALE_LEN-1:0]),
	.clk_div(clk_),
	.clk_divl(last_clk)
	);
	
	BUFGMUX #(
      .CLK_SEL_TYPE("SYNC")  // Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   BUFGMUX_cpu (
      .O(clk),   // 1-bit output: Clock buffer output
      .I0(clk_0), // 1-bit input: Clock buffer input (S=0)
      .I1(clk_1), // 1-bit input: Clock buffer input (S=1)
      .S(do_switch)    // 1-bit input: Clock buffer select
   );
	
	`ifdef LP805X_MULTIFREQ
	BUFGMUX #(
      .CLK_SEL_TYPE("SYNC")  // Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   BUFGMUX_p1 (
      .O(clk_p1o),   // 1-bit output: Clock buffer output
      .I0(clk_p0), // 1-bit input: Clock buffer input (S=0)
      .I1(clk_p1), // 1-bit input: Clock buffer input (S=1)
      .S(do_switch)    // 1-bit input: Clock buffer select
   );
	`endif
	
		`endif //PLL
	`endif // Xilinx
`endif // Altera
endmodule

module lp805x_clkdiv( 
	rst, clki, _pres_factor, 
	`ifdef LP805X_MULTIFREQ
	_pres_factor1, clk_div1, clk_divl1,
	`endif
	clk_div, clk_divl) ;
	 parameter PRESCALE_LEN = 3;
	 parameter COUNTER_LEN = 7;
	 
	 input rst;
    input clki;
	 input [PRESCALE_LEN-1:0] _pres_factor;
	 output clk_div,clk_divl;
	 reg [PRESCALE_LEN-1:0] clk_divl_i;
	 `ifdef LP805X_MULTIFREQ
	 input [PRESCALE_LEN-1:0] _pres_factor1;
	 output clk_div1, clk_divl1;
	 reg [PRESCALE_LEN-1:0] clk_divl_i1;
	 `endif
	 
	 reg [COUNTER_LEN-1:0] pres_counter;
	 
	 wire [COUNTER_LEN:0] clock_list = { pres_counter,  clki };
	 
		assign 
			clk_div = clock_list[ _pres_factor],
			clk_divl = clock_list[ clk_divl_i];
		
		`ifdef LP805X_MULTIFREQ
		assign
			clk_div1 = clock_list[ _pres_factor1],
			clk_divl1 = clock_list[ clk_divl_i1];
		`endif
			
	 always @(posedge clki)
	 begin
		if ( rst) begin
			clk_divl_i <= #1 0;
			`ifdef LP805X_MULTIFREQ
			clk_divl_i1 <= #1 0;
			`endif
		end
		else begin
			clk_divl_i <= _pres_factor;
			`ifdef LP805X_MULTIFREQ
			clk_divl_i1 <= _pres_factor1;
			`endif
		end
	 end
	 
	 always @(posedge clki)
	 begin
		if ( rst)
			pres_counter <= #1 0;
		else
			pres_counter <= #1 pres_counter + 1'b1;
	 end
	 
endmodule
