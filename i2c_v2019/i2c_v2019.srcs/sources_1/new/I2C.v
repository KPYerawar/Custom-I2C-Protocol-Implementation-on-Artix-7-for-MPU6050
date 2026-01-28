`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: i2c_master1
// Description: Reads Temperature from MPU6050 (Addr 0x68, Reg 0x41) 
//              and displays the value on LEDs.
//////////////////////////////////////////////////////////////////////////////////

module  I2C (
    input  wire clk,        // 100 MHz
    input  wire rst,
    inout  wire SDA,
    output reg  SCL,
    output reg [7:0] led    // Added LED output for temperature display
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
    // Tri-state buffer for SDA
    assign SDA = (SDA_drv == 1'b0) ? 1'b0 : 1'bz;

    // -------------------------
    // Data Registers
    // -------------------------
    // MPU6050 Slave Address = 0x68
    // Write Address = 0xD0 (0x68 << 1)
    // Read Address  = 0xD1 (0x68 << 1 | 1)
    reg [7:0] slave_addr_w = 8'hD0; 
    reg [7:0] slave_addr_r = 8'hD1; 
    
    // Register Address: 0x41 (TEMP_OUT_H for MPU6050)
    reg [7:0] reg_addr     = 8'h41; 

    reg [7:0] data_read; // Stores the read temperature byte

    // -------------------------
    // FSM States
    // -------------------------
    reg [4:0] state;
    reg [2:0] bitcnt;

    localparam IDLE          = 0,
               START1        = 1,
               ADDR_W_LOW    = 2,
               ADDR_W_HIGH   = 3,
               ADDR_W_ACK    = 4,
               REG_LOW       = 5,
               REG_HIGH      = 6,
               REG_ACK       = 7,
               // Read Sequence Start
               START2        = 8,  // Repeated Start
               ADDR_R_LOW    = 9,
               ADDR_R_HIGH   = 10,
               ADDR_R_ACK    = 11,
               READ_LOW      = 12,
               READ_HIGH     = 13,
               NACK_OUT      = 14, // Master sends NACK to end read
               STOP          = 15;

    // -------------------------
    // FSM Logic
    // -------------------------
    always @(posedge i2c_clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            SCL     <= 1'b1;
            SDA_drv <= 1'b1;
            bitcnt  <= 3'd7;
            led     <= 8'h00;
        end else begin
            case (state)

            IDLE: begin
                SCL     <= 1'b1;
                SDA_drv <= 1'b1;
                bitcnt  <= 3'd7;
                state   <= START1;
            end

            // --- 1. Start Condition ---
            START1: begin
                SCL     <= 1'b1;
                SDA_drv <= 1'b0;   // SDA Low while SCL High
                state   <= ADDR_W_LOW;
            end

            // --- 2. Send Slave Address (Write) ---
            ADDR_W_LOW: begin
                SCL     <= 1'b0;
                SDA_drv <= slave_addr_w[bitcnt];
                state   <= ADDR_W_HIGH;
            end

            ADDR_W_HIGH: begin
                SCL <= 1'b1;
                if (bitcnt == 0) begin
                    SDA_drv <= 1'b1; // Release SDA for ACK
                    state   <= ADDR_W_ACK;
                end else begin
                    bitcnt <= bitcnt - 1;
                    state  <= ADDR_W_LOW;
                end
            end

            ADDR_W_ACK: begin
                SCL <= 1'b0;
                bitcnt <= 3'd7;
                // Ideally check SDA for 0 (ACK), assume ACK for now
                state <= REG_LOW;
            end

            // --- 3. Send Register Address (Temp High) ---
            REG_LOW: begin
                SCL     <= 1'b0;
                SDA_drv <= reg_addr[bitcnt];
                state   <= REG_HIGH;
            end

            REG_HIGH: begin
                SCL <= 1'b1;
                if (bitcnt == 0) begin
                    SDA_drv <= 1'b1; // Release for ACK
                    state   <= REG_ACK;
                end else begin
                    bitcnt <= bitcnt - 1;
                    state  <= REG_LOW;
                end
            end

            REG_ACK: begin
                SCL <= 1'b0;
                bitcnt <= 3'd7;
                state <= START2; // Go to Repeated Start
            end

            // --- 4. Repeated Start ---
            START2: begin
                SCL     <= 1'b1; 
                SDA_drv <= 1'b1; // Ensure SDA is High first (if it wasn't)
                // Need a small delay or state split to pull SDA Low for start
                // Simplified here: assume previous SDA release holds high
                state   <= ADDR_R_LOW;
                SDA_drv <= 1'b0; // Drive Low for Start
            end

            // --- 5. Send Slave Address (Read) ---
            ADDR_R_LOW: begin
                SCL     <= 1'b0;
                SDA_drv <= slave_addr_r[bitcnt];
                state   <= ADDR_R_HIGH;
            end

            ADDR_R_HIGH: begin
                SCL <= 1'b1;
                if (bitcnt == 0) begin
                    SDA_drv <= 1'b1; // Release for ACK
                    state   <= ADDR_R_ACK;
                end else begin
                    bitcnt <= bitcnt - 1;
                    state  <= ADDR_R_LOW;
                end
            end

            ADDR_R_ACK: begin
                SCL <= 1'b0;
                bitcnt <= 3'd7;
                state <= READ_LOW;
            end

            // --- 6. Read Byte ---
            READ_LOW: begin
                SCL     <= 1'b0;
                SDA_drv <= 1'b1; // Keep released to read
                state   <= READ_HIGH;
            end

            READ_HIGH: begin
                SCL <= 1'b1;
                data_read[bitcnt] <= SDA; // Sample data
                if (bitcnt == 0) begin
                    state <= NACK_OUT;
                end else begin
                    bitcnt <= bitcnt - 1;
                    state  <= READ_LOW;
                end
            end

            // --- 7. Master NACK (Indicate End of Read) ---
            NACK_OUT: begin
                SCL     <= 1'b0;
                SDA_drv <= 1'b1; // NACK = 1 (High)
                state   <= STOP;
                // Update LEDs with the temperature data read
                led     <= data_read; 
            end

            // --- 8. Stop Condition ---
            STOP: begin
                SCL <= 1'b0; // Prepare SCL Low
                // Step 1: SCL Low, SDA Low
                // Step 2: SCL High
                // Step 3: SDA High
                // Simplified for this FSM structure:
                if (SCL == 1'b0) begin
                   SCL <= 1'b1;
                   SDA_drv <= 1'b0;
                end else begin
                   SDA_drv <= 1'b1; // SDA High while SCL High -> Stop
                   state   <= IDLE;
                end
            end

            default: state <= IDLE;
            endcase
        end
    end

endmodule