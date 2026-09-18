`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/30 21:35:20
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
    wire [5:0] OP = IM[31:26]; //主操作码，先区分R型、I型、J型及CP0等大类
    wire [4:0] Rsc = IM[25:21]; //rs字段，作为第一个源寄存器编号
    wire [4:0] Rtc = IM[20:16]; //rt字段，可作为第二个源寄存器编号或I型写回编号
    wire [4:0] IM_15_11 = IM[15:11]; //R型rd字段，也用于选择CP0寄存器
    wire [4:0] sa = IM[10:6]; //SLL、SRL、SRA直接写在指令中的5位移位量
    wire [5:0] FUNC = IM[5:0]; //R型指令用FUNC继续区分具体操作
    wire [15:0] Imm16 = IM[15:0]; //I型指令的16位立即数或偏移量
    wire [25:0] target = IM[25:0]; //J型指令的26位跳转目标字段

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

    wire [31:0] Ext5 = {27'h0, sa}; //把5位sa补0扩展为ALU可以使用的32位移位量
    wire [31:0] Ext16_sign = {{16{Imm16[15]}}, Imm16}; //算术、访存和分支偏移量使用符号扩展
    wire [31:0] Ext16_zero = {16'h0000, Imm16}; //ANDI、ORI、XORI使用零扩展
    wire [31:0] NPC = pc + 32'd4; //正常顺序执行时的下一条指令地址
    wire [31:0] BranchAddr = NPC + {{14{Imm16[15]}}, Imm16, 2'b00}; //分支偏移量以字为单位，左移2位后加到NPC
    wire [31:0] JumpAddr = {NPC[31:28], target, 2'b00}; //J型目标地址由NPC高4位、target和末尾两个0拼接
    reg [31:0] PC_next;

    PC pc_reg(.clk(clk), .rst(rst), .pc_next(PC_next), .pc(pc));

    reg [31:0] hi; //乘法保存高32位，除法保存余数
    reg [31:0] lo; //乘法保存低32位，除法保存商
    reg [31:0] cp0_status; //CP0的12号Status寄存器
    reg [31:0] cp0_cause; //CP0的13号Cause寄存器
    reg [31:0] cp0_epc; //CP0的14号EPC寄存器，保存发生异常的PC
    wire [31:0] cp0_rdata = (IM_15_11 == 5'd12) ? cp0_status :
                             (IM_15_11 == 5'd13) ? cp0_cause :
                             (IM_15_11 == 5'd14) ? cp0_epc : 32'h0;

    wire [63:0] mult_unit_result;
    wire mult_unit_busy;
    wire mult_unit_done;
    wire [63:0] div_unit_result;
    wire div_unit_busy;
    wire div_unit_done;
    wire mdu_busy = mult_unit_busy || div_unit_busy; //统一表示乘法器或除法器正在工作
    wire mdu_done = mult_unit_done || div_unit_done; //任一运算结束后通知CPU更新HI和LO
    wire [63:0] mdu_result = mult_unit_done ? mult_unit_result : div_unit_result; //高32位写HI，低32位写LO
    wire load_busy = 1'b0; //前仿真DMEM组合读，不需要增加等待周期

    function [31:0] clz32;
        input [31:0] value;
        integer idx;
        reg found;
        begin
            clz32 = 32'd32; //输入全0时前导0个数为32
            found = 1'b0;
            for (idx = 31; idx >= 0; idx = idx - 1) begin
                if (!found && value[idx]) begin
                    clz32 = 31 - idx;
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

    wire [2:0] M1; //PC_next来源选择：NPC、分支、跳转、Rs、EPC或异常入口
    wire [2:0] M2; //寄存器写回数据选择：ALU、DMEM、NPC、HI、LO、CP0、CLZ或LUI
    wire M3; //ALU输入A选择，1取Rs，0取Ext5
    wire M4; //ALU输入B选择，1取Ext16，0取Rt
    wire ext_zero; //控制Imm16使用零扩展还是符号扩展
    wire [1:0] rdc_sel; //写回寄存器编号选择rt、rd、31号或JALR规定的rd
    wire [3:0] ALUC; //控制ALU执行加、减、逻辑、比较或移位
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
    wire rs_equal_rt = (Rs == Rt); //BEQ、BNE和TEQ直接使用寄存器相等比较结果
    wire rs_negative = Rs[31]; //补码最高位为1表示负数，BGEZ据此判断是否跳转

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
            4'b0000: alu_result = alu_a + alu_b; //ADD及访存地址计算
            4'b0001: alu_result = alu_a - alu_b; //SUB
            4'b0010: alu_result = alu_a & alu_b; //AND
            4'b0011: alu_result = alu_a | alu_b; //OR
            4'b0100: alu_result = alu_a ^ alu_b; //XOR
            4'b0101: alu_result = ~(alu_a | alu_b); //NOR
            4'b0110: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0; //有符号比较
            4'b0111: alu_result = (alu_a < alu_b) ? 32'd1 : 32'd0; //无符号比较
            4'b1000: alu_result = alu_b << alu_a[4:0]; //逻辑左移
            4'b1001: alu_result = alu_b >> alu_a[4:0]; //逻辑右移
            4'b1010: alu_result = $signed(alu_b) >>> alu_a[4:0]; //算术右移并补符号位
            default: alu_result = 32'h0;
        endcase
    end

    always @(*) begin
        case (rdc_sel)
            2'b00: Rdc = Rtc; //I型指令写rt
            2'b01: Rdc = IM_15_11; //普通R型指令写rd
            2'b10: Rdc = 5'd31; //JAL固定写31号返回地址寄存器
            default: Rdc = (IM_15_11 == 5'd0) ? 5'd31 : IM_15_11; //JALR的rd为0时按本工程约定改写31号寄存器
        endcase
    end

    always @(*) begin
        case (M2)
            3'b000: Rd = alu_result;
            3'b001: Rd = DM_Data_out; //五条Load指令把DMEM读出的结果写回通用寄存器
            3'b010: Rd = NPC; //JAL和JALR保存当前PC+4作为返回地址
            3'b011: Rd = hi;
            3'b100: Rd = lo;
            3'b101: Rd = cp0_rdata;
            3'b110: Rd = clz32(Rs);
            default: Rd = {Imm16, 16'h0}; //LUI把立即数放到结果高16位
        endcase
    end

    always @(*) begin
        case (M1)
            3'b000: PC_next = NPC;
            3'b001: PC_next = BranchAddr;
            3'b010: PC_next = JumpAddr;
            3'b011: PC_next = Rs; //JR和JALR从寄存器取得跳转地址
            3'b100: PC_next = cp0_epc + 32'd4; //ERET返回异常指令的下一条
            3'b101: PC_next = 32'h0040_0004; //本实验指导书规定的异常处理入口
            3'b110: PC_next = pc; //多周期部件忙时保持当前PC
            default: PC_next = NPC;
        endcase
    end

    assign DM_Addr = alu_result; //Load和Store都由Rs+符号扩展偏移量得到字节地址
    assign DM_Data_in = Rt; //Store把rt寄存器中的数据送入DMEM

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
            cp0_status <= 32'h0;
            cp0_cause <= 32'h0;
            cp0_epc <= 32'h0;
        end else begin
            if (mdu_done) begin //MULT、MULTU、DIV、DIVU完成后统一更新HI和LO
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
            if (exception) begin //异常时保存现场，并由PC通路跳到0x00400004
                cp0_status <= cp0_status << 5;
                cp0_cause <= {25'h0, exception_code, 2'b00};
                cp0_epc <= pc;
            end else if (cp0_eret) begin
                cp0_status <= cp0_status >> 5;
            end
        end
    end
endmodule
