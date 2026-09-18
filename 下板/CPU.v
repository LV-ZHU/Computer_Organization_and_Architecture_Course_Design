`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/31 19:01:19
// Design Name: 
// Module Name: CPU
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

module CPU(
    input clk,
    input rst,
    input [31:0] IM,
    input [31:0] DM_Data_out,
    output [31:0] pc,
    output DM_R,
    output DM_W,
    output [31:0] DM_Addr,
    output [31:0] DM_Data_in,
    output [1:0] DM_Size,
    output DM_Unsigned
);
    wire [5:0] OP = IM[31:26];
    wire [4:0] Rsc = IM[25:21];
    wire [4:0] Rtc = IM[20:16];
    wire [4:0] IM_15_11 = IM[15:11];
    wire [4:0] sa = IM[10:6];
    wire [5:0] FUNC = IM[5:0];
    wire [15:0] Imm16 = IM[15:0];
    wire [25:0] target = IM[25:0];

    wire [31:0] Rs;
    wire [31:0] Rt;
    wire RF_W;
    wire RF_W_raw;
    reg [4:0] Rdc;
    reg [31:0] Rd;

    regfile cpu_ref(
        .clk(clk), .rst(rst), .RegWrite(RF_W),
        .raddr1(Rsc), .raddr2(Rtc), .waddr(Rdc), .wdata(Rd),
        .rdata1(Rs), .rdata2(Rt)
    );

    wire [31:0] Ext5 = {27'h0, sa};
    wire [31:0] Ext16_sign = {{16{Imm16[15]}}, Imm16};
    wire [31:0] Ext16_zero = {16'h0000, Imm16};
    wire [31:0] NPC = pc + 32'd4;
    wire [31:0] BranchAddr = NPC + {{14{Imm16[15]}}, Imm16, 2'b00};
    wire [31:0] JumpAddr = {NPC[31:28], target, 2'b00};
    reg [31:0] PC_next;

    PC pc_reg(.clk(clk), .rst(rst), .pc_next(PC_next), .pc(pc));

    reg [31:0] hi;
    reg [31:0] lo;
    reg [31:0] cp0_status;
    reg [31:0] cp0_cause;
    reg [31:0] cp0_epc;
    wire [31:0] cp0_rdata = (IM_15_11 == 5'd12) ? cp0_status :
                             (IM_15_11 == 5'd13) ? cp0_cause :
                             (IM_15_11 == 5'd14) ? cp0_epc : 32'h0;

    wire [63:0] mult_unit_result;
    wire mult_unit_busy;
    wire mult_unit_done;
    wire [63:0] div_unit_result;
    wire div_unit_busy;
    wire div_unit_done;
    wire mdu_busy = mult_unit_busy || div_unit_busy;
    wire mdu_done = mult_unit_done || div_unit_done;
    wire [63:0] mdu_result = mult_unit_done ? mult_unit_result : div_unit_result;
    reg load_busy;

    function [31:0] clz32;
        input [31:0] value;
        integer idx;
        reg found;
        begin
            clz32 = 32'd32; //默认全0情况下为32
            found = 1'b0; //标记为还没找到1
            for (idx = 31; idx >= 0; idx = idx - 1) begin
                if (!found && value[idx]) begin//如果还没找到且第idx位为1
                    clz32 = 31 - idx;//第idx+1..31都是0，故clz32是(31-(idx+1))+1=31-idx
                    found = 1'b1;
                end
            end
        end
    endfunction

    wire i_add, i_addu, i_sub, i_subu, i_and, i_or, i_xor, i_nor;
    wire i_slt, i_sltu, i_sll, i_srl, i_sra, i_sllv, i_srlv, i_srav;
    wire i_jr, i_jalr, i_syscall, i_break, i_mfhi, i_mthi, i_mflo, i_mtlo;
    wire i_mult, i_multu, i_div, i_divu, i_teq;
    wire i_mfc0, i_mtc0, i_eret, i_clz;
    wire i_bgez, i_beq, i_bne;
    wire i_addi, i_addiu, i_slti, i_sltiu, i_andi, i_ori, i_xori, i_lui;
    wire i_lb, i_lh, i_lw, i_lbu, i_lhu, i_sb, i_sh, i_sw;
    wire i_j, i_jal;

    Decoder decoder(
        .OP(OP), .Rsc(Rsc), .Rtc(Rtc), .FUNC(FUNC),
        .i_add(i_add), .i_addu(i_addu), .i_sub(i_sub), .i_subu(i_subu),
        .i_and(i_and), .i_or(i_or), .i_xor(i_xor), .i_nor(i_nor),
        .i_slt(i_slt), .i_sltu(i_sltu), .i_sll(i_sll), .i_srl(i_srl),
        .i_sra(i_sra), .i_sllv(i_sllv), .i_srlv(i_srlv), .i_srav(i_srav),
        .i_jr(i_jr), .i_jalr(i_jalr), .i_syscall(i_syscall), .i_break(i_break),
        .i_mfhi(i_mfhi), .i_mthi(i_mthi), .i_mflo(i_mflo), .i_mtlo(i_mtlo),
        .i_mult(i_mult), .i_multu(i_multu), .i_div(i_div), .i_divu(i_divu),
        .i_teq(i_teq), .i_mfc0(i_mfc0), .i_mtc0(i_mtc0), .i_eret(i_eret),
        .i_clz(i_clz), .i_bgez(i_bgez), .i_beq(i_beq), .i_bne(i_bne),
        .i_addi(i_addi), .i_addiu(i_addiu), .i_slti(i_slti), .i_sltiu(i_sltiu),
        .i_andi(i_andi), .i_ori(i_ori), .i_xori(i_xori), .i_lui(i_lui),
        .i_lb(i_lb), .i_lh(i_lh), .i_lw(i_lw), .i_lbu(i_lbu),
        .i_lhu(i_lhu), .i_sb(i_sb), .i_sh(i_sh), .i_sw(i_sw),
        .i_j(i_j), .i_jal(i_jal)
    );

    wire [2:0] M1;
    wire [2:0] M2;
    wire M3;
    wire M4;
    wire ext_zero;
    wire [1:0] rdc_sel;
    wire [3:0] ALUC;
    wire mult_start;
    wire mult_signed;
    wire div_start;
    wire div_signed;
    wire hi_write_rs;
    wire lo_write_rs;
    wire cp0_write;
    wire cp0_eret;
    wire exception;
    wire hi_write_rs_raw;
    wire lo_write_rs_raw;
    wire cp0_write_raw;
    wire cp0_eret_raw;
    wire exception_raw;
    wire DM_R_raw;
    wire DM_W_raw;
    wire [4:0] exception_code;
    wire rs_equal_rt = (Rs == Rt);
    wire rs_negative = Rs[31];

    assign RF_W = RF_W_raw && !mdu_busy;
    assign DM_R = DM_R_raw && !mdu_busy;
    assign DM_W = DM_W_raw && !mdu_busy;
    assign hi_write_rs = hi_write_rs_raw && !mdu_busy;
    assign lo_write_rs = lo_write_rs_raw && !mdu_busy;
    assign cp0_write = cp0_write_raw && !mdu_busy;
    assign cp0_eret = cp0_eret_raw && !mdu_busy;
    assign exception = exception_raw && !mdu_busy;

    Controller controller(
        .i_add(i_add), .i_addu(i_addu), .i_sub(i_sub), .i_subu(i_subu),
        .i_and(i_and), .i_or(i_or), .i_xor(i_xor), .i_nor(i_nor),
        .i_slt(i_slt), .i_sltu(i_sltu), .i_sll(i_sll), .i_srl(i_srl),
        .i_sra(i_sra), .i_sllv(i_sllv), .i_srlv(i_srlv), .i_srav(i_srav),
        .i_jr(i_jr), .i_jalr(i_jalr), .i_syscall(i_syscall), .i_break(i_break),
        .i_mfhi(i_mfhi), .i_mthi(i_mthi), .i_mflo(i_mflo), .i_mtlo(i_mtlo),
        .i_mult(i_mult), .i_multu(i_multu), .i_div(i_div), .i_divu(i_divu),
        .i_teq(i_teq), .i_mfc0(i_mfc0), .i_mtc0(i_mtc0), .i_eret(i_eret),
        .i_clz(i_clz), .i_bgez(i_bgez), .i_beq(i_beq), .i_bne(i_bne),
        .i_addi(i_addi), .i_addiu(i_addiu), .i_slti(i_slti), .i_sltiu(i_sltiu),
        .i_andi(i_andi), .i_ori(i_ori), .i_xori(i_xori), .i_lui(i_lui),
        .i_lb(i_lb), .i_lh(i_lh), .i_lw(i_lw), .i_lbu(i_lbu),
        .i_lhu(i_lhu), .i_sb(i_sb), .i_sh(i_sh), .i_sw(i_sw),
        .i_j(i_j), .i_jal(i_jal),
        .rs_equal_rt(rs_equal_rt), .rs_negative(rs_negative),
        .load_busy(load_busy), .mdu_busy(mdu_busy),
        .M1(M1), .M2(M2), .M3(M3), .M4(M4), .ext_zero(ext_zero),
        .rdc_sel(rdc_sel), .ALUC(ALUC), .RF_W(RF_W_raw),
        .DM_R(DM_R_raw), .DM_W(DM_W_raw), .DM_Size(DM_Size), .DM_Unsigned(DM_Unsigned),
        .mult_start(mult_start), .mult_signed(mult_signed),
        .div_start(div_start), .div_signed(div_signed),
        .hi_write_rs(hi_write_rs_raw), .lo_write_rs(lo_write_rs_raw),
        .cp0_write(cp0_write_raw), .cp0_eret(cp0_eret_raw),
        .exception(exception_raw), .exception_code(exception_code)
    );

    wire [31:0] Ext16 = ext_zero ? Ext16_zero : Ext16_sign;
    wire [31:0] alu_a = M3 ? Rs : Ext5;
    wire [31:0] alu_b = M4 ? Ext16 : Rt;
    reg [31:0] alu_result;

    always @(*) begin
        case (ALUC)
            4'b0000: alu_result = alu_a + alu_b;
            4'b0001: alu_result = alu_a - alu_b;
            4'b0010: alu_result = alu_a & alu_b;
            4'b0011: alu_result = alu_a | alu_b;
            4'b0100: alu_result = alu_a ^ alu_b;
            4'b0101: alu_result = ~(alu_a | alu_b);
            4'b0110: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0;
            4'b0111: alu_result = (alu_a < alu_b) ? 32'd1 : 32'd0;
            4'b1000: alu_result = alu_b << alu_a[4:0];
            4'b1001: alu_result = alu_b >> alu_a[4:0];
            4'b1010: alu_result = $signed(alu_b) >>> alu_a[4:0];
            default: alu_result = 32'h0;
        endcase
    end

    always @(*) begin
        case (rdc_sel)
            2'b00: Rdc = Rtc;
            2'b01: Rdc = IM_15_11;
            2'b10: Rdc = 5'd31;
            default: Rdc = (IM_15_11 == 5'd0) ? 5'd31 : IM_15_11;
        endcase
    end

    always @(*) begin
        case (M2)
            3'b000: Rd = alu_result;
            3'b001: Rd = DM_Data_out;
            3'b010: Rd = NPC;
            3'b011: Rd = hi;
            3'b100: Rd = lo;
            3'b101: Rd = cp0_rdata;
            3'b110: Rd = clz32(Rs);
            default: Rd = {Imm16, 16'h0};
        endcase
    end

    always @(*) begin
        case (M1)
            3'b000: PC_next = NPC;
            3'b001: PC_next = BranchAddr;
            3'b010: PC_next = JumpAddr;
            3'b011: PC_next = Rs;
            3'b100: PC_next = cp0_epc + 32'd4;
            3'b101: PC_next = 32'h0040_0004;
            3'b110: PC_next = pc;
            default: PC_next = NPC;
        endcase
    end

    assign DM_Addr = alu_result;
    assign DM_Data_in = Rt;

    multiplier cpu_multiplier(
        .clk(clk), .rst(rst),
        .start(mult_start && !mdu_busy), .signed_mode(mult_signed),
        .a(Rs), .b(Rt),
        .result(mult_unit_result), .busy(mult_unit_busy), .done(mult_unit_done)
    );

    divider cpu_divider(
        .clk(clk), .rst(rst),
        .start(div_start && !mdu_busy), .signed_mode(div_signed),
        .dividend(Rs), .divisor(Rt),
        .result(div_unit_result), .busy(div_unit_busy), .done(div_unit_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hi <= 32'h0;
            lo <= 32'h0;
            load_busy <= 1'b0;
            cp0_status <= 32'h0;
            cp0_cause <= 32'h0;
            cp0_epc <= 32'h0;
        end else begin
            if (load_busy)
                load_busy <= 1'b0;
            else if (DM_R)
                load_busy <= 1'b1;

            if (mdu_done) begin
                hi <= mdu_result[63:32];
                lo <= mdu_result[31:0];
            end else if (hi_write_rs) begin
                hi <= Rs;
            end else if (lo_write_rs) begin
                lo <= Rs;
            end

            if (cp0_write && IM_15_11 == 5'd12) cp0_status <= Rt;
            if (cp0_write && IM_15_11 == 5'd13) cp0_cause <= Rt;
            if (cp0_write && IM_15_11 == 5'd14) cp0_epc <= Rt;
            if (exception) begin
                cp0_status <= cp0_status << 5;
                cp0_cause <= {25'h0, exception_code, 2'b00};
                cp0_epc <= pc;
            end else if (cp0_eret) begin
                cp0_status <= cp0_status >> 5;
            end
        end
    end
endmodule

