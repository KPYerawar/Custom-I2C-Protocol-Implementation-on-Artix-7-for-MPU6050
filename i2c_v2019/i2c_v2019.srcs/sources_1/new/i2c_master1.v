`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.01.2026 08:00:43
// Design Name: 
// Module Name: i2c_master1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Rsevision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module i2c_master1(
input clk ,// 100MHz
input rst,
inout SDA ,
output reg SCL 
);

reg FSM_CLK ;///fsm clk which will  work ok 100khz
reg [8:0] counter = 0 ;//this will count till 499 and return to 0 to from a 50%duty cycle for fsm_clk 
reg SDA_EN;
reg MPU_ADDR = 'h68;//mpu address 
reg [3:0] bitcnt = 7 ;
reg kick_start = 0 ;
/////////////////////////////////////////////////////////////////
reg [3:0] state = 0 ;
////////////////////////////////////////////////////////
localparam IDLE =  1 ;
localparam START = 2;
localparam SEND_ADDR_MPU = 3;
//////////////////////////////////////////////////////////////////////////////////////////
/*  CLOCK FOR FSM IN I2C */
///////////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin 
if ( rst ) begin 
FSM_CLK <= 0 ;
counter <= 0 ;
end
else begin 
          if ( counter == 499) begin 
            counter <= 9'b0 ;
            FSM_CLK <= ~ FSM_CLK;//toggle at 50 % duty cycle
            end 
           else counter <= counter + 1 ;
           
      end 
 end 

///////////////////////////////////////////////////////////////////////////////
/*ACTUAL FSM */
/////////////////////////////////////////////////////////////////////////////

always @(posedge FSM_CLK or posedge rst) begin 
if (rst ) begin 
state <= IDLE ; end 

else begin 
               case(state) 
               IDLE: begin 
                  SCL <=  1 ;
                  SDA_EN <= 1 ;
                  state <= START;                  
                  end
            
                START: begin
                
                if ( kick_start == 1 )begin 
                SCL<= 0;
                SDA_EN <= 1;
                state <= SEND_ADDR_MPU ;
                kick_start<= 0 ; end 
                else begin 
                       SDA_EN <= 0 ;
                       SCL <= 1 ;
                       state <= START;
                       kick_start<= 1 ;
                       end 
                    
                end 
                SEND_ADDR_MPU: begin 
                SCL<= 1 ;
                end 
                       
                  
                  
                    
endcase 
end 

end
assign SDA = SDA_EN;
endmodule
