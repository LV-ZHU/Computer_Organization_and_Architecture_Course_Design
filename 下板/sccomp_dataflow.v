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
    wire [31:0] cpu_pc; //取指令
    wire [31:0] cpu_instr; //取指令
    wire DM_R;
    wire DM_W;
    wire [31:0] DM_Addr;
    wire [31:0] DM_Data_in;
    wire [31:0] DM_Data_out;
    wire [1:0] DM_Size;
    wire DM_Unsigned;
    wire DM_CS = DM_R | DM_W;

    wire [31:0] imem_byte_addr = cpu_pc - 32'h0040_0000; //计算相对地址，便于下一行转化ROM下标
    wire [10:0] imem_word_addr = imem_byte_addr[12:2]; //取出相对地址的低11位，也即除以4后的结果，IMEM_ROM共2048位故有11位即可
    wire [31:0] dmem_byte_addr = DM_Addr - 32'h1001_0000;
    wire [12:0] dmem_addr = dmem_byte_addr[12:0];

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
        .im_addr_in(imem_word_addr),// 输入的地址
        .im_instr_out(cpu_instr) //根据地址从COE中拿出的指令
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
