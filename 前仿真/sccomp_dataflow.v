`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/30 21:36:05
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

module sccomp_dataflow(
    input clk_in,
    input reset,
    output [31:0] inst,
    output [31:0] pc
);
    wire [31:0] cpu_pc;
    wire [31:0] cpu_instr;
    wire DM_R;
    wire DM_W;
    wire DM_CS = DM_R || DM_W;
    wire [31:0] DM_Addr;
    wire [31:0] DM_Data_in;
    wire [31:0] DM_Data_out;
    wire [1:0] DM_Size;
    wire DM_Unsigned;

    wire [31:0] imem_byte_addr = cpu_pc - 32'h0040_0000; //将MIPS指令地址换成从0开始的ROM相对地址
    wire [10:0] imem_word_addr = imem_byte_addr[12:2]; //每条指令占4字节，除以4后得到2048深度ROM的下标
    wire [31:0] dmem_byte_addr = DM_Addr - 32'h1001_0000; //将MIPS数据地址换成从0开始的DMEM相对地址
    wire [12:0] dmem_addr = dmem_byte_addr[12:0]; //DMEM共8192字节，只需要保留低13位作为内部地址

    assign pc = cpu_pc;
    assign inst = cpu_instr;

    CPU sccpu(
        .clk(clk_in),
        .rst(reset),
        .IM(cpu_instr),
        .DM_Data_out(DM_Data_out),
        .pc(cpu_pc),
        .DM_R(DM_R),
        .DM_W(DM_W),
        .DM_Addr(DM_Addr),
        .DM_Data_in(DM_Data_in),
        .DM_Size(DM_Size),
        .DM_Unsigned(DM_Unsigned)
    );

    IMEM imem(
        .im_addr_in(imem_word_addr),
        .im_instr_out(cpu_instr)
    );

    DMEM dmem(
        .dm_clk(clk_in),
        .dm_ena(DM_CS),
        .dm_r(DM_R),
        .dm_w(DM_W),
        .dm_addr(dmem_addr),
        .dm_data_in(DM_Data_in),
        .dm_size(DM_Size),
        .dm_unsigned(DM_Unsigned),
        .dm_data_out(DM_Data_out)
    );
endmodule
