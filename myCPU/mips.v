`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,rst,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire memwriteM,
	output wire[31:0] aluoutM,mem_write_dataM,
	input wire[31:0] readdataM, 
	output wire [3:0] mem_wenM,
	//for debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
    );

	//连接controller �??? datapath
	wire [5:0] opD,opE,opM,functD;
	wire [1:0] regdstE;
	wire alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM,regwriteW;
	wire [4:0] alucontrolE;
	wire flushD,flushE,flushM,equalD;
	wire hilo_writeE; //hilo寄存器写信号
	wire is_invalidM; //保留指令
	wire [5:0] ext_int;//硬件中断�?
	assign ext_int = 6'b000000;
	wire cp0_writeM; //cp0寄存器写信号
	
//----------------------------------------------for debug begin----------------------------------------------------	
    wire [31:0] pcW;
    wire [31:0] instrE,instrM,instrW;
    flopr #(32) rinstrE(clk,rst,instrD,instrE);
    flopr #(32) rinstrM(clk,rst,instrE,instrM);
    flopr #(32) rinstrW(clk,rst,instrM,instrW);
    
    flopr #(32) rpcW(clk,rst,pcM,pcW);
    assign debug_wb_pc          = pcW;
    assign debug_wb_rf_wen      = {4{regwriteW}};
    assign debug_wb_rf_wnum     = writeregW;
    assign debug_wb_rf_wdata    = resultW;
//----------------------------------------------for debug end----------------------------------------------------

//----------------------------------------controler 模块begin------------------------------------------
	//decode stage
	wire memtoregD,memwriteD,alusrcD,regwriteD;
	wire[1:0] regdstD;
	wire[4:0] alucontrolD;
	wire hilo_writeD;//由maindec译码得来
	wire is_invalidD,is_invalidE; //maindec译码得来，无效指令标�?
	wire jbralD,jrD,cp0_writeD;

	//execute stage
	wire memwriteE;
	wire jbralE,cp0_writeE;

	maindec md(
		opD,
		functD,
		rsD,
		rtD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		hilo_writeD,
		jbralD,
		jrD,
		cp0_writeD,
		is_invalidD
		);
	aludec ad(functD,opD,rtD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(32) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilo_writeD,jbralD,cp0_writeD,is_invalidD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_writeE,jbralE,cp0_writeE,is_invalidE}
		);
	floprc #(8) regM(
		clk,rst,flushM,
		{memtoregE,memwriteE,regwriteE,cp0_writeE,is_invalidE},
		{memtoregM,memwriteM,regwriteM,cp0_writeM,is_invalidM}
		);
	flopr #(8) regW(
		clk,rst,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
//----------------------------------------controler 模块end------------------------------------------

//----------------------------------------datapath 模块begin------------------------------------------
	//fetch stage
	wire stallF;
	wire is_AdEL_pcF;
	wire is_in_delayslotF; //当前指令是否在延迟槽
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD,pcnextjrD,pcnextF;
	//decode stage
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rtD,rdD,saD;
	wire stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire is_AdEL_pcD,is_syscallD,is_breakD,is_eretD; //例外标记
	wire is_in_delayslotD; 
	wire [31:0] pcD;
	wire [4:0] cp0_waddrD; //cp0写地�?，指令MTC0
	wire [4:0] cp0_raddrD; //cp0读地�?，指令MFC0

	//execute stage
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srca3E,  srcbE,srcb2E,srcb3E,srcb4E;
	wire [31:0] aluoutE;
	wire [63:0] read_hiloE,write_hiloE;//HILO读写数据
	wire hilo_write2E; //考虑了除法后的hilo寄存器写信号
	wire div_readyE; //除法运算是否完成
	wire div_stallE; //除法导致的流水线暂停控制
	wire stallE; //Ex阶段暂停控制信号
	wire is_AdEL_pcE,is_syscallE,is_breakE,is_eretE,is_overflowE; //例外标记
	wire is_in_delayslotE;
	wire [31:0] pcE;
	wire [4:0] cp0_waddrE;
	wire [4:0] cp0_raddrE;
	wire [31:0] cp0_rdataE;

	//mem stage
	wire [4:0] writeregM;
	wire [31:0] final_read_dataM,writedataM;
	wire is_AdEL_pcM,is_syscallM,is_breakM,is_eretM,is_AdEL_dataM,is_AdESM,is_overflowM; //例外标记
	wire is_in_delayslotM;
	wire [31:0] pcM;
	wire [4:0] cp0_waddrM;
	wire [4:0] cp0_raddrM;
	wire is_exceptM;
	wire [31:0] except_typeM;
	wire [31:0] except_pcM;
	wire [31:0] cp0_statusM,cp0_causeM,cp0_epcM;

	//writeback stage
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;

	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		jrD,
		forwardaD,forwardbD,
		stallD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		div_stallE,
		forwardaE,forwardbE,
		flushD,
		flushE,
		flushM,
		stallE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		is_exceptM,
		//write back stage
		writeregW,
		regwriteW
		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcjumpmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD,pcnextFD);
	mux2 #(32) pc_jr_mux(pcnextFD,srca2D,jrD,pcnextjrD);
	mux2 #(32) pc_except_mux(pcnextjrD,except_pcM,is_exceptM,pcnextF); //处理异常添加

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextF,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);

	assign is_AdEL_pcF = ~(pcF[1:0] == 2'b00);
	assign is_in_delayslotF = jumpD | branchD | jbralD | jrD;

	//decode stage
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) r3D(clk,rst,~stallD,flushD,is_AdEL_pcF,is_AdEL_pcD);
	flopenrc #(1) r4D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
	flopenrc #(32) r5D(clk,rst,~stallD,flushD,pcF,pcD);

	signext se(instrD[15:0],opD[3:2],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];

	assign is_breakD = (opD == 6'b000000) & (functD == `BREAK);
	assign is_syscallD = (opD == 6'b000000) & (functD == `SYSCALL);
	assign is_eretD = (instrD == 32'b01000010000000000000000000011000);
	assign cp0_waddrD = rdD;
	assign cp0_raddrD = rdD;

	//execute stage
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5) r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(6) r8E(clk,rst,~stallE,flushE,opD,opE);
	flopenrc #(4) r9E(clk,rst,~stallE,flushE,
		{is_AdEL_pcD,is_syscallD,is_breakD,is_eretD},
		{is_AdEL_pcE,is_syscallE,is_breakE,is_eretE});
	flopenrc #(1) r10E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);
	flopenrc #(32) r11E(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(5) r12E(clk,rst,~stallE,flushE,cp0_waddrD,cp0_waddrE);
	flopenrc #(5) r13E(clk,rst,~stallE,flushE,cp0_raddrD,cp0_raddrE);
	
	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	//跳转链接类指�?,复用ALU,ALU源操作数选择为pcE�?8
	mux2 #(32) alusrcamux(srca2E,pcE,jbralE,srca3E);
	mux2 #(32) alusrcbmux(srcb3E,32'h00000008,jbralE,srcb4E);
	//CP0写后读数据前�?
	mux2 #(32) forwardcp0mux(cp0_rdataE,aluoutM,(cp0_raddrE == cp0_waddrM),cp0_rdata2E); 

	alu alu(clk,rst,srca3E,srcb4E,alucontrolE,saE,read_hiloE,cp0_rdata2E,
			write_hiloE,aluoutE,div_readyE,div_stallE,is_overflowE);
	assign hilo_write2E = (alucontrolE == `DIV_CONTROL) ? (div_readyE & hilo_writeE) : (hilo_writeE); 
	hilo_reg hilo_reg(clk,rst,(hilo_write2E & ~is_exceptM),write_hiloE,read_hiloE);
	mux3 #(5) wrmux(rtE,rdE,5'd31,regdstE,writeregE);

	//mem stage
	floprc #(32) r1M(clk,rst,flushM,srcb2E,writedataM);
	floprc #(32) r2M(clk,rst,flushM,aluoutE,aluoutM);
	floprc #(5) r3M(clk,rst,flushM,writeregE,writeregM);
	floprc #(6) r4M(clk,rst,flushM,opE,opM);
	floprc #(5) r5M(clk,rst,flushM,
		{is_AdEL_pcE,is_syscallE,is_breakE,is_eretE,is_overflowE},
		{is_AdEL_pcM,is_syscallM,is_breakM,is_eretM,is_overflowM});
	floprc #(1) r6M(clk,rst,flushM,is_in_delayslotE,is_in_delayslotM);
	floprc #(32) r7M(clk,rst,flushM,pcE,pcM);
	floprc #(5) r8M(clk,rst,flushM,cp0_waddrE,cp0_waddrM);
	floprc #(5) r9M(clk,rst,flushM,cp0_raddrE,cp0_raddrM);
	
	mem_ctrl mem_ctrl(opM,aluoutM,readdataM,final_read_dataM,writedataM,mem_write_dataM,mem_wenM,is_AdEL_dataM,is_AdESM);
	exceptdec exceptdec(
		//input
		.clk(clk),              
		.rst(rst),              
		.ext_int(ext_int),   
		.cp0_status(cp0_statusM),  
		.cp0_cause(cp0_causeM),  
		.cp0_epc(cp0_epcM),    
		.is_syscallM(is_syscallM),      
		.is_breakM(is_breakM),        
		.is_eretM(is_eretM),         
		.is_AdEL_pcM(is_AdEL_pcM),      
		.is_AdEL_dataM(is_AdEL_dataM),    
		.is_AdESM(is_AdESM),         
		.is_overflowM(is_overflowM),     
		.is_invalidM(is_invalidM),   
		//output   
		.is_except(is_exceptM),       
		.except_type(except_typeM),
		.except_pc(except_pcM)   
	);
	assign bad_addrM = is_AdEL_pcM ? pcM : aluoutM;
	cp0_reg cp0_reg(
		//input
		.clk(clk),                          
		.rst(rst),
		.we_i(cp0_writeM),    
		.waddr_i(cp0_waddrM),
		.raddr_i(cp0_raddrM),
		.data_i(aluoutM),
		.int_i(ext_int),
		.excepttype_i(except_typeM),
		.current_inst_addr_i(pcM),
		.is_in_delayslot_i(is_in_delayslotM),
		.bad_addr_i(bad_addrM),
		//output
		.data_o(cp0_rdataE),
		// .count_o(),
		// .compare_o(),
		.status_o(cp0_statusM), //用于判断中断
		.cause_o(cp0_causeM), //用于判断中断
		.epc_o(cp0_epcM)  //用于ERET
		// .config_o(),
		// .prid_o(),
		// .badvaddr(),
		// .timer_int_o()
	);

	//writeback stage
	flopr #(32) r1W(clk,rst,aluoutM,aluoutW);
	flopr #(32) r2W(clk,rst,final_read_dataM,readdataW);
	flopr #(5) r3W(clk,rst,writeregM,writeregW);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
//----------------------------------------datapath 模块end------------------------------------------

	
endmodule
