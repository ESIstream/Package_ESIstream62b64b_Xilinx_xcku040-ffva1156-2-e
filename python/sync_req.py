#!/usr/bin/env python
import os
import sys
import time
from uart_com import uart_com

if (len(sys.argv) > 1):
     # Check 1st argument exists
     com_port = sys.argv[1]
     print (">> Start serial with", com_port)
else:
     com_port = "COM11"
     print (">> Start serial with", com_port)
     
app=uart_com()
app.start_serial(com_port)

app.sync_req()
print("-- SYNC request sent")

app.stop_serial()
