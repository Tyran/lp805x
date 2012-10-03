`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:26:02 10/01/2012 
// Design Name: 
// Module Name:    lp805x_asiclkSwitch 
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
module lp805x_asiclkSwitch(
   // Outputs
   clk_out,
   // Inputs
   clk_1, clk_2, select
   );

   input clk_1;
   input clk_2;
   input select;

   output wire clk_out;

	reg q1,q2,q3,q4;
	wire or1_1, or1_2,or2_1,or2_2;

always @ (posedge clk_1)
begin
    if (clk_1 == 1'b1)
    begin
       q1 <= q4;
       q3 <= or1_1;
    end
end

always @ (posedge clk_2)
begin
    if (clk_2 == 1'b1)
    begin
        q2 <= q3;
        q4 <= or2_1;
    end
end

assign
	or1_1	= (!q1) | (!select),
	or2_1	= (!q2) | (select),
	or1_2	= (q3)  | (clk_1),
	or2_2	= (q4)  | (clk_2);

assign clk_out  = or1_2 & or2_2;

endmodule      