`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:05:33 08/10/2012 
// Design Name: 
// Module Name:    lp805x_synctrl 
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
module lp805x_synctrl(
		clk,
		rst,
		read,
		sfr_prrdy,
		sfr_pget,
		sfr_pwrdy,
		sfr_pput,
		clk_cpu,
		sfr_get,
		sfr_out,
		sfr_rrdy,
		this
    );
	 
	input clk,rst;
	input read;
	input sfr_prrdy,sfr_pwrdy;
	output sfr_pget,sfr_pput;
		
	input clk_cpu;
	input sfr_get;
	output sfr_out;
	input sfr_rrdy;
	
	input this;
	
	reg sfr_preput;
	reg sfr_pget,sfr_pput;
	
	reg sfr_out;

	always @(posedge clk)
	if ( rst)
		sfr_pput <= #1 0;
	else
		sfr_pput <= #1 sfr_preput;
			
	always @(posedge clk)
	begin
		if ( rst)
		begin
			sfr_pget <= #1 0;
			sfr_preput <= #1 0;
		end
		else if ( sfr_prrdy)
		begin
			sfr_pget <= #1 1;
			sfr_preput <= #1 0;
		end
		else if ( sfr_pget & sfr_pwrdy & read & this)
		begin
			sfr_pget <= #1 0;
			sfr_preput <= #1 1;
		end
		else if ( sfr_preput)
		begin
			sfr_preput <= #1 0;
		end
	end
	
	reg this_sync;
	
	always @(posedge clk_cpu)
	if ( rst)
		this_sync <= #1 0;
	else if ( sfr_rrdy)
		this_sync <= #1 1;
	else
		this_sync <= #1 0;
	
	always @(posedge clk_cpu)
	if ( rst)
		sfr_out <= #1 1'b0;
	else
		sfr_out <= #1 sfr_get & this_sync;

endmodule
