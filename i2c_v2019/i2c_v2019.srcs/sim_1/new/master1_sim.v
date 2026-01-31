`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.01.2026 16:19:57
// Design Name: 
// Module Name: master1_sim
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


module master1_sim;
reg clk ;
reg rst ;
wire SCL;
wire SDA;









i2c_master1 M1(
.clk(clk),.rst(rst),.SCL(SCL),.SDA(SDA));

always  #10 clk = ~clk ;

initial begin 
clk = 0 ;
rst = 1 ;
#50;
rst = 0 ;
#500;
$finish;
end 

initial begin 
$monitor( "time  = %t", $time);
end 
endmodule
