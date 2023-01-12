`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
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


module hazard(
	//fetch stage
	output wire stallF,
	input wire i_stall,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	input wire jrD,
	output wire forwardaD,forwardbD,
	output wire stallD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	input wire div_stallE,
	output reg[1:0] forwardaE,forwardbE,
	output wire flushF,
	output wire flushD,
	output wire flushE,
	output wire flushM,
	output wire flushW,
	output wire stallE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	input wire is_exceptM,
	input wire d_stall,
	output wire stallM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	output wire stallW,

	output wire longest_stall
    );

	wire lwstallD,branchstallD;

	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding sources to E stage (ALU)

	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

	//stalls
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign branchstallD = (branchD | jrD) &
				(regwriteE & (writeregE == rsD | writeregE == rtD) |
				memtoregM & (writeregM == rsD | writeregM == rtD));

	assign longest_stall = i_stall | d_stall | div_stallE;

	//stalls state
	assign stallD = lwstallD | branchstallD | longest_stall;
	assign stallF = (~is_exceptM & stallD); //触发异常处理时，可能有后续指令(无效执行指令)会暂停流水线
											//这个暂停会导致pc取不到异常处理地址0xBFC00380。因为暂停时，pc保持不变，
											//然后下一周期不暂停了，但是0xBFC00380也流走了，所以这个异常就得不到处理，出错
											//因此，触发异常时，不能暂停取指阶段
	assign stallE = longest_stall; 
	assign stallM = longest_stall;
    assign stallW = longest_stall & ~is_exceptM;

	//flushs state
	assign flushF = is_exceptM;
	assign flushD = is_exceptM;
	assign flushE = (lwstallD & ~longest_stall) | (branchstallD & ~longest_stall) | is_exceptM; //stalling D flushes next stage
	assign flushM = is_exceptM;
	assign flushW = is_exceptM ;

endmodule
