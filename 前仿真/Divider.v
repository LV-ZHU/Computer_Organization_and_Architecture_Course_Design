`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/02 17:01:20
// Design Name: 
// Module Name: Divider
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

module divider(
    input clk,
    input rst,
    input start,
    input signed_mode,
    input [31:0] dividend,
    input [31:0] divisor,
    output [63:0] result,
    output busy,
    output done
);
    wire signed [31:0] signed_dividend = dividend;
    wire signed [31:0] signed_divisor = divisor;
    wire [31:0] signed_quotient = (divisor == 32'h0) ? 32'h0 : signed_dividend / signed_divisor; //除数为0时不计算除法，避免仿真器报错
    wire [31:0] signed_remainder = (divisor == 32'h0) ? 32'h0 : signed_dividend % signed_divisor;
    wire [31:0] unsigned_quotient = (divisor == 32'h0) ? 32'h0 : dividend / divisor;
    wire [31:0] unsigned_remainder = (divisor == 32'h0) ? 32'h0 : dividend % divisor;

    assign result = signed_mode ? {signed_remainder, signed_quotient}
                                : {unsigned_remainder, unsigned_quotient}; //高32位送HI保存余数，低32位送LO保存商
    assign busy = 1'b0; //前仿真按单周期给出结果，避免平台重复记录同一条乘除法指令
    assign done = start;
endmodule
