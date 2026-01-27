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

 reg i2c_fsm_clk;
 reg [6:0] sensor_addr = 7'b1101000;// addr 
 reg [6:0] temp_reg_addr = 7'h1000001;// 01000001 adddr
 reg [8:0] counter;
 reg SDA_DRIVER;
 reg [3:0] state;
 assign SDA = (SDA_DRIVER == 1'b0) ? 1'b0 : 1'bz;

 localparam IDLE = 0 ;
  localparam START = 1 ;
 localparam  SEND_SLAVE_ADDR = 2 ;
 localparam send_reg_addr = 3;
 localparam receive_sensor_data = 4 ; 

 
 
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
       SCL <= 0 ;
       for (  i = 7 ; i >= 0 ; i = i -1 ) begin 
        SDA_DRIVER <= sensor_addr[i];
          end 
          SDA_DRIVER <= 0 ; // write bit sent 
          state <= send_reg_addr;
          
       end
     send_reg_addr: begin
     SCL <=  1 ;
     
      for (  i = 7 ; i >= 0 ; i = i -1 ) begin 
        SDA_DRIVER <= temp_reg_addr[i];
          end 
          SDA_DRIVER <= 1 ; //read bit
          state<= receive_sensor_data;
      end 
     
    
endcase
end
end  
endmodule
