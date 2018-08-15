import csv
import visa
import socket
import vxi11
import time
import sys
import math
import string
from SA_CTRL_function import *
from SG_CTRL_function import *

# sig gen settings
start_freq = 2.0000000  # GHz
end_freq = 3.000000     # GHz
delta_freq = 0.0005000  # GHz
pwr = 14                # dBm

# fsv settings
fspan = '0.5'           # scope peak range, MHz
avnum = '128'

# position setting
pos = 61803             # room location

# show GPIB device
print('Resources: ', visa.ResourceManager().list_resources())
sg = SG_CTRL_function('GPIB0::13::INSTR', 0)
print("Connecting to signal generator ...")
sg.connect()

# FSV network connectivity settings.... 'ipconfig /all' on remote host to show its IPV4
resourceString = 'TCPIP::10.198.138.37::INSTR'      # Auditorium B, port 159D
LAN = '10.198.138.37'

print("Connecting to FSV ...")
scope = SA_CTRL_function(LAN, resourceString)
scope.fsa_set_fspan_MHz(fspan)
scope.fsa_set_average(avnum)                        # why was this commented out? XXXXXXX

# Clear CSV File
f1 = open('fsa_markers_pos%s.csv' % pos, 'w')
f1.truncate()
f1.close()

# Measuring peaks and record to CSV
print("Starting measurements ...")

SL = int((end_freq - start_freq) / delta_freq)      # spectral lines
loops = 1                                           # loops for repeated sweep averaging
t_sleep = 2                                         # seconds
results = [0] * SL * (loops+1)                      # zeros array initialization
print("Estimated run time: ", SL * loops * t_sleep / 60, ' minutes.')

with open('fsa_markers_pos%s.csv' % pos, 'a') as f1:

    writer = csv.writer(f1, delimiter='\t', lineterminator='\n', )
    columnTitleRow = "Freq TX\tMagnitude\n"
    writer.writerow(columnTitleRow)                 # write headings for columns

    for i in range(1, loops + 1):                   # average of several sweeps
        print("Sweep number ", i)
        freq = start_freq

        for j in range(0, SL + 1):                  # perform single sweep on 80 channels

            scope.fsa_set_fc_GHz(str(freq))         # set scope centre frequency
            sg.set_sg(freq, pwr)                    # set signal generator
            time.sleep(t_sleep)                     # enough time to allow average to work better
            scope.fsa_measure_peak()                # take measurement
            time.sleep(0.01)                        # wait before looping again
            print("Freq Tx: ", freq)
            print("Freq Rx: ", scope.res_x)
            print("Measurement: ", scope.res_y)
            results[j] += float(scope.res_y)        # increment useful if loops > 1
            freq += delta_freq                      # increment freq prior to next measurement

    results = [x / loops for x in results]          # average of frequency sweep

    for i in range(0, SL + 1):                      # print results
        print(results[i])
        writer.writerow([str(start_freq + i*delta_freq), '\t', str(results[i])])

print("Finished measurements!")
