`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2026 06:32:44 PM
// Design Name: 
// Module Name: i2c_master
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


module i2c_master(
input clk ,
inout  SDA,
input rst ,
output  reg SCL,
output reg_data
    );
    reg  i ;
reg [3:0]bitcnt;// made this 4 bit  so it could count from 8 ;
 reg i2c_fsm_clk;
 reg [7:0] sensor_addr = 8'b11010000;// addr including write  
 reg [7:0] temp_reg_addr = 8'b01000001;// 01000001 adddr
 reg [8:0] counter;
 reg SDA_DRIVER;
 reg [3:0] state;
 assign SDA = (SDA_DRIVER == 1'b0) ? 1'b0 : 1'bz;

 localparam IDLE = 0 ;
  localparam START = 1 ;
 localparam  SEND_SLAVE_ADDR = 2 ;
 localparam sensor_addr_ack = 3;

 
 
 always @(posedge clk or posedge rst) begin 
 if(rst)begin 
 counter <= 0 ;
 i2c_fsm_clk <= 0 ; end 
  else if (counter ==  499 )
  begin 
  i2c_fsm_clk <= ~i2c_fsm_clk;
  counter <= 10'b0;
  end
  
  else
  counter <= counter +1 ;
  end  

always @(posedge i2c_fsm_clk or posedge rst ) begin 
if (rst) begin 
state <= IDLE ;
end 

else begin 

case (state) 

IDLE : begin 
        SDA_DRIVER <= 1'b1;
        SCL <= 1'b1;
        bitcnt<= 7;
        state <= START;

        end
 START : begin 
         SCL <= 1'b1;
         SDA_DRIVER <= 0;   
         state <= SEND_SLAVE_ADDR;
         end
 SEND_SLAVE_ADDR : begin 
            SCL <= 1'b0 ;
         SDA_DRIVER <= sensor_addr[bitcnt];
        if (bitcnt == 0 ) begin 
        bitcnt <= 7 ;
         state <= sensor_addr_ack; end 
         else begin 
         bitcnt = bitcnt - 1 ;
         state <= SEND_SLAVE_ADDR; end 
         end 
         
  sensor_addr_ack:  begin 
  
           SCL <= 1'b1;
           end
endcase
end
end  
endmodule
