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
    initial pc = 32'h0040_0000;

    always @(negedge clk or posedge rst) begin
        if (rst) //复位至初值，对应板载N17
            pc <= 32'h0040_0000;
        else //时钟下降沿就更新PC，这样可以保证在时钟上升沿时PC已经是最新的值了
            pc <= pc_next;
    end
endmodule
