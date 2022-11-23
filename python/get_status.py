#!/usr/bin/env python
import os
import sys
import time
from uart_com import uart_com

if len(sys.argv) > 1:
     # Check 1st argument exists 
     com_port = sys.argv[1]
     print (">> Start serial with", com_port)
else:
     com_port = "COM11"
     print (">> Start serial with", com_port)

app=uart_com()
app.start_serial(com_port)

ret=app.get_status()
print("-- Status: "+str(hex(ret)))

ret=app.get_config()
print("-- Status: "+str(hex(ret)))

app.stop_serial()

