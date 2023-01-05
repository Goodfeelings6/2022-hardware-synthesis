`include "defines2.vh"

module mem_ctrl(
    input wire[5:0] op_code,  //指令op_code
    input wire[31:0] addr, //访存地址
    //Load
	input wire[31:0] mem_read_data,  //从数据存储器读出的字
    output reg[31:0] final_read_data, //回写regfile的数据
    //Store
    input wire[31:0] pre_write_data, //rt寄存器读出的值
	output reg[31:0] mem_write_data,  //要写入数据存储器的值
	output reg [3:0] mem_wen //字节写使能
    );
	
	always @(*) begin
        mem_wen = 4'b0000;
        case(op_code)
            //Load
            `LB  :  begin //有符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {{24{mem_read_data[7]}},  mem_read_data[7:0]};
                    2'b01 : final_read_data = {{24{mem_read_data[15]}}, mem_read_data[15:8]};
                    2'b10 : final_read_data = {{24{mem_read_data[23]}}, mem_read_data[23:16]};
                    2'b11 : final_read_data = {{24{mem_read_data[31]}}, mem_read_data[31:24]};
                endcase
            end
            `LBU :  begin //无符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {      24'b0    ,       mem_read_data[7:0]};
                    2'b01 : final_read_data = {      24'b0    ,       mem_read_data[15:8]};
                    2'b10 : final_read_data = {      24'b0    ,       mem_read_data[23:16]};
                    2'b11 : final_read_data = {      24'b0    ,       mem_read_data[31:24]};
                endcase
            end
            `LH  :  begin //有符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {{16{mem_read_data[15]}}, mem_read_data[15:0]};
                    2'b10 : final_read_data = {{16{mem_read_data[31]}}, mem_read_data[31:16]};
                endcase
            end
            `LHU :  begin //无符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {      16'b0    ,       mem_read_data[15:0]};
                    2'b10 : final_read_data = {      16'b0    ,       mem_read_data[31:16]};
                endcase
            end
            `LW  :  final_read_data = mem_read_data;
            //Store
            `SB  :  begin
                case(addr[1:0]) //控制信号-字节写使能
                    2'b00 : mem_wen = 4'b0001;
                    2'b01 : mem_wen = 4'b0010;
                    2'b10 : mem_wen = 4'b0100;
                    2'b11 : mem_wen = 4'b1000;
                endcase
                mem_write_data = {4{pre_write_data[7:0]}};
            end
            `SH  :  begin
                case(addr[1:0]) //控制信号-字节写使能
                    2'b00 : mem_wen = 4'b0011;
                    2'b10 : mem_wen = 4'b1100;
                endcase
                mem_write_data = {2{pre_write_data[15:0]}};
            end
            `SW  :  begin
                //控制信号-字节写使能
                mem_wen = 4'b1111;
                mem_write_data = pre_write_data;
            end  
		endcase
    end
endmodule