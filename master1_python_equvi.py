import RPi.GPIO as GPIO
import time

# --- PIN CONFIGURATION ---
# Using arbitrary GPIOs as requested (not the hardware I2C pins)
SCL_PIN = 23 
SDA_PIN = 24 

# --- CONSTANTS (Matching Verilog Logic) ---
MPU_ADDR = 0x68  # 7'b1101000
TEMP_REG = 0x41  # 7'b1000001
I2C_DELAY = 0.000005  # Approx 100kHz equivalent
#some modifications may made for rwg storage also  
# --- GPIO SETUP ---
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(SCL_PIN, GPIO.OUT)

def set_sda_dir(direction):
    """Equivalent to Verilog: assign SDA = (SDA_EN) ? 1'bz : 1'b0"""
    if direction == "IN":
        GPIO.setup(SDA_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    else:
        GPIO.setup(SDA_PIN, GPIO.OUT)

def write_sda(bit):
    """Logic: 0 drives line low, 1 releases line (High-Z pulled up)"""
    if bit == 0:
        set_sda_dir("OUT")
        GPIO.output(SDA_PIN, GPIO.LOW)
    else:
        set_sda_dir("IN")

def read_sda():
    set_sda_dir("IN")
    return GPIO.input(SDA_PIN)

def scl_pulse():
    """Equivalent to CLK_HIGH and CLK_LOW states"""
    time.sleep(I2C_DELAY)
    GPIO.output(SCL_PIN, GPIO.HIGH)
    time.sleep(I2C_DELAY)
    GPIO.output(SCL_PIN, GPIO.LOW)

# --- I2C FSM LOGIC ---

try:
    # IDLE State
    GPIO.output(SCL_PIN, GPIO.HIGH)
    write_sda(1)
    time.sleep(I2C_DELAY)

    # START & START_2 States
    write_sda(0) # SDA low while SCL high
    time.sleep(I2C_DELAY)
    GPIO.output(SCL_PIN, GPIO.LOW)

    # SEND_ADDR_MPU (7 bits) + SEND_WRITE_BIT (1 bit)
    full_addr = (MPU_ADDR << 1) | 0 # Write bit = 0
    for i in range(7, -1, -1):
        bit = (full_addr >> i) & 1
        write_sda(bit)
        scl_pulse()

    # ACK_BEGIN / ACK_HIGH / ACK_LOW (Address ACK)
    write_sda(1) # Release SDA
    time.sleep(I2C_DELAY)
    GPIO.output(SCL_PIN, GPIO.HIGH)
    ack1 = read_sda()
    time.sleep(I2C_DELAY)
    GPIO.output(SCL_PIN, GPIO.LOW)
    
    if ack1 == 0:
        print("Address Acknowledged")
        
        # SEND_REG_ADDR (7 bits) + SEND_READ_BIT (Actually 8th bit of reg addr)
        # Note: Verilog code sends 7 bits of TEMP_REG then a '1' as Read Bit
        for i in range(6, -1, -1):
            bit = (TEMP_REG >> i) & 1
            write_sda(bit)
            scl_pulse()
        
        # SEND_READ_BIT state
        write_sda(1)
        scl_pulse()

        # ACK_REG_ADDR (Register ACK)
        write_sda(1)
        time.sleep(I2C_DELAY)
        GPIO.output(SCL_PIN, GPIO.HIGH)
        ack2 = read_sda()
        time.sleep(I2C_DELAY)
        GPIO.output(SCL_PIN, GPIO.LOW)

        if ack2 == 0:
            print("Register Address Acknowledged")
            
            # START_RECEIVE_DATA / READ_CLK_HIGH / READ_CLK_LOW
            rx_data = 0
            write_sda(1) # Ensure master releases SDA
            for i in range(7, -1, -1):
                time.sleep(I2C_DELAY)
                GPIO.output(SCL_PIN, GPIO.HIGH)
                bit = read_sda()
                rx_data |= (bit << i)
                time.sleep(I2C_DELAY)
                GPIO.output(SCL_PIN, GPIO.LOW)
            
            print(f"Data Received: {bin(rx_data)} (Hex: {hex(rx_data)})")

            # SEND_NACK / NACK_CLK_HIGH / NACK_CLK_LOW
            write_sda(1) # NACK = SDA High
            scl_pulse()

            # STOP_1 / STOP_2
            write_sda(0)
            time.sleep(I2C_DELAY)
            GPIO.output(SCL_PIN, GPIO.HIGH)
            time.sleep(I2C_DELAY)
            write_sda(1) # SDA goes high while SCL is high
            print("Stop Condition Sent")

        else:
            print("Error: Register NACK")
    else:
        print("Error: Device Address NACK")

except KeyboardInterrupt:
    pass
finally:
    GPIO.cleanup()
