`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/02 17:00:56
// Design Name: 
// Module Name: Multiplier
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

module multiplier(
    input clk,
    input rst,
    input start,
    input signed_mode,
    input [31:0] a,
    input [31:0] b,
    output [63:0] result,
    output busy,
    output done
);
    wire signed [63:0] signed_a = {{32{a[31]}}, a}; //先扩成64位，避免乘法表达式只保留32位结果
    wire signed [63:0] signed_b = {{32{b[31]}}, b};
    wire signed [63:0] signed_result = signed_a * signed_b;
    wire [63:0] unsigned_result = {32'h0, a} * {32'h0, b};

    assign result = signed_mode ? signed_result : unsigned_result; //前仿真一次得到结果，不额外占用时钟周期
    assign busy = 1'b0; //平台逐周期比对PC，因此前仿真模型不暂停PC
    assign done = start; //start有效时结果同时有效，CPU在当前上升沿写入HI和LO
endmodule
