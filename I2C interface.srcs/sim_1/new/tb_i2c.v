`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/18/2026 03:53:44 PM
// Design Name: 
// Module Name: tb_i2c
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


module tb_i2c;

    // 1. Inputs (Regs because we drive them)
    reg clk;
    reg rst;
    reg start;

    // 2. Outputs (Wires because we just watch them)
    wire i2c_scl;
    wire i2c_sda;
    wire [7:0] data_out;
    wire ready;

    // 3. Instantiate the Unit Under Test (UUT)
    i2c_conteroller uut (
        .clk(clk), 
        .rst(rst), 
        .i2c_scl(i2c_scl), 
        .i2c_sda(i2c_sda), 
        .start(start), 
        .data_out(data_out), 
        .ready(ready)
    );

    // 4. Mimic the Physical Pull-Up Resistor
    // This makes "z" look like "1" (High) in simulation
    pullup(i2c_sda);

    // 5. Clock Generation (100MHz = 10ns period)
    always #5 clk = ~clk; 

    // 6. Test Stimulus
    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        start = 0;

        // Hold Reset for 100ns
        #100;
        rst = 0;

        // Wait a bit, then press "Start"
        #200;
        start = 1;
        #20;         // Hold button for 20ns
        start = 0;   // Release button

        // Wait long enough to see the whole I2C packet
        // Your divider is 500, so it takes time!
        #100000; 

        $finish;
    end
      
endmodule
