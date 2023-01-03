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
	input wire[31:0] a,b,  //操作数a,b
	input wire [4:0] alucontrolE,
	input wire [4:0] sa,
	output reg[31:0] result
	// output reg overflow,
	// output wire zero
    );
	reg carry; //溢出判断
	
	always @(*) begin
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
			`MULT_CONTROL  :  result = 0;
			`MULTU_CONTROL :  result = 0;
			`DIV_CONTROL   :  result = 0;
			`DIVU_CONTROL  :  result = 0; 
			default        :  result = `ZeroWord;
		endcase
    end
endmodule
