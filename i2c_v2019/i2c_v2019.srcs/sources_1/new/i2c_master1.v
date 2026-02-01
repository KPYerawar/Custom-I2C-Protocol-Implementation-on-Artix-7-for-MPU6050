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
reg [6:0]MPU_ADDR = 7'b1101000;//mpu address 
reg [6:0] TEMP_REG = 7'b1000001;//temp reg addr 
reg [3:0] bitcnt = 6;
reg [3:0] tempbitcnt = 6 ;
reg kick_start = 0 ;
reg ACK_REG;
reg [7:0] rx_data ;
reg [3:0] read_bitcnt = 7 ;
reg done ;
/////////////////////////////////////////////////////////////////
reg [7:0] state = 0 ;
reg ACK ;
////////////////////////////////////////////////////////
localparam IDLE =  1 ;
localparam START = 2;
localparam SEND_ADDR_MPU = 3;
localparam CLK_HIGH = 4 ;
localparam CLK_LOW = 5 ;
localparam SEND_WRITE_BIT = 6;
localparam WRITE_BIT_HIGH = 7 ;
localparam WRITE_BIT_LOW = 8 ;
localparam SEND_REG_ADDR = 9 ;
localparam ACK_BEGIN = 10 ;
localparam ACK_HIGH = 11 ;
localparam ACK_LOW = 12 ; 
localparam REG_CLK_HIGH = 13 ;
localparam REG_CLK_LOW = 14 ; 
localparam SEND_READ_BIT = 15 ;
localparam READ_BIT_HIGH = 16 ;
localparam READ_BIT_LOW = 17 ;
localparam RECEIVE_DATA = 18 ;
localparam ACK_REG_ADDR = 19 ;
localparam error_occured_addr = 20 ;
localparam ACK_REG_ADDR_HIGH  = 21 ;
localparam ACK_REG_ADDR_LOW = 22 ;
localparam START_RECEIVE_DATA = 23 ;
localparam ADDR_INCORRECTLY_READ = 24 ;
////////////reading start////////
localparam READ_CLK_HIGH = 25 ;
localparam READ_CLK_LOW = 26 ;
localparam SEND_NACK = 27 ;
localparam NACK_CLK_HIGH = 28 ;
localparam NACK_CLK_LOW = 29 ;
localparam STOP_1 = 30 ;
localparam STOP_2 = 31 ;
localparam START_2 = 32;
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
                  if (done == 1 )
                  state <= IDLE ;
                  else
                  state <= START;                  
                  end
            
                   START: begin
        SCL    <= 1;
        SDA_EN <= 1;       // SDA high
        state  <= START_2;
    end
    
    START_2: begin
        SCL    <= 1;
        SDA_EN <= 0;       // SDA low while SCL high = START
        state  <= SEND_ADDR_MPU;
    end
                    SEND_ADDR_MPU: begin 
                SCL <= 0 ;
                SDA_EN <= MPU_ADDR[bitcnt];                 
                state <= CLK_HIGH; 
                end 
                
                CLK_HIGH: begin 
                SCL <= 1 ;
                 state <= CLK_LOW ;
                 end  
                 
                 CLK_LOW: begin 
                 SCL<= 0 ;
                 if ( bitcnt == 0 )begin 
                 bitcnt<= 6;
                 state <= SEND_WRITE_BIT ;end
                    else begin 
                 bitcnt <= bitcnt -1 ;
                 state <= SEND_ADDR_MPU;end
               
                       end 
                       
                       
                  SEND_WRITE_BIT: begin 
                  SCL<= 0 ;
                  SDA_EN <= 1'b0 ;
                  state <= WRITE_BIT_HIGH;
                  end 
                  
                  WRITE_BIT_HIGH : begin 
                  SCL <= 1 ;
                  state <= WRITE_BIT_LOW;
                  end
                  
                  WRITE_BIT_LOW : begin 
                  SCL <= 0 ;
                  state <= ACK_BEGIN ;
                  end 
                  
                  
                  ACK_BEGIN : begin 
                  SCL<= 0 ;
                  SDA_EN <= 1'b1 ;/// aSDA relesed 
                  state<= ACK_HIGH;
                  end 
                  
                  ACK_HIGH : begin 
                  SCL <= 1 ;
                  ACK <= SDA ; // ack == 0 : 1 = nack 
                  state <= ACK_LOW ;
                  end 
                  
                  ACK_LOW : begin 
                  SCL<= 0 ;
                  if (ACK == 0 )//everything is fine 
                  state <= SEND_REG_ADDR ;
                  else 
                  state <= error_occured_addr ;
                  end 
                  
                  
                /////////////// send now the reg addr 
                  SEND_REG_ADDR : begin 
                  SCL <=  0 ;
                  SDA_EN <= TEMP_REG[tempbitcnt];
                  state <= REG_CLK_HIGH;
                  end 
                  
                  REG_CLK_HIGH : begin 
                  SCL <= 1 ; 
                  state <= REG_CLK_LOW ;
                  end 
                  
                  REG_CLK_LOW : begin 
                   SCL <= 0 ;
                   if ( tempbitcnt == 0)begin 
                   tempbitcnt<= 6 ;
                   state <= SEND_READ_BIT;
                   end 
                   else begin 
                   tempbitcnt <= tempbitcnt -1;
                   state<= SEND_REG_ADDR; end 
                  end 
                  
                  
                  SEND_READ_BIT : begin 
                  SCL <= 0 ;
                  SDA_EN <= 1'b1 ;//read bit pushed 
                  state <= READ_BIT_HIGH ;
                  end 
                  READ_BIT_HIGH : begin 
                  SCL<= 1 ;
                  state <= READ_BIT_LOW ;
                  end 
                  
                  READ_BIT_LOW : begin 
                  SCL<= 0 ;
                  state  <= ACK_REG_ADDR;
                  end 
                    /////////////////////ack of adder send is remain then loop is remaining ..... to readthat temp again and again and
                    //////////an now sda is relesed by master so er have to consider the slave is drivig sda and to read thos valsiue scl == 1 ;
                    /////////////
                    
                    
                  ACK_REG_ADDR : begin 
                  SCL <= 0 ;
                  SDA_EN <= 1'b1 ; // sda relesed  
                  state <= ACK_REG_ADDR_HIGH; 
                  end 
                  
                  ACK_REG_ADDR_HIGH: begin 
                  SCL <= 1 ;
                  ACK_REG <= SDA ;// ID ACK_REG == 0 THEN EVERYTHING IS FINE 
                  state <= ACK_REG_ADDR_LOW ;
                  end 
                  
                  ACK_REG_ADDR_LOW: begin 
                  SCL <= 0 ;
                  if ( ACK_REG == 0 )
                  state <= START_RECEIVE_DATA;
                  else 
                  state <= ADDR_INCORRECTLY_READ;
                  end 
                  ///////////////////////////////////////////////////////////////////////
                  //////START READING DATA /////////////////////////////////////////////
                  ////////////////////////////////////////////////////////////////////
                  
                  START_RECEIVE_DATA : begin 
                  SCL <= 0 ;
                  SDA_EN <= 0; // release SDA

                  state <= READ_CLK_HIGH;                  
                  end 
                  
                  READ_CLK_HIGH: begin 
                  SCL<= 1 ;
                  rx_data[read_bitcnt] <= SDA;
                  state <=  READ_CLK_LOW;
                  end 
                  
                  READ_CLK_LOW: begin 
                  SCL<= 0 ;
                  if (read_bitcnt == 0 )begin 
                  read_bitcnt <= 7;
                  state <= SEND_NACK; end
                  else begin
                  read_bitcnt <= read_bitcnt -1 ;
                  state <= START_RECEIVE_DATA;end end 
                  
                  
                  SEND_NACK : begin
    SCL    <= 1'b0;     // keep clock low
    SDA_EN <= 1'b1;     // master drives SDA
    state  <= NACK_CLK_HIGH;
end

NACK_CLK_HIGH : begin
    SCL   <= 1'b1;      // clock high → NACK sampled
    state <= NACK_CLK_LOW;
end

NACK_CLK_LOW : begin
    SCL   <= 1'b0;
    state <= STOP_1;
end

        STOP_1 : begin
    SDA_EN <= 1'b0;     // master drives SDA
    SCL    <= 1'b1;     // SCL high
    state  <= STOP_2;
end

STOP_2 : begin
SDA_EN <= 1;
SCL<= 1 ;
done <= 1 ;
    state  <= IDLE;     // bus released
end
            
endcase 
end 

end
assign SDA = (SDA_EN) ? 1'bz : 1'b0;
endmodule
