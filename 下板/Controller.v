`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/01 14:53:28
// Design Name: 
// Module Name: Controller
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

module Controller(
    input i_add,
    input i_addu,
    input i_sub,
    input i_subu,
    input i_and,
    input i_or,
    input i_xor,
    input i_nor,
    input i_slt,
    input i_sltu,
    input i_sll,
    input i_srl,
    input i_sra,
    input i_sllv,
    input i_srlv,
    input i_srav,
    input i_jr,
    input i_jalr,
    input i_syscall,
    input i_break,
    input i_mfhi,
    input i_mthi,
    input i_mflo,
    input i_mtlo,
    input i_mult,
    input i_multu,
    input i_div,
    input i_divu,
    input i_teq,
    input i_mfc0,
    input i_mtc0,
    input i_eret,
    input i_clz,
    input i_bgez,
    input i_beq,
    input i_bne,
    input i_addi,
    input i_addiu,
    input i_slti,
    input i_sltiu,
    input i_andi,
    input i_ori,
    input i_xori,
    input i_lui,
    input i_lb,
    input i_lh,
    input i_lw,
    input i_lbu,
    input i_lhu,
    input i_sb,
    input i_sh,
    input i_sw,
    input i_j,
    input i_jal,
    input rs_equal_rt,
    input rs_negative,
    input load_busy,
    input mdu_busy,
    output reg [2:0] M1,
    output reg [2:0] M2,
    output reg M3,
    output reg M4,
    output reg ext_zero,
    output reg [1:0] rdc_sel,
    output reg [3:0] ALUC,
    output reg RF_W,
    output reg DM_R,
    output reg DM_W,
    output reg [1:0] DM_Size,
    output reg DM_Unsigned,
    output reg mult_start,
    output reg mult_signed,
    output reg div_start,
    output reg div_signed,
    output reg hi_write_rs,
    output reg lo_write_rs,
    output reg cp0_write,
    output reg cp0_eret,
    output reg exception,
    output reg [4:0] exception_code
);
    always @(*) begin
        M1 = 3'b000;              // PC_next选择NPC
        M2 = 3'b000;              // Rd选择ALU结果
        M3 = 1'b1;                // ALU输入A选择Rs
        M4 = 1'b0;                // ALU输入B选择Rt
        ext_zero = 1'b0;          // Ext16默认进行符号扩展
        rdc_sel = 2'b00;          // Rdc默认选择rt字段
        ALUC = 4'b0000;           // ALU默认执行加法
        RF_W = 1'b0;
        DM_R = 1'b0;
        DM_W = 1'b0;
        DM_Size = 2'b10;          // 默认按32位字访问DMEM
        DM_Unsigned = 1'b0;
        mult_start = 1'b0;
        mult_signed = 1'b0;
        div_start = 1'b0;
        div_signed = 1'b0;
        hi_write_rs = 1'b0;
        lo_write_rs = 1'b0;
        cp0_write = 1'b0;
        cp0_eret = 1'b0;
        exception = 1'b0;
        exception_code = 5'b00000;

        if (i_add || i_addu) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0000;
        end else if (i_sub || i_subu) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0001;
        end else if (i_and) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0010;
        end else if (i_or) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0011;
        end else if (i_xor) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0100;
        end else if (i_nor) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0101;
        end else if (i_slt) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0110;
        end else if (i_sltu) begin
            RF_W = 1'b1; rdc_sel = 2'b01; ALUC = 4'b0111;
        end else if (i_sll || i_srl || i_sra) begin
            RF_W = 1'b1; rdc_sel = 2'b01; M3 = 1'b0;
            if (i_sll) ALUC = 4'b1000;
            else if (i_srl) ALUC = 4'b1001;
            else ALUC = 4'b1010;
        end else if (i_sllv || i_srlv || i_srav) begin
            RF_W = 1'b1; rdc_sel = 2'b01;
            if (i_sllv) ALUC = 4'b1000;
            else if (i_srlv) ALUC = 4'b1001;
            else ALUC = 4'b1010;
        end else if (i_addi || i_addiu) begin
            RF_W = 1'b1; M4 = 1'b1; ALUC = 4'b0000;
        end else if (i_slti) begin
            RF_W = 1'b1; M4 = 1'b1; ALUC = 4'b0110;
        end else if (i_sltiu) begin
            RF_W = 1'b1; M4 = 1'b1; ALUC = 4'b0111;
        end else if (i_andi || i_ori || i_xori) begin
            RF_W = 1'b1; M4 = 1'b1; ext_zero = 1'b1;
            if (i_andi) ALUC = 4'b0010;
            else if (i_ori) ALUC = 4'b0011;
            else ALUC = 4'b0100;
        end else if (i_lui) begin
            RF_W = 1'b1; M2 = 3'b111;
        end else if (i_lb || i_lbu || i_lh || i_lhu || i_lw) begin
            RF_W = load_busy; M2 = 3'b001; M4 = 1'b1; ALUC = 4'b0000;
        end else if (i_sb || i_sh || i_sw) begin
            M4 = 1'b1; ALUC = 4'b0000;
        end else if (i_jal) begin
            RF_W = 1'b1; rdc_sel = 2'b10; M2 = 3'b010;//JAL跳转的同时把下一条指令地址NPC写入31号寄存器，供函数执行结束后返回
        end else if (i_jalr) begin
            RF_W = 1'b1; rdc_sel = 2'b11; M2 = 3'b010;
        end else if (i_mfhi) begin
            RF_W = 1'b1; rdc_sel = 2'b01; M2 = 3'b011;
        end else if (i_mflo) begin
            RF_W = 1'b1; rdc_sel = 2'b01; M2 = 3'b100;
        end else if (i_mfc0) begin
            RF_W = 1'b1; M2 = 3'b101;
        end else if (i_clz) begin
            RF_W = 1'b1; rdc_sel = 2'b01; M2 = 3'b110;
        end

        DM_R = i_lb || i_lbu || i_lh || i_lhu || i_lw;
        DM_W = i_sb || i_sh || i_sw;
        if (i_lb || i_lbu || i_sb) DM_Size = 2'b00;
        else if (i_lh || i_lhu || i_sh) DM_Size = 2'b01;
        else DM_Size = 2'b10;
        DM_Unsigned = i_lbu || i_lhu;

        mult_start = i_mult || i_multu;
        mult_signed = i_mult;
        div_start = i_div || i_divu;
        div_signed = i_div;
        hi_write_rs = i_mthi;
        lo_write_rs = i_mtlo;
        cp0_write = i_mtc0;
        cp0_eret = i_eret;

        exception = i_break || i_syscall || (i_teq && rs_equal_rt);
        if (i_syscall) exception_code = 5'b01000;
        else if (i_break) exception_code = 5'b01001;
        else if (i_teq && rs_equal_rt) exception_code = 5'b01101;

        if ((i_beq && rs_equal_rt) || (i_bne && !rs_equal_rt) ||
            (i_bgez && !rs_negative)) M1 = 3'b001;
        else if (i_j || i_jal) M1 = 3'b010;
        else if (i_jr || i_jalr) M1 = 3'b011;
        else if (i_eret) M1 = 3'b100;
        else if (exception) M1 = 3'b101;
        if (mdu_busy || load_busy) M1 = 3'b110;
    end
endmodule
