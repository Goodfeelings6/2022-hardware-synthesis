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
	input wire [63:0] hilo_in, //读取的HI、LO寄存器的�?
	input wire [31:0] cp0_rdata, //读取的CP0寄存器的�?
	input wire is_except, //用于触发异常时控制除法相关刷�?
	output reg[63:0] hilo_out, //用于写入HI、LO寄存�?
	output reg[31:0] result,
	output wire div_ready,  //除法是否完成
	output reg div_stall,   //除法的流水线暂停控制
	output wire overflow     //溢出判断
	// output wire zero
    );

	reg double_sign; //凑运算结果的双符号位，处理整型溢�?
	assign overflow = (alucontrolE==`ADD_CONTROL || alucontrolE==`SUB_CONTROL) & (double_sign ^ result[31]); 

	//div
	reg div_start;
	reg div_signed;
	reg [31:0] a_save; //除法时保存两个操作数，防止因为M阶段的刷新，继�?�数据前推�?�择器信号改变，导致alu输入发生变化，使除法出错
	reg [31:0] b_save;
	wire [63:0] div_result;
	
	always @(*) begin
		double_sign = 0;
		hilo_out = 64'b0;
		if(rst | is_except) begin
			div_stall = 1'b0;
			div_start = 1'b0;
		end
		else begin
        	case(alucontrolE)
				//逻辑运算8�?
				`AND_CONTROL   :  result = a & b;  //指令AND、ANDI
				`OR_CONTROL    :  result = a | b;  //指令OR、ORI
				`XOR_CONTROL   :  result = a ^ b;  //指令XOR
				`NOR_CONTROL   :  result = ~(a | b);  //指令NOR、XORI
				`LUI_CONTROL   :  result = {b[15:0],16'b0}; //指令LUI
				//移位指令6�?
				`SLL_CONTROL   :  result = b << sa;  //指令SLL
				`SRL_CONTROL   :  result = b >> sa;  //指令SRL
				`SRA_CONTROL   :  result = $signed(b) >>> sa;  //指令SRL
				`SLLV_CONTROL  :  result = b << a[4:0];  //指令SLLV
				`SRLV_CONTROL  :  result = b >> a[4:0];  //指令SRLV
				`SRAV_CONTROL  :  result = $signed(b) >>> a[4:0]; //指令SRAV
				//算数运算指令14�?
				`ADD_CONTROL   :  {double_sign,result} = {a[31],a} + {b[31],b}; //指令ADD、ADDI
				`ADDU_CONTROL  :  result = a + b; //指令ADDU、ADDIU
				`SUB_CONTROL   :  {double_sign,result} = {a[31],a} - {b[31],b}; //指令SUB
				`SUBU_CONTROL  :  result = a - b; //指令SUBU
				`SLT_CONTROL   :  result = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  //指令SLT、SLTI
				`SLTU_CONTROL  :  result = a < b ? 32'b1 : 32'b0; //指令SLTU、SLTIU
				`MULT_CONTROL  :  hilo_out = $signed(a) * $signed(b); //指令MULT 
				`MULTU_CONTROL :  hilo_out = {32'b0, a} * {32'b0, b}; //指令MULTU
				`DIV_CONTROL   :  begin //指令DIV, 除法器控制状态机逻辑
					if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋�??
						//必须非阻塞赋值，否则时序不对
						div_start <= 1'b1;
						div_signed <= 1'b1;
						div_stall <= 1'b1;
						a_save <= a; //除法时保存两个操作数
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b1;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end
				`DIVU_CONTROL  :  begin //指令DIVU, 除法器控制状态机逻辑
					if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋�??
						//必须非阻塞赋值，否则时序不对
						div_start <= 1'b1;
						div_signed <= 1'b0;
						div_stall <= 1'b1;
						a_save <= a; ////除法时保存两个操作数
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b0;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end
				//数据移动指令4�?
				`MFHI_CONTROL  :  result = hilo_in[63:32]; //指令MFHI
				`MFLO_CONTROL  :  result = hilo_in[31:0]; //指令MFLO
				`MTHI_CONTROL  :  hilo_out = {a,hilo_in[31:0]}; //指令MTHI
				`MTLO_CONTROL  :  hilo_out = {hilo_in[63:32],a}; //指令MTLO
				//读写CP0
				`MFC0_CONTROL  :  result = cp0_rdata; //指令MFC0
				`MTC0_CONTROL  :  result = b;  //指令MTC0
				default        :  result = `ZeroWord;
			endcase
		end
    end
	wire annul; //终止除法信号
	assign annul = ((alucontrolE == `DIV_CONTROL)|(alucontrolE == `DIVU_CONTROL)) & is_except;
	//接入除法�?
	div div(clk,rst,div_signed,a_save,b_save,div_start,annul,div_result,div_ready);
endmodule