`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2023 04:16:10 PM
// Design Name: 
// Module Name: SPI_Write
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


module spi_16(clk,data,send,sck,ss,mosi,busy,bram_valid,rd_enable

    );
    
    parameter data_length=24;
    input clk;
    input [data_length-1:0] data;
    input send;
    input bram_valid;
    
    
    output reg sck=0;
    output reg ss=1;
    output reg mosi;
    output reg busy=0;
    output wire rd_enable;
    
    localparam SET_FIFO=3'b000,RDY=3'b001, CLOSE_FIFO=3'b010, START=3'b011 , TRANSMIT=3'b100 , STOP=3'b101;
        
    reg [data_length-1:0] data_in;
    reg[1:0] state =SET_FIFO;
    reg[7:0] clkdiv=0;
    reg[7:0] index=0;
    reg rd_enable_reg=0;
    
    always @ (posedge clk)
    //sck is set busy
    if ( clkdiv == 8'd10)
    begin 
    clkdiv <= 0 ;
    sck <= ~sck;
    end
    else clkdiv <= clkdiv+1;
    
    always @ (posedge sck)
    
    case (state)
     
    SET_FIFO: 
           if (send)
           begin
           state <= RDY;
           rd_enable_reg <= 1;
           end
    RDY:
           if (send)
           begin
           state <= CLOSE_FIFO ;
           data_in<=data;
           busy <= 1;
           index <= data_length-1;
           end
     CLOSE_FIFO:
           begin
           rd_enable_reg <= 0;
           state <= START ;
           end
     START: 
           begin
           ss <= 0 ;
           mosi <= data_in[index];
           index <= index-1;
           state <= TRANSMIT;
           end 
     TRANSMIT:
           begin 
           rd_enable_reg <= 0;
           if(index==0)
           state <= STOP;
           mosi <= data_in[index];
           index <= index-1;
           end 
      STOP :
           begin
           busy <= 0;
           ss  <= 1;
           state <= SET_FIFO;
           end 
       endcase     
    assign rd_enable = rd_enable_reg;
   
endmodule
