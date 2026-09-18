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
    output reg [63:0] result, //高32位为余数HI，低32位为商LO
    output reg busy,
    output reg done
);
    reg [5:0] count; //记录已经算出的商的位数
    reg quotient_negative; //最终的商是否为负数
    reg remainder_negative;//最终的余数是否为负数，符号和被除数符合应该相同
    reg [63:0] work;//前32位为余数，后32位逐渐形成商
    reg [31:0] divisor_work;//除数的绝对值,32轮运算期间保持不变

    wire [31:0] dividend_abs = signed_mode && dividend[31] //判断是否为有符号模式且被除数为负数
                               ? (~dividend + 32'd1) : dividend;//如果是，那么取被除数的绝对值（也即相反数），否则直接使用被除数
    wire [31:0] divisor_abs = signed_mode && divisor[31]
                              ? (~divisor + 32'd1) : divisor;//同理，当有符号且除数为负时取除数的绝对值，用来试减
    wire [31:0] quotient_value = quotient_negative //完成无符号运算后决定最终的商是否为负数，如果是，那么还原商的补码，否则直接使用商(work的低32位)
                                 ? (~work[31:0] + 32'd1) : work[31:0];
    wire [31:0] remainder_value = remainder_negative //同理，决定最终的余数是否为负数，如果是，那么还原余数的补码，否则直接使用余数(work的高32位)
                                  ? (~work[63:32] + 32'd1) : work[63:32];

    always @(posedge clk or posedge rst) begin
        if (rst) begin //复位时清空所有寄存器
            result <= 64'h0;
            busy <= 1'b0;
            done <= 1'b0;
            count <= 6'd0;
            quotient_negative <= 1'b0;
            remainder_negative <= 1'b0;
            work <= 64'h0;
            divisor_work <= 32'h0;
        end else if (done) begin //当除法运算完成后，清空busy和done信号
            done <= 1'b0;
            busy <= 1'b0;
        end else if (start && !busy) begin //开始且不忙时，初始化除法运算
            busy <= 1'b1; //记录忙，下一轮开始执行busy分支
            count <= 6'd0; //初始化计数器
            quotient_negative <= signed_mode && (dividend[31] ^ divisor[31]); //判断最终的商是否为负数，只有当有符号模式且被除数和除数符号不同才为负数
            remainder_negative <= signed_mode && dividend[31]; //判断最终的余数是否为负数，只有当有符号模式且被除数为负数才为负数（因为余数的符号和被除数相同）
            work <= {32'h0000_0000, dividend_abs}; //初始化work寄存器，前32位为余数，后32位为被除数的绝对值
            divisor_work <= divisor_abs; //锁存除数的绝对值，即使后续变化也不影响除数
        end else if (busy) begin //正式开始
            if (count < 6'd32) begin //每轮生成1位商，共执行32轮
                if (work[62:31] >= divisor_work) //work整体左移一位后的候选余数够减除数
                    work <= {work[62:31] - divisor_work, work[30:0], 1'b1}; //候选余数减去除数，同时商左移并补1
                else
                    work <= {work[62:0], 1'b0}; //候选余数不够减，不执行减法，同时商左移并补0
                count <= count + 6'd1; //本轮生成1位商，计数器加1
            end else begin //32位商全部生成，整理最终结果
                result <= {remainder_value, quotient_value}; //高32位保存余数，低32位保存商
                done <= 1'b1; //结果有效，CPU将在下一上升沿把结果写入HI和LO
            end
        end
    end
endmodule
