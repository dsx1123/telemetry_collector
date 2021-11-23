
import getpass
import sys
import telnetlib
import traceback
import time

time_out = 5
term_server = "10.62.143.238"
user = 'cisco'
password = 'cisco!123'

systems = [
    {'name': 'KLANSW-9348U-5',
     'term_server_ip': '10.62.143.238',
     'telnet_port': '2063',
     'mgmt_ip': '10.62.149.174',
     'mgmt_mask': '255.255.255.0',
     'mgmt_dgw': '10.62.149.1', 
     'mgmt_intf_name': "mgmt0",
     'username': 'cisco',
     'password': 'cisco!123',
     #'problems': '[aaa_authorization, no_mgmt_ip, no_vrf, no_ssh_keys]'
     'problems': '[aaa_authorization]'
    },
    {'name': 'KLANSW-9348U-6',
     'term_server_ip': '10.62.143.238',
     'telnet_port': '2058',
     'mgmt_ip': '10.62.149.175',
     'mgmt_mask': '255.255.255.0',
     'mgmt_dgw': '10.62.149.1', 
     'mgmt_intf_name': "mgmt0",
     'username': 'cisco',
     'password': 'cisco!123',
     #'problems': '[aaa_authorization, no_mgmt_ip, no_vrf, no_ssh_keys]'
     'problems': '[aaa_authorization]'
    },
    {'name': 'KLANSW-9606R-1',
     'term_server_ip': '10.62.143.238',
     'telnet_port': '2065',
     'mgmt_ip': '10.62.149.173',
     'mgmt_mask': '255.255.255.0',
     'mgmt_dgw': '10.62.149.1', 
     'mgmt_intf_name': "mgmt0",
     'username': 'cisco',
     'password': 'cisco!123',
     #'problems': '[aaa_authorization, no_mgmt_ip, no_vrf, no_ssh_keys]'
     'problems': '[aaa_authorization]'
    }
]

for item in systems:
    term_server_ip = item['term_server_ip']
    port = item['telnet_port']
    name = item['name']
    print("Telnet to host " + term_server_ip + " on port " + port)
    try:
      print("Trying now...")
      tn = telnetlib.Telnet(host=term_server_ip, port=port, timeout=time_out)
      tn.set_debuglevel(1)
      print("  ")
      print(" ######################################################### ")
      print(" Successful telnet to " + name + ": " + term_server_ip + " " + port)
      print(" ######################################################### ")
      print("  ")
      if b'Username:' in tn.read_until(b'Username:', timeout=1):
          print("Username prompt detected")
      if b'>' in tn.read_until(b'>', timeout=1):
          print("enable prompt detected")
      if b'#' in tn.read_until(b'#', timeout=1):
          print("exec prompt detected")
      if b"" in tn.read_until(b"", timeout=1):
        print(name + ": " + term_server_ip + " " + port)
        if len(item['problems']) > 0
          tn.write(b"\r\n")
          time.sleep(1)
          if b'#' in tn.read_until(b'#', timeout=1):
            print("exec prompt detected")
            tn.write(b"configure terminal\n")
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
          for problem in item['problems']:
            if problem == "aaa_authentication":
                  tn.write(b"aaa new-model\n")
                  time.sleep(1)
                  tn.write(b"aaa authorization exec default local\n")
                  time.sleep(1)
            elif problem == "no_mgmt_ip":
              tn.write(b"interface " + item['mgmt_intf_name'] + "\r\n")
              time.sleep(1)
              tn.write(b"vrf member management\r\n")
              time.sleep(1)
              tn.write(b"ip address 10.66.94.216/28\r\n")
              time.sleep(1)
              tn.write(b"vrf context management\r\n")
              time.sleep(1)
              tn.write(b"ip route 0.0.0.0/0 10.66.94.209\r\n")
              time.sleep(1)
            elif problem == "no_vrf":
              print('No VRF')
            elif problem == "no_ssh_keys":
              print('No ssh keys')
            else:
              print('Error:  Undefined Problem')
          print(tn.read_all().decode('ascii'))
          tn.close()
        else:
          print("problem list for " + name + "is empty")
    except:
        print("  ")
        print(" ######################################################### ")
        print(" Processing complete for " + name + ": " + term_server_ip + " " + port)
        print(" ######################################################### ")
        print("  ")
        pass

