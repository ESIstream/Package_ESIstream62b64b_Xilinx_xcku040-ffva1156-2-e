import os
import sys
import time
import serial
import logging

## CONSTANTS:
REG_NUMBER = 20 # Satus register can't be written (read only).
REG_ADDRESS_LENGTH = 2
REG_DATA_LENGTH = 4
REG_HDL_VERSION_ADDRESS = 8
REG_SPI_FIFO_FLAGS_ADDRESS = 9
REG_SPI_RD_FIFO_ADDRESS = 10
REG_STATUS_ADDRESS = 255
REG_READ_MODE_ENABLE = 2**15 # Address field MSB high (bit 15).

## CLASS:
class uart_com:
    def __init__(self):
        self.list = []    # creates a new empty list for each instance
        """
        Serial port object 
        """
        self.ser=""
        """
        FPGA registers base image 
        """
        self.reg_array = [0] * REG_NUMBER

    ##################################################################################################################################### 
    ## Serial port functions
    #####################################################################################################################################      
    def start_serial(self, com_port):
        """
        Open serial port (UART):
        The FPGA design embeds a UART slave which uses the following configuration:
        -	Baud rate: 115200 
        -	Data Bits: 8
        -	No parity
        """
        self.ser=serial.Serial(str(com_port), 115200, timeout=1)
        print("\r\n")
        print("--------------------------------------------------------")
        print("-- Serial communication opened... %s" %(self.ser.isOpen()))
        
    def stop_serial(self):
        """
        Close serial port (UART).
        """
        self.ser.close()
        print("-- Serial communication closed... %s" %(not self.ser.isOpen()))
        print("--------------------------------------------------------")
        print("\r\n")
     
    def write_register(self, address, data):
        """
        Parameters:
        * address : 15-bit : Positive integer.  
        * data :    32-bit : Positive integer. 
        The UART frames layer protocol defined here allows to perform read and write operations on the registers listed in the register map.
        write_registers takes FPGA register address and data to create the UART frames layer protocol write operation command:
        -	The most significant bit of the first transmitted byte (bit 7) must be set to 0 for write operation. 
        -	The bits 6 down to 0 of the first transmitted byte contain the bit 14 down to 8 of the register address.
        -	The second byte contains the bit 7 down to 0 of the register address. 
        -	The third byte contains the bit 31 down to 24 of the register data.
        -	The fourth byte contains the bit 23 down to 16 of the register data.
        -	The fifth byte contains the bit 15 down to 8 of the register data. 
        -	The sixth byte contains the bit 7 down to 0 of the register data.
        --
        -       Master write ----< Byte 1: 0 & Addr high >< Byte 2: Addr low >< Data byte 3 >< Data byte 2 >< Data byte 1 >< Data byte 0 >-------------------------------
        -       Master read  --------------------------------------------------------------------------------------------------------------------< ACK byte: 0xAC >-----
        """
        rcv=self.ser.read(self.ser.inWaiting()) 
        command = int(address).to_bytes(REG_ADDRESS_LENGTH, byteorder='big')
        command = command + int(data).to_bytes(REG_DATA_LENGTH,byteorder='big')
        self.ser.write(command)
        ack = self.wait_response() # Wait for slave acknowledgment ACK value = 0xAC (16) = 172 (10)
        return (int.from_bytes(ack, byteorder='big'))
    
    def read_register(self, address):
        """
        Parameters:
        * address : 15-bit : Positive integer.  
        The UART frames layer protocol defined here allows to perform read and write operations on the registers listed in the register map.
        read_registers takes FPGA register address to create the UART frames layer protocol read operation command:
        -	The most significant bit of the first transmitted byte (bit 7) must be set to 1 for read operation. 
        -	The bits 6 down to 0 of the first transmitted byte contain the bit 14 down to 8 of the register address.
        -	The second byte contains the bit 7 down to 0 of the register address. 
        Then, the master read the data and the acknowledgment word to check that the communication has been done correctly. The acknowledgment word is a single byte of value 0xAC (172 is the decimal value). 
        -	The third byte contains the bit 31 down to 24 of the register data.
        -	The fourth byte contains the bit 23 down to 16 of the register data.
        -	The fifth byte contains the bit 15 down to 8 of the register data. 
        -	The sixth byte contains the bit 7 down to 0 of the register data.
        --
        -       Master write ----< Byte 1: 1 & Addr high >---------------------------------------------------------------------------------------------------------
        -       Master read  -------------------------------< Byte 2: Addr low >< Data byte 3 >< Data byte 2 >< Data byte 1 >< Data byte 0 >< ACK byte: 0xAC >-----
        """
        command = (int(address)+REG_READ_MODE_ENABLE).to_bytes(REG_ADDRESS_LENGTH, byteorder='big')
        self.ser.write(command)
        data = self.ser.read(size=REG_DATA_LENGTH)
        ack = self.wait_response() # Wait for slave acknowledgment ACK value = 0xAC = 172
        return (int.from_bytes(data, byteorder='big'))

    def wait_response(self, wtext=b'\xAC', timeSleep=0.05, timeOut=1, timeDisplayEnable=False):
        """
        After sending a UART frames layer protocol write or read operation command allows waiting for the acknowledgment word: 
        - Hexadecimal: 0xAC 
        - Decimal: 172
        """
        ack=""
        waitResponse=True
        timeCntr=0
        while(waitResponse):
            time.sleep(timeSleep)
            timeCntr = timeCntr+timeSleep
            ack=self.ser.read(self.ser.inWaiting()) 
            if (wtext in ack):
                waitResponse=False
            elif (timeCntr == timeOut):
                ack='-- Error: wait_response "%s" timeout %ds'%(wtext, timeOut)
                waitResponse=False
            else:
                waitResponse=True
                if timeDisplayEnable:
                    logging.debug("...%ds"%(timeCntr))
        return ack

    def set_vector(self, reg_addr, reg_data, start_bit):
        vector_slip = (reg_data << start_bit)
        self.reg_array[reg_addr] = vector_slip
        self.write_register(reg_addr, self.reg_array[reg_addr])
        time.sleep(0.001)
        
    def set_bit(self, reg_addr, reg_data_bit):
        """
        Parameters:
        * reg_addr     : 15-bit        : Positive integer, FPGA register address.   
        * reg_data_bit : range 0 to 31 : Positive integer, FPGA data register bit position.
        set_bit allows setting the register bit to 1. 
        For instance: 
        -        Register 2 value is 0x00000000
        Using set_bit(2, 2)
        -        Register 2 value becomes 0x00000004
        Also set FPGA registers base image (reg_array)
        """
        bit_slip = (0x1 << reg_data_bit)
        self.reg_array[reg_addr] = self.reg_array[reg_addr] | (bit_slip)
        self.write_register(reg_addr, self.reg_array[reg_addr])
        time.sleep(0.001)

    def unset_bit(self, reg_addr, reg_data_bit):
        """
        Parameters:
        * reg_addr     : 15-bit        : Positive integer, FPGA register address.   
        * reg_data_bit : range 0 to 31 : Positive integer, FPGA data register bit position.
        unset_bit allows setting the register bit to 0. 
        For instance: 
        -        Register 2 value is 0xFFFFFFFF
        Using set_bit(2, 2):
        -        Register 2 value becomes 0xFFFFFFFB
        Also set FPGA registers base image (reg_array)
        """
        bit_slip = (0x1 << reg_data_bit)
        self.reg_array[reg_addr] = self.reg_array[reg_addr] & (~bit_slip) 
        self.write_register(reg_addr, self.reg_array[reg_addr])
        time.sleep(0.001)

    #####################################################################################################################################   
    ## FPGA REGISTERS
    #####################################################################################################################################      
    ## REG 0
    def sync_req(self):
        reg_addr = 0
        reg_data_bit = 0
        self.set_bit(reg_addr, reg_data_bit)
        time.sleep(0.1)
        self.unset_bit(reg_addr, reg_data_bit)
        
    ## REG 5
    def ila_trigger(self):
        reg_addr = 5
        reg_data_bit = 0
        self.set_bit(reg_addr, reg_data_bit)
        
    ## REG 8
    def get_config(self):
        """
        Reserved for debug 
        """
        rcv = self.read_register(8)
        return rcv
    
    ## REG 255
    def get_status(self):
        """
        Reserved for debug 
        """
        rcv = self.read_register(REG_STATUS_ADDRESS)
        return rcv
