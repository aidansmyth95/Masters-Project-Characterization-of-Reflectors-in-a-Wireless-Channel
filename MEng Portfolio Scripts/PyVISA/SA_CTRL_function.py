import csv
import visa
import socket,  vxi11
import time


class SA_CTRL_function:

    def __init__(self,LAN,resourceString):
        self.LAN = LAN
        self.resourceString = resourceString
        self.scope = visa.ResourceManager().open_resource(self.resourceString) # Standard LAN connection (also called VXI-11)
        self.instr = vxi11.Instrument(LAN)
        self.res_x = 0
        self.res_y = 0

    def fsa_connect(self):
        self.scope.write_termination = '\n'
        self.scope.clear()  # Clear instrument io buffers and status
        #idn_response = scope.query('*IDN?')  # Query the Identification string
        print("Hello, I am FSV, ", self.instr.ask("*IDN?"))

    def fsa_set_fc_GHz(self,fc):
        cmd = 'freq:center %se9;*opc?' % str(fc)
        self.instr.write('%s\n' % cmd)

    def fsa_set_fspan_MHz(self,fspan):
        cmd = 'freq:span %se6;*opc?' % str(fspan)
        self.instr.write('%s\n' % cmd)

    def fsa_measure_peak(self):
        cmd = ':INIT:IMM;*OPC?'
        self.instr.write('%s\n' % cmd)
        cmd = ':calc:mark1:max:peak;*OPC?'
        self.instr.write('%s\n' % cmd)
        cmd = ':calc:mark1:y?'
        self.res_y = self.instr.ask('%s\n' % cmd, 5)
        cmd = ':calc:mark1:x?'
        self.res_x = self.instr.ask('%s\n' % cmd, 5)

    ######################################

    def fsa_set_average(self,avnum):
        mode = 'average'
        type = 'power'
        cmd = 'display:trace1:mode %s;*opc?' % str(mode)
        self.instr.write('%s\n' % cmd)
        cmd = 'aver:type %s;*opc?' % type
        self.instr.write('%s\n' % str(cmd))
        cmd = 'sweep:count %s;*opc?' % avnum
        self.instr.write('%s\n' % str(cmd))
      #  cmd = 'calc:marker1 on;*opc?'
      #  self.instr.write('%s\n' % str(cmd))
    ######################################
