`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/30 21:37:12
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

module PC(
    input clk,
    input rst,
    input [31:0] pc_next,
    output reg [31:0] pc
);
    initial pc = 32'h0040_0000; //MIPS测试程序规定从0x00400000开始取指

    always @(negedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0040_0000;
        else
            pc <= pc_next; //下降沿更新PC，与上升沿写寄存器错开，避免同一时刻的竞争
    end
endmodule
