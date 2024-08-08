`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2024 10:11:10 AM
// Design Name: 
// Module Name: DEMUX
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


module DEMUX(in0, s, out0, out1);
    input wire in0;
    input wire s;
    output wire out0;
    output wire out1;
    assign {out0,out1} = s ? {1'b0,in0} : {in0,1'b0};
endmodule
