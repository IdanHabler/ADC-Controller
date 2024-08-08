`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2024 12:35:02 PM
// Design Name: 
// Module Name: control
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


module control (
    input CS,
    input SCLK,
    input [4:0] length,
    output reg enable );

    localparam IDLE = 2'b00, COMM = 2'b01, BLOCK = 2'b10;

    reg state = IDLE;
    integer count = 0;

    always @(negedge CS) begin
        if (state == IDLE)
            state <= COMM;
    end
    always @(posedge SCLK) begin
        if (state == COMM) begin
            if (count == length - 1) begin
                state <= BLOCK;
                enable <= 0;
            end
        end else
            count <= count + 1;
    end
    always @(posedge CS) begin
        state <= IDLE;
        count <= 0;
        enable <= 1;
    end
endmodule