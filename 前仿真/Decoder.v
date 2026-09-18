`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/01 17:21:30
// Design Name: 
// Module Name: Decoder
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

module Decoder(
    input [5:0] OP,
    input [4:0] Rsc,
    input [4:0] Rtc,
    input [5:0] FUNC,
    output i_add,
    output i_addu,
    output i_sub,
    output i_subu,
    output i_and,
    output i_or,
    output i_xor,
    output i_nor,
    output i_slt,
    output i_sltu,
    output i_sll,
    output i_srl,
    output i_sra,
    output i_sllv,
    output i_srlv,
    output i_srav,
    output i_jr,
    output i_jalr,
    output i_syscall,
    output i_break,
    output i_mfhi,
    output i_mthi,
    output i_mflo,
    output i_mtlo,
    output i_mult,
    output i_multu,
    output i_div,
    output i_divu,
    output i_teq,
    output i_mfc0,
    output i_mtc0,
    output i_eret,
    output i_clz,
    output i_bgez,
    output i_beq,
    output i_bne,
    output i_addi,
    output i_addiu,
    output i_slti,
    output i_sltiu,
    output i_andi,
    output i_ori,
    output i_xori,
    output i_lui,
    output i_lb,
    output i_lh,
    output i_lw,
    output i_lbu,
    output i_lhu,
    output i_sb,
    output i_sh,
    output i_sw,
    output i_j,
    output i_jal
);
    assign i_add = (OP == 6'b000000 && FUNC == 6'b100000); //R型指令由OP和FUNC共同区分
    assign i_addu = (OP == 6'b000000 && FUNC == 6'b100001);
    assign i_sub = (OP == 6'b000000 && FUNC == 6'b100010);
    assign i_subu = (OP == 6'b000000 && FUNC == 6'b100011);
    assign i_and = (OP == 6'b000000 && FUNC == 6'b100100);
    assign i_or = (OP == 6'b000000 && FUNC == 6'b100101);
    assign i_xor = (OP == 6'b000000 && FUNC == 6'b100110);
    assign i_nor = (OP == 6'b000000 && FUNC == 6'b100111);
    assign i_slt = (OP == 6'b000000 && FUNC == 6'b101010);
    assign i_sltu = (OP == 6'b000000 && FUNC == 6'b101011);
    assign i_sll = (OP == 6'b000000 && FUNC == 6'b000000);
    assign i_srl = (OP == 6'b000000 && FUNC == 6'b000010);
    assign i_sra = (OP == 6'b000000 && FUNC == 6'b000011);
    assign i_sllv = (OP == 6'b000000 && FUNC == 6'b000100);
    assign i_srlv = (OP == 6'b000000 && FUNC == 6'b000110);
    assign i_srav = (OP == 6'b000000 && FUNC == 6'b000111);
    assign i_jr = (OP == 6'b000000 && FUNC == 6'b001000);
    assign i_jalr = (OP == 6'b000000 && FUNC == 6'b001001);
    assign i_syscall = (OP == 6'b000000 && FUNC == 6'b001100);
    assign i_break = (OP == 6'b000000 && FUNC == 6'b001101);
    assign i_mfhi = (OP == 6'b000000 && FUNC == 6'b010000);
    assign i_mthi = (OP == 6'b000000 && FUNC == 6'b010001);
    assign i_mflo = (OP == 6'b000000 && FUNC == 6'b010010);
    assign i_mtlo = (OP == 6'b000000 && FUNC == 6'b010011);
    assign i_mult = (OP == 6'b000000 && FUNC == 6'b011000);
    assign i_multu = (OP == 6'b000000 && FUNC == 6'b011001);
    assign i_div = (OP == 6'b000000 && FUNC == 6'b011010);
    assign i_divu = (OP == 6'b000000 && FUNC == 6'b011011);
    assign i_teq = (OP == 6'b000000 && FUNC == 6'b110100);

    assign i_mfc0 = (OP == 6'b010000 && Rsc == 5'b00000); //CP0类指令使用Rsc继续区分功能
    assign i_mtc0 = (OP == 6'b010000 && Rsc == 5'b00100);
    assign i_eret = (OP == 6'b010000 && Rsc == 5'b10000 && FUNC == 6'b011000);
    assign i_clz = (OP == 6'b011100 && FUNC == 6'b100000);

    assign i_bgez = (OP == 6'b000001 && Rtc == 5'b00001); //BGEZ还要检查rt字段
    assign i_beq = (OP == 6'b000100);
    assign i_bne = (OP == 6'b000101);
    assign i_addi = (OP == 6'b001000);
    assign i_addiu = (OP == 6'b001001);
    assign i_slti = (OP == 6'b001010);
    assign i_sltiu = (OP == 6'b001011);
    assign i_andi = (OP == 6'b001100);
    assign i_ori = (OP == 6'b001101);
    assign i_xori = (OP == 6'b001110);
    assign i_lui = (OP == 6'b001111);
    assign i_lb = (OP == 6'b100000);
    assign i_lh = (OP == 6'b100001);
    assign i_lw = (OP == 6'b100011);
    assign i_lbu = (OP == 6'b100100);
    assign i_lhu = (OP == 6'b100101);
    assign i_sb = (OP == 6'b101000);
    assign i_sh = (OP == 6'b101001);
    assign i_sw = (OP == 6'b101011);
    assign i_j = (OP == 6'b000010);
    assign i_jal = (OP == 6'b000011);
endmodule
