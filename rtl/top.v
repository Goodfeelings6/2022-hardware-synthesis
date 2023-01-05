`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 13:50:53
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
	input wire clk,rst,
	output wire[31:0] writedata,dataadr,
	output wire memwrite
    );

	wire[31:0] pc,instr,readdata;
	wire[3:0] mem_wen;

	mips mips(clk,rst,pc,instr,memwrite,dataadr,writedata,readdata,mem_wen);
	inst_mem imem(~clk,pc[7:2],instr);
	data_mem dmem(~clk,mem_wen,dataadr,writedata,readdata);
endmodule
