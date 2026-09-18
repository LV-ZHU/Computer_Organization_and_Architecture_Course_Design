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
    imem_rom imem_rom_inst(
        .a(im_addr_in),
        .spo(im_instr_out)
    );
endmodule
