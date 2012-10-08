//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:24:12 10/07/2012 
// Design Name: 
// Module Name:    lp805x_gtb 
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

// synopsys translate_off
`include "oc8051_timescale.v"
// synopsys translate_on

`include "oc8051_defines.v"


//`define POST_ROUTE

module lp805x_gtb(
    );

//parameter FREQ  = 12000; // frequency in kHz
parameter FREQ  = 30000; // frequency in kHz
//parameter FREQ  = 3500; // frequency in kHz

parameter DELAY = 500000/FREQ;

reg rst,clk,int0,int1;
reg [7:0] p0_in;
wire [7:0] p0_out;

`ifdef LP805X_ROM_ONCHIP
wire ea_in=1;
`else
wire ea_in=0;
`endif

lp805x_top #(.PWMS_LEN(1)) lp805x_top_1(
		.wb_rst_i(~rst),
		.wb_clk_i(clk),
		.int0_i(int0), .int1_i(int1),

	`ifdef LP805X_PORTS
		`ifdef LP805X_PORT0
		 .p0_i(p0_in),
		 .p0_o(p0_out),
		`endif
	`endif
	
	 .ea_in( ea_in)
	 );
	 
initial
begin
  clk = 0;
  forever #DELAY clk <= ~clk;
end
	 
initial 
	begin
		rst= 1'b1;
		p0_in = 8'hA5;
		int0 = 1'b0;
		int1 = 1'b0;

	// wait for 2 cycles for reset to settle
		repeat(2)@(posedge clk);
		rst = 1'b0;

		$display("reset over!\n");
		if (ea_in)
			$display("Test running from internal rom!");
		else
			$display("Test running from external rom!");
	end
	
// ALLmost all insn test	
//always @(p0_out)
//begin
//	if ( p0_out == 8'd127)
//		begin
//			$display("Test ran successfully!");
//			$finish;
//		end
//	else if ( p0_out != 8'd255)
//		begin
//			$display("Test failed with exit code: ",p0_out);
//			$finish;
//		end
//end

// XRAM test	
always @(p0_out)
begin
	if ( p0_out == 8'd127)
		begin
			$display("Xram Test ran successfully!");
			$finish;
		end
	else if ( p0_out != 8'd255)
		begin
			$display("Xram Test failed with exit code: ",p0_out);
			$finish;
		end
end



endmodule
