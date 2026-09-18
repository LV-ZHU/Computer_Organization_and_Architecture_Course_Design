`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/31 17:12:19
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

module cpu_clock_divider #(
    parameter integer HALF_PERIOD_CYCLES = 500000
)(
    input clk_in,
    input reset,
    output clk_out
);
    reg [31:0] counter;
    reg divided_clk;

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 32'd0;
            divided_clk <= 1'b0;
        end else if (counter == HALF_PERIOD_CYCLES - 1) begin
            counter <= 32'd0;
            divided_clk <= ~divided_clk;
        end else begin
            counter <= counter + 32'd1;
        end
    end

    BUFG cpu_clk_buf(
        .I(divided_clk),
        .O(clk_out)
    );
endmodule
