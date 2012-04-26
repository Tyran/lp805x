

module pll_dummy(areset,inclk0,clk,addr,data,select,locked);

	input	  areset;
	input	  inclk0;
	wire	  pllena=1'b1;
	wire 	  c0;
	wire	  c1;
	wire	  c2;
	output wire	  locked;

lp805x_pll clker
	(
		.areset( areset),
		.inclk0( inclk0),
		.pllena( pllena),
		.c0( c0),
		.c1( c1),
		.c2( c2),
		.locked( locked)
	);
	
	output wire clk;
	input wire [1:0] select;
	
lp805x_clkctrl clkctrl
	(
		.clkselect( select),
		.ena( locked),
		.inclk0x( inclk0),
		.inclk1x( inclk0),
		.inclk2x( c1),
		.inclk3x( c2),
		.outclk( clk)
	);		
		
	output wire [31:0] data;
	input wire [15:0] addr;
	wire nn;
	  oc8051_rom rom1
				(
				 .rst(areset),
             .clk(clkx),
				 .ea_int(nn),
		       .addr(addr),
		       .data_o(data)
		      );
				 
endmodule
