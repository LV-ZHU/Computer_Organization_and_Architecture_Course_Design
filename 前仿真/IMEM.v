`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/30 21:36:35
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

module IMEM(
    input [10:0] im_addr_in,
    output [31:0] im_instr_out
);
    reg [31:0] rom [0:2047]; //每个单元保存一条32位指令，2048个单元与IP核深度一致
    integer i;

    initial begin
        for (i = 0; i < 2048; i = i + 1)
            rom[i] = 32'h0000_0000;
        $readmemh("program.hex", rom); //前仿真直接读取与官方COE内容一致的十六进制指令
    end

    assign im_instr_out = rom[im_addr_in]; //PC已经在顶层换算成按字编号的ROM下标
endmodule
