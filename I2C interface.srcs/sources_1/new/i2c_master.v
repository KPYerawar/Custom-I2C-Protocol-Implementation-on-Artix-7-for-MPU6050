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
    
 reg i2c_fsm_clk;
 reg [9:0] counter;
 reg SDA_DRIVER;
 reg [3:0] state;
 assign SDA = (SDA_DRIVER == 1'b0) ? 1'b0 : 1'bz;

 localparam IDLE = 0 ;
  localparam START = 1 ;
 localparam  SEND_SLAVE_ADDR = 2 ;

 
 
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
        state <= START;

        end
 START : begin 
         SCL <= 1'b1;
         SDA_DRIVER <= 0;   
         state <= SEND_SLAVE_ADDR;
         end
 SEND_SLAVE_ADDR : begin 
 
       end
endcase
end
end  
endmodule
