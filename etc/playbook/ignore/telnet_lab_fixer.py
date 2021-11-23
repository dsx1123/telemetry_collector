
import getpass
import sys
import telnetlib
import traceback
import time

time_out = 5
term_server = "10.62.143.238"
user = 'cisco'
password = 'cisco!123'

devices = [
    {'name': 'KLANSW-9348U-5',
     'device': '10.62.143.238',
     'ip': '10.62.149.174',
     'port': '2063'
    },
    {'name': 'KLANSW-9348U-6',
     'device': '10.62.143.238',
     'ip': '10.62.149.175',
     'port': '2058'
    },
    {'name': 'KLANSW-9606R-1',
     'device': '10.62.143.238',
     'ip': '10.62.149.173',
     'port': '2065'
    }
]


for item in devices:
    device = item['device']
    port = item['port']
    name = item['name']
    print("Telnet to host " + device + " on port " + port)
    try:
        print("Trying now...")
        tn = telnetlib.Telnet(host=device, port=port, timeout=time_out)
        tn.set_debuglevel(1)
        print("  ")
        print(" ######################################################### ")
        print(" Successful telnet to " + name + ": " + device + " " + port)
        print(" ######################################################### ")
        print("  ")
        if b'Username:' in tn.read_until(b'Username:', timeout=1):
            print("Username prompt detected")
        if b'>' in tn.read_until(b'>', timeout=1):
            print("enable prompt detected")
        if b'#' in tn.read_until(b'#', timeout=1):
            print("exec prompt detected")
        if b"" in tn.read_until(b"", timeout=1):
            if name == 'KLANSW-9348U-5' or name == 'KLANSW-9348U-6' or name == 'KLANSW-9606R-1':
                print(name + ": " + device + " " + port)
                tn.write(b"\r\n")
                time.sleep(1)
                if b'#' in tn.read_until(b'#', timeout=1):
                    print("exec prompt detected")
                    tn.write(b"configure terminal\n")
                    time.sleep(1)
                    tn.write(b"aaa new-model\n")
                    time.sleep(1)
                    tn.write(b"aaa authorization exec default local\n")
                    time.sleep(1)
                else:
                    print("> prompt detected")
                    tn.write(b"enable\r\n")
                    time.sleep(1)
                    tn.write(bytes(password, 'ascii') + b"\r\n")
                    time.sleep(1)
                    tn.write(b"configure terminal\n")
                    time.sleep(1)
                    tn.write(b"username cisco privilege 15 password 0 cisco!123\n")
                    time.sleep(1)
                    tn.write(b"username admin privilege 15 password 0 cisco!123\n")
                    time.sleep(1)
                    tn.write(b"aaa new-model\n")
                    time.sleep(1)
                    tn.write(b"aaa authorization exec default local\n")
                    time.sleep(1)
                tn.write(b"end\n")
                time.sleep(1)
                print(tn.read_all().decode('ascii'))
                tn.close()
            elif name == 'KLANSW-9606R-3':
                print(name + ": " + device + " " + port)
    except:
        print("  ")
        print(" ######################################################### ")
        print(" Processing complete for " + name + ": " + device + " " + port)
        print(" ######################################################### ")
        print("  ")
        pass

