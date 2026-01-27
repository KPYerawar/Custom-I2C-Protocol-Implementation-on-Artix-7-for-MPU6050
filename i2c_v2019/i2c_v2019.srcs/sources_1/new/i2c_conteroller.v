`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/18/2026 02:45:32 PM
// Design Name: 
// Module Name: i2c_conteroller
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


module i2c_conteroller(
input clk , 
input rst ,
output i2c_scl ,
inout i2c_sda,

input start ,
output [7:0]data_out,
output ready 

    );
    reg sda_out ;
    reg sda_en ;
    reg [9:0] counter ;
    reg i2c_clk ;
    reg [2:0]state;
    reg [7:0] bit_cnt ;
    reg [7:0] saved_addr;
    
    localparam IDLE = 0 ;
    localparam START = 1 ;
    localparam COMMAND = 2  ;
    localparam ACK = 3 ;
    localparam STOP = 4 ;
    
    
  always @(posedge clk or posedge rst) begin 
  if (rst) begin 
  counter <=  0 ;
  i2c_clk <= 0 ;
  end 
  else begin 
         if ( counter == 499 ) begin 
           counter <= 0 ;
           i2c_clk <= ~i2c_clk ;
           end 
           else begin 
           counter <= counter+ 1 ;
           end 
           end 
           end 
           
    always @(posedge i2c_clk or posedge rst) begin 
    if (rst ) begin 
    state <= 0 ;
    bit_cnt <= 0 ;
        end 
     else begin 
     case (state) 
      IDLE: begin 
      sda_en <= 0 ;
      sda_out <= 1 ;
      if (start == 1 ) begin 
      state <= START ;
      saved_addr <= {7'h68 , 1'b0};
      bit_cnt <= 7 ;
       end 
       end
       START : begin 
       sda_out <= 0 ;
       sda_en <= 1 ;
       state <= COMMAND;
       end 
       COMMAND : begin 
       sda_out <= saved_addr [bit_cnt];
       sda_en <= 1 ;
       if (bit_cnt == 0 ) 
       state <= ACK ;
       else 
       bit_cnt <= bit_cnt - 1 ;
       end 
       ACK: begin 
       sda_en <= 0 ;
       state <= STOP;
       
       end
       STOP: begin 
       sda_out <= 0 ;
       sda_en <= 1 ;
       state <= IDLE ;
       end 
       endcase
       end 
       end 
       assign i2c_sda = ( sda_en == 1 ) ? sda_out : 1'bz;
       assign i2c_scl = ~i2c_clk;
       assign ready = (state == IDLE);
       assign data_out = 8'b0; 
       
    
endmodule
