`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:35:30 10/01/2012 
// Design Name: 
// Module Name:    bufgmux_test 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module bufgmux_test(
    input clk1,
    input clk2,
	 input rst,
    output clko,
    input sel,
	 output reg lg
    );
	 
	BUFGMUX #(
      .CLK_SEL_TYPE("SYNC")  // Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   BUFGMUX_p1 (
      .O(clko),   // 1-bit output: Clock buffer output
      .I0(clk1), // 1-bit input: Clock buffer input (S=0)
      .I1(clk2), // 1-bit input: Clock buffer input (S=1)
      .S(sel)    // 1-bit input: Clock buffer select
   );
	
	always @(posedge clko)
	if ( rst)
		lg <= #1 0;
	else
		lg <= #1 sel;


endmodule
