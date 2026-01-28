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
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module i2c_master1 (
    input  wire clk,        // 100 MHz
    input  wire rst,
    inout  wire SDA,
    output reg  SCL
);

    // -------------------------
    // Clock divider for I2C
    // -------------------------
    reg [8:0] clk_cnt;
    reg i2c_clk;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 0;
            i2c_clk <= 0;
        end else if (clk_cnt == 499) begin
            clk_cnt <= 0;
            i2c_clk <= ~i2c_clk;   // ~100 kHz
        end else
            clk_cnt <= clk_cnt + 1;
    end

    // -------------------------
    // I2C signals
    // -------------------------
    reg SDA_drv;   // 0 = drive low, 1 = release
    assign SDA = (SDA_drv == 1'b0) ? 1'b0 : 1'bz;

    // -------------------------
    // FSM
    // -------------------------
    reg [3:0] state;
    reg [2:0] bitcnt;

    localparam IDLE          = 0,
               START         = 1,
               ADDR_LOW      = 2,
               ADDR_HIGH     = 3,
               ADDR_ACK      = 4,
               REG_LOW       = 5,
               REG_HIGH      = 6,
               REG_ACK       = 7,
               STOP          = 8;

    // -------------------------
    // Data
    // -------------------------
    reg [7:0] slave_addr = 8'b11010000; // 0x68 + Write
    reg [7:0] reg_addr   = 8'b01000001; // example register

    // -------------------------
    // FSM logic
    // -------------------------
    always @(posedge i2c_clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            SCL     <= 1'b1;
            SDA_drv <= 1'b1;
            bitcnt  <= 3'd7;
        end else begin
            case (state)

            IDLE: begin
                SCL     <= 1'b1;
                SDA_drv <= 1'b1;
                bitcnt  <= 3'd7;
                state   <= START;
            end

            START: begin
                SCL     <= 1'b1;
                SDA_drv <= 1'b0;   // SDA goes low while SCL high
                state   <= ADDR_LOW;
            end

            // -------- Send Slave Address --------
            ADDR_LOW: begin
                SCL     <= 1'b0;
                SDA_drv <= slave_addr[bitcnt];
                state   <= ADDR_HIGH;
            end

            ADDR_HIGH: begin
                SCL <= 1'b1;
                if (bitcnt == 0) begin
                    SDA_drv <= 1'b1;  // release for ACK
                    state   <= ADDR_ACK;
                end else begin
                    bitcnt <= bitcnt - 1;
                    state  <= ADDR_LOW;
                end
            end

            ADDR_ACK: begin
                SCL <= 1'b0;
                bitcnt <= 3'd7;
                state <= REG_LOW;
            end

            // -------- Send Register Address --------
            REG_LOW: begin
                SCL     <= 1'b0;
                SDA_drv <= reg_addr[bitcnt];
                state   <= REG_HIGH;
            end

            REG_HIGH: begin
                SCL <= 1'b1;
                if (bitcnt == 0) begin
                    SDA_drv <= 1'b1;
                    state   <= REG_ACK;
                end else begin
                    bitcnt <= bitcnt - 1;
                    state  <= REG_LOW;
                end
            end

            REG_ACK: begin
                SCL <= 1'b0;
                state <= STOP;
            end

            STOP: begin
                SCL     <= 1'b1;
                SDA_drv <= 1'b1;   // SDA goes high while SCL high
                state   <= IDLE;
            end

            default: state <= IDLE;
            endcase
        end
    end

endmodule

