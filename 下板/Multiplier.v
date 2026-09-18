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
    output reg [63:0] result,
    output reg busy,
    output reg done
);
    reg [2:0] phase; //当前进行的阶段，000-100分别对应5个阶段
    reg [63:0] partial [0:31];//32个部分积，每个部分积64位
    reg [63:0] sum_2 [0:15];//第一轮两两相加后变为16个中间和
    reg [63:0] sum_3 [0:7];//第二轮两两相加后变为8个中间和
    reg [63:0] sum_4 [0:3];//第三轮两两相加后变为4个中间和
    reg [63:0] sum_5 [0:1];//第四轮两两相加后变为2个中间和

    wire [63:0] signed_a = {{32{a[31]}}, a};//将a扩展为64位有符号数，复制符号位32次
    wire [63:0] neg_signed_a = ~signed_a + 64'd1;//按位取反加1得到-a的补码表示
    wire [32:0] booth_b = {b, 1'b0};//补1个0开始Booth
    wire [63:0] unsigned_a = {32'h0000_0000, a};//无符号的a直接补32个0

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin //把结果、busy、完成、阶段号和所有部分积、中间和清零
            result <= 64'h0;
            busy <= 1'b0;
            done <= 1'b0;
            phase <= 3'd0;
            for (i = 0; i < 32; i = i + 1)
                partial[i] <= 64'h0;
            for (i = 0; i < 16; i = i + 1)
                sum_2[i] <= 64'h0;
            for (i = 0; i < 8; i = i + 1)
                sum_3[i] <= 64'h0;
            for (i = 0; i < 4; i = i + 1)
                sum_4[i] <= 64'h0;
            for (i = 0; i < 2; i = i + 1)
                sum_5[i] <= 64'h0;
        end else if (done) begin //如果完成了乘法运算，清除busy和done信号
            done <= 1'b0;
            busy <= 1'b0;
        end else if (start && !busy) begin //如果开始乘法运算且当前不忙，则设置busy信号并进入第0阶段，也即计算partial部分积阶段
            busy <= 1'b1;
            phase <= 3'd0;
            if (signed_mode) begin //MULT
                for (i = 0; i < 32; i = i + 1) begin //遍历32位的b，计算每一位对应的部分积
                    case ({booth_b[i + 1], booth_b[i]})
                        2'b01: partial[i] <= signed_a << i; //01,则加a(左移i位即乘以2^i)
                        2'b10: partial[i] <= neg_signed_a << i; //10,则减a(左移i位即乘以2^i)
                        default: partial[i] <= 64'h0;//00或11则部分积为0
                    endcase
                end
            end else begin //MULTU
                for (i = 0; i < 32; i = i + 1)
                    partial[i] <= b[i] ? (unsigned_a << i) : 64'h0; //如果b的第i位为1，则部分积为a左移i位，否则第i位为0，部分积为0
            end
        end else if (busy) begin //busy已经在上一个分支里变为1了，开始进入阶段计算
            done <= 1'b0;
            case (phase)
                3'd0: begin //32变16
                    for (i = 0; i < 16; i = i + 1) //并行得到16个中间和
                        sum_2[i] <= partial[i << 1] + partial[(i << 1) + 1];//类似二叉树的下标规律，把2i和2i+1的部分积(类似左右孩子)相加得到第i个部分积(类似父节点)
                    phase <= 3'd1; //进入下一阶段
                end
                3'd1: begin //16变8
                    for (i = 0; i < 8; i = i + 1)
                        sum_3[i] <= sum_2[i << 1] + sum_2[(i << 1) + 1];
                    phase <= 3'd2;
                end
                3'd2: begin //8变4
                    for (i = 0; i < 4; i = i + 1)
                        sum_4[i] <= sum_3[i << 1] + sum_3[(i << 1) + 1];
                    phase <= 3'd3;
                end
                3'd3: begin //4变2
                    sum_5[0] <= sum_4[0] + sum_4[1];
                    sum_5[1] <= sum_4[2] + sum_4[3];
                    phase <= 3'd4;
                end
                default: begin //2变1，即最终结果
                    result <= sum_5[0] + sum_5[1];
                    done <= 1'b1; //完成乘法运算，设置done信号，标记结果有效，CPU将在下个上升沿写入HI和LO寄存器
                end
            endcase
        end
    end
endmodule
