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
    input dm_unsigned,
    output [31:0] dm_data_out
);
    reg [7:0] dmem0 [0:2047]; //每个下标是一行，dmem0到dmem3依次保存该32位字的低字节到高字节
    reg [7:0] dmem1 [0:2047];
    reg [7:0] dmem2 [0:2047];
    reg [7:0] dmem3 [0:2047];
    integer i;
    wire [10:0] wa = dm_addr[12:2]; //去掉字节地址低2位，得到四列数组共同使用的行号
    wire [1:0] byte_sel = dm_addr[1:0]; //低2位选择一行中的具体字节
    reg [31:0] read_data;

    initial begin
        for (i = 0; i < 2048; i = i + 1) begin
            dmem0[i] = 8'h00;
            dmem1[i] = 8'h00;
            dmem2[i] = 8'h00;
            dmem3[i] = 8'h00;
        end
    end

    always @(posedge dm_clk) begin
        if (dm_ena && dm_w && !dm_r) begin
            case (dm_size)
                2'b00: begin //SB只使用dm_data_in低8位，byte_sel决定写入哪一列
                    case (byte_sel)
                        2'b00: dmem0[wa] <= dm_data_in[7:0];
                        2'b01: dmem1[wa] <= dm_data_in[7:0];
                        2'b10: dmem2[wa] <= dm_data_in[7:0];
                        default: dmem3[wa] <= dm_data_in[7:0];
                    endcase
                end
                2'b01: begin //SH使用低16位，地址第1位决定写一行的低半字还是高半字
                    if (byte_sel[1]) begin
                        dmem2[wa] <= dm_data_in[7:0];
                        dmem3[wa] <= dm_data_in[15:8];
                    end else begin
                        dmem0[wa] <= dm_data_in[7:0];
                        dmem1[wa] <= dm_data_in[15:8];
                    end
                end
                default: begin //SW按小端序把低字节写进低地址列
                    dmem0[wa] <= dm_data_in[7:0];
                    dmem1[wa] <= dm_data_in[15:8];
                    dmem2[wa] <= dm_data_in[23:16];
                    dmem3[wa] <= dm_data_in[31:24];
                end
            endcase
        end
    end

    always @(*) begin
        case (dm_size)
            2'b00: begin //LB补符号位，LBU补0，二者只在所读字节最高位为1时不同
                case (byte_sel)
                    2'b00: read_data = dm_unsigned ? {24'h0, dmem0[wa]} : {{24{dmem0[wa][7]}}, dmem0[wa]};
                    2'b01: read_data = dm_unsigned ? {24'h0, dmem1[wa]} : {{24{dmem1[wa][7]}}, dmem1[wa]};
                    2'b10: read_data = dm_unsigned ? {24'h0, dmem2[wa]} : {{24{dmem2[wa][7]}}, dmem2[wa]};
                    default: read_data = dm_unsigned ? {24'h0, dmem3[wa]} : {{24{dmem3[wa][7]}}, dmem3[wa]};
                endcase
            end
            2'b01: begin //LH和LHU先按小端序拼成16位，再分别进行符号扩展或零扩展
                if (byte_sel[1])
                    read_data = dm_unsigned ? {16'h0, dmem3[wa], dmem2[wa]} : {{16{dmem3[wa][7]}}, dmem3[wa], dmem2[wa]};
                else
                    read_data = dm_unsigned ? {16'h0, dmem1[wa], dmem0[wa]} : {{16{dmem1[wa][7]}}, dmem1[wa], dmem0[wa]};
            end
            default: read_data = {dmem3[wa], dmem2[wa], dmem1[wa], dmem0[wa]}; //LW重新拼成完整32位字
        endcase
    end

    assign dm_data_out = (dm_ena && dm_r && !dm_w) ? read_data : 32'h0; //前仿真采用组合读，当前周期即可送回CPU
endmodule
