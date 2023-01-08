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
	output wire hilo_write,
	output wire is_invalid
    );
	reg[8:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,hilo_write} = controls;
	always @(*) begin
		is_invalid <= 1'b0;
		case (op)
			`R_TYPE:
				case (funct)
					`ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU,
					`AND,`NOR,`OR,`XOR,
					`SLLV,`SLL,`SRAV,`SRA,`SRLV,`SRL,
					`MFHI,`MFLO:						controls <= 9'b101000000;
					`DIV,`DIVU,`MULT,`MULTU,
					`MTHI,`MTLO:						controls <= 9'b000000001;
					`JR:								controls <= 9'b000000010;
					`JALR:								controls <= 9'b101000010;
					default:  begin
						controls <= 9'b000000000;
						is_invalid <= 1'b1;
					end
				endcase
			// I-type
			`ADDI,`ADDIU,`SLTI,`SLTIU,
			`ANDI,`LUI,`ORI,`XORI:		controls <= 9'b100100000;
			`BEQ,`BNE,`BGTZ,`BLEZ:		controls <= 9'b000010000;
			`REGIMM_INST:
				case (rt)
					`BGEZ,`BLTZ:		controls <= 9'b000010000;
					`BGEZAL,`BLTZAL:	controls <= 9'b110010000;
					default:  begin
						controls <= 9'b000000000;
						is_invalid <= 1'b1;
					end
				endcase
			`LB,`LBU,`LH,`LHU,`LW:		controls <= 9'b100100100;
			`SB,`SH,`SW:				controls <= 9'b000101000;
			// J-type
			`J:		controls <= 9'b000000010;
			`JAL:	controls <= 9'b110000010;
			default:  begin
					controls <= 9'b000000000;
					is_invalid <= 1'b1;
			end
		endcase
	end
endmodule