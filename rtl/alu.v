`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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
`include "defines2.vh"

module alu(
	input wire clk,rst,
	input wire[31:0] a,b,  //操作数a,b
	input wire [4:0] alucontrolE,
	input wire [4:0] sa,
	input wire [63:0] hilo_in, //读取的HI、LO寄存器的值
	output reg[63:0] hilo_out, //用于写入HI、LO寄存器
	output reg[31:0] result,
	output wire div_ready,  //除法是否完成
	output reg div_stall   //除法的流水线暂停控制
	// output reg overflow,
	// output wire zero
    );
	reg carry; //溢出判断

	//div
	reg div_start;
	reg div_signed;
	wire [63:0] div_result;
	
	always @(*) begin
		if(rst)
			div_stall = 1'b0;
		carry = 0;
        case(alucontrolE)
			//逻辑运算8条
			`AND_CONTROL   :  result = a & b;  //指令AND、ANDI
			`OR_CONTROL    :  result = a | b;  //指令OR、ORI
			`XOR_CONTROL   :  result = a ^ b;  //指令XOR
			`NOR_CONTROL   :  result = ~(a | b);  //指令NOR、XORI
			`LUI_CONTROL   :  result = {b[15:0],16'b0}; //指令LUI
			//移位指令6条
			`SLL_CONTROL   :  result = b << sa;  //指令SLL
			`SRL_CONTROL   :  result = b >> sa;  //指令SRL
			`SRA_CONTROL   :  result = $signed(b) >>> sa;  //指令SRL
			`SLLV_CONTROL  :  result = b << a[4:0];  //指令SLLV
			`SRLV_CONTROL  :  result = b >> a[4:0];  //指令SRLV
			`SRAV_CONTROL  :  result = $signed(b) >>> a[4:0]; //指令SRAV
			//算数运算指令14条
			`ADD_CONTROL   :  {carry,result} = {a[31],a} + {b[31],b}; //指令ADD、ADDI
			`ADDU_CONTROL  :  result = a + b; //指令ADDU、ADDIU
			`SUB_CONTROL   :  {carry,result} = {a[31],a} - {b[31],b}; //指令SUB
			`SUBU_CONTROL  :  result = a - b; //指令SUBU
			`SLT_CONTROL   :  result = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  //指令SLT、SLTI
			`SLTU_CONTROL  :  result = a < b ? 32'b1 : 32'b0; //指令SLTU、SLTIU
			`MULT_CONTROL  :  hilo_out = $signed(a) * $signed(b); //指令MULT 
			`MULTU_CONTROL :  hilo_out = {32'b0, a} * {32'b0, b}; //指令MULTU
			`DIV_CONTROL   :  begin //指令DIV, 除法器控制状态机逻辑
				if(~div_ready) begin
					div_start = 1'b1;
					div_signed = 1'b1;
					div_stall = 1'b1;
				end
				else if(div_ready) begin
					div_start = 1'b0;
					div_signed = 1'b1;
					div_stall = 1'b0;
					hilo_out = div_result;
				end
				else begin
					div_start = 1'b0;
					div_signed = 1'b0;
					div_stall = 1'b0;
				end
			end
			`DIVU_CONTROL  :  begin //指令DIVU, 除法器控制状态机逻辑
				if(~div_ready) begin
					div_start = 1'b1;
					div_signed = 1'b0;
					div_stall = 1'b1;
				end
				else if(div_ready) begin
					div_start = 1'b0;
					div_signed = 1'b0;
					div_stall = 1'b0;
					hilo_out = div_result;
				end
				else begin
					div_start = 1'b0;
					div_signed = 1'b0;
					div_stall = 1'b0;
				end
			end
			//数据移动指令4条
			`MFHI_CONTROL  :  result = hilo_in[63:32]; //指令MFHI
			`MFLO_CONTROL  :  result = hilo_in[31:0]; //指令MFLO
			`MTHI_CONTROL  :  hilo_out = {a,hilo_in[31:0]}; //指令MTHI
			`MTLO_CONTROL  :  hilo_out = {hilo_in[63:32],a}; //指令MTLO
			default        :  result = `ZeroWord;
		endcase
    end

	//接入除法器
	div div(clk,rst,div_signed,a,b,div_start,1'b0,div_result,div_ready);
endmodule