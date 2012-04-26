// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"

module lp805x_tbpll();

parameter FREQ0  = 50000; // frequency in kHz
parameter DELAY0 = 500000/FREQ0;
/*
	reg	  areset;
	reg	  inclk0;
	reg	  pfdena;
	reg	  pllena;
	wire	  c0;
	wire	  c1;
	wire	  c2;
	wire	  locked;

lp805x_pll dut
	(
		.areset( areset),
		.inclk0( inclk0),
		.pfdena( pdfena),
		.pllena( pllena),
		.c0( c0),
		.c1( c1),
		.c2( c2),
		.locked( locked)
	);
	
	initial
	begin
		inclk0 = 0;
		areset = 1;
		pfdena = 1;
		pllena = 1;
		
		#20
		areset = 0;
		

	end
	*/
	
	reg  inclk0;
	reg areset;
	reg [15:0] addr;
	wire [31:0] data;
	reg [1:0] select;
	wire clk;
	wire locked;
	
	pll_dummy dut(areset,inclk0,clk,addr,data,select,locked);
	
	initial
	begin
	areset=1;
	inclk0=0;
	addr = 0;
	select = 1;
	
	#5
	areset=0;
	#300
	addr = 1;
	select = 2;
	
	#300
	addr = 2;
	select = 3;
	end
	
	always #DELAY0 inclk0 = ~inclk0;

endmodule
