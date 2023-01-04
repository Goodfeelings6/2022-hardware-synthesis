`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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


module maindec(
	input wire[5:0] op,
	input wire[5:0] funct,
	input wire[4:0] rt,
	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire[1:0] regdst,
	output wire regwrite,
	output wire jump,
    );
	reg[7:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump} = controls;
	always @(*) begin
		case (op)
			`R_TYPE:
				case (funct)
					`ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU,
					`AND,`NOR,`OR,`XOR,
					`SLLV,`SLL,`SRAV,`SRA,`SRLV,`SRL
					`MFHI,`MFLO:						controls <= 8'b10100000;
					`DIV,`DIVU,`MULT,`MULTU,
					`MTHI,`MTLO:						controls <= 8'b00000000;
					`JR:								controls <= 8'b00000001;
					`JALR:								controls <= 8'b10100001;
					default:    controls <= 8'b00000000;
				endcase
			// I-type
			`ADDI,`ADDIU,`SLTI,`SLTIU,
			`ANDI,`LUI,`ORI,`XORI:		controls <= 8'b10010000;
			`BEQ,`BNE,`BGTZ,`BLEZ:		controls <= 8'b00001000;
			`REGIMM_INST:
				case (rt)
					`BGEZ,`BLTZ:		controls <= 8'b00001000;
					`BGEZAL,`BLTZAL:	controls <= 8'b11001000;
					default:    controls <= 8'b00000000;
				endcase
			`LB,`LBU,`LH,`LHU,`LW:		controls <= 8'b10010010;
			`SB,`SH,`SW:				controls <= 8'b00010100;
			// J-type
			`J:		controls <= 8'b00000001;
			`JAL:	controls <= 8'b11000001;
			default:	controls <= 8'b00000000;
		endcase
	end
endmodule