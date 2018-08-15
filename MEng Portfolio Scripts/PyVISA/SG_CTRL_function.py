import time
import sys
import visa
import time
import sys
import math
import string

class SG_CTRL_function:
    def __init__(self,gpib_addr,sg=0):
        self.sg = sg
        self.rm = visa.ResourceManager()
        self.gaddr = gpib_addr
        print(self.rm.list_resources())
        self.my_instrument = self.rm.open_resource(self.gaddr)

    def connect(self):
        print("Connecting...")
        self.my_instrument.write_termination = '\n'
        self.my_instrument.clear()
        print("Hello, I am a signal generator,  " + self.my_instrument.query('*IDN?'))

    def set_sg(self,freq,pwr):
        self.my_instrument.write('FREQUENCY:FIXED %se9' % str(freq))
        self.my_instrument.write('POW:AMPL %s dBm' % str(pwr) )