`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/30 21:37:55
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

module DMEM(
    input dm_clk,
    input dm_ena,
    input dm_r,
    input dm_w,
    input [12:0] dm_addr,
    input [31:0] dm_data_in,
    input [1:0] dm_size,
    input dm_unsigned, // 读出的数据不满32位时，1表示左边补0，0表示左边复制符号位
    output [31:0] dm_data_out
);
    reg [7:0] dmem0 [0:2047]; // 四个dmem数组可以看成四列，这一列存每行第1个字节
    reg [7:0] dmem1 [0:2047]; // 这一列存每行第2个字节
    reg [7:0] dmem2 [0:2047]; // 这一列存每行第3个字节
    reg [7:0] dmem3 [0:2047]; // 这一列存每行第4个字节，四列合起来是一个32 bit的字
    integer i;
    wire [10:0] wa = dm_addr[12:2];      // 地址高11位选择哪一行，也就是字节地址除以4
    wire [1:0] byte_sel = dm_addr[1:0];  // 地址低2位选择这一行中的哪一个字节列
    reg [31:0] read_data; // 把读出的字节或半字扩展成32位后存在这里

    assign dm_data_out = read_data; // 把整理好的32位读取结果送回CPU

    initial begin // 开始时执行一次，把2048行的四列全部清0，不需要等2048个时钟
        read_data = 32'h0000_0000; 
        for (i = 0; i < 2048; i = i + 1) begin
            dmem0[i] = 8'h00;
            dmem1[i] = 8'h00;
            dmem2[i] = 8'h00;
            dmem3[i] = 8'h00;
        end
    end

    always @(posedge dm_clk) begin // 只在dm_clk从0变成1时进行一次读写
        if (dm_ena && dm_w && !dm_r) begin // 存储器已启用，并且现在只写不读
            case (dm_size) // 00执行SB，01执行SH，CPU正常给10时执行SW
                2'b00: begin // SB只写dm_data_in的最低8位，这次用不到高24位
                    case (byte_sel)
                        2'b00: dmem0[wa] <= dm_data_in[7:0];
                        2'b01: dmem1[wa] <= dm_data_in[7:0];
                        2'b10: dmem2[wa] <= dm_data_in[7:0];
                        default: dmem3[wa] <= dm_data_in[7:0];
                    endcase
                end
                2'b01: begin // SH一次写相邻的两个字节
                    if (byte_sel[1]) begin // 为1就写一行的后两列，否则写前两列
                        dmem2[wa] <= dm_data_in[7:0];
                        dmem3[wa] <= dm_data_in[15:8];
                    end else begin
                        dmem0[wa] <= dm_data_in[7:0];
                        dmem1[wa] <= dm_data_in[15:8];
                    end
                end
                default: begin // SW把32位数据拆成四个字节，写满同一行
                    dmem0[wa] <= dm_data_in[7:0];
                    dmem1[wa] <= dm_data_in[15:8];
                    dmem2[wa] <= dm_data_in[23:16];
                    dmem3[wa] <= dm_data_in[31:24];
                end
            endcase
        end

        if (dm_ena && dm_r && !dm_w) begin // 存储器已启用，并且现在只读不写
            case (dm_size)
                2'b00: begin // LB和LBU只读一个字节，再把它扩展成32位
                    case (byte_sel)
                        2'b00: read_data <= dm_unsigned ? {24'h0, dmem0[wa]} :
                                                     {{24{dmem0[wa][7]}}, dmem0[wa]}; // 读第1列，LBU补0，LB复制符号位24次并补充
                        2'b01: read_data <= dm_unsigned ? {24'h0, dmem1[wa]} :
                                                     {{24{dmem1[wa][7]}}, dmem1[wa]}; 
                        2'b10: read_data <= dm_unsigned ? {24'h0, dmem2[wa]} :
                                                     {{24{dmem2[wa][7]}}, dmem2[wa]};
                        default: read_data <= dm_unsigned ? {24'h0, dmem3[wa]} :
                                                     {{24{dmem3[wa][7]}}, dmem3[wa]}; 
                    endcase
                end
                2'b01: begin
                    if (byte_sel[1])
                        read_data <= dm_unsigned ? {16'h0, dmem3[wa], dmem2[wa]} :
                                               {{16{dmem3[wa][7]}}, dmem3[wa], dmem2[wa]};// 读第3、4列，LHU补0，LH复制符号最高位16次并补充
                    else
                        read_data <= dm_unsigned ? {16'h0, dmem1[wa], dmem0[wa]} :
                                               {{16{dmem1[wa][7]}}, dmem1[wa], dmem0[wa]};
                end
                default: read_data <= {dmem3[wa], dmem2[wa], dmem1[wa], dmem0[wa]};//LW整行直接拼接成32位
            endcase
        end
    end
endmodule
