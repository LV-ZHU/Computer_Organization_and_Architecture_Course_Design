`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/31 15:23:21
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

module board_sccomp_dataflow(
    input clk_in,
    input reset,
    output [7:0] o_seg,
    output [7:0] o_sel
);
    wire cpu_clk;
    wire [31:0] inst;
    wire [31:0] pc;
    reg [31:0] pc_sync_1;
    reg [31:0] pc_sync_2;

    cpu_clock_divider #(
        .HALF_PERIOD_CYCLES(10000000)
    ) cpu_clock_divider_inst(
        .clk_in(clk_in),
        .reset(reset),
        .clk_out(cpu_clk)
    );

    sccomp_dataflow cpu_core(
        .clk_in(cpu_clk),
        .reset(reset),
        .inst(inst),
        .pc(pc)
    );

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            pc_sync_1 <= 32'h0;
            pc_sync_2 <= 32'h0;
        end else begin
            pc_sync_1 <= pc;
            pc_sync_2 <= pc_sync_1;
        end
    end

    seg7x16 display_inst(
        .clk(clk_in),
        .reset(reset),
        .cs(1'b1),
        .i_data(pc_sync_2),
        .o_seg(o_seg),
        .o_sel(o_sel)
    );
endmodule
