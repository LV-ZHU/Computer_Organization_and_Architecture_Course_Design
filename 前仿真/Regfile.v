`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/30 21:36:13
// Design Name: 
// Module Name: 1
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

module regfile(
    input clk,
    input rst,
    input RegWrite,
    input [4:0] raddr1,
    input [4:0] raddr2,
    input [4:0] waddr,
    input [31:0] wdata,
    output [31:0] rdata1,
    output [31:0] rdata2
);
    reg [31:0] array_reg [0:31]; //32个通用寄存器，每个寄存器保存32位数据
    integer i;

    assign rdata1 = array_reg[raddr1]; //两个读端口为组合读，寄存器编号变化后数据立即变化
    assign rdata2 = array_reg[raddr2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                array_reg[i] <= 32'h0;
        end else begin
            array_reg[0] <= 32'h0; //MIPS规定0号寄存器恒为0
            if (RegWrite && waddr != 5'd0)
                array_reg[waddr] <= wdata; //上升沿到来时把Rd写进Rdc指定的寄存器
        end
    end
endmodule
