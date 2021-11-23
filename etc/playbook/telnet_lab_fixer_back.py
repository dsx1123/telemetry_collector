
import getpass
import sys
import telnetlib
import traceback
import time
import socket
import os
import ast
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

time_out = 5

with open(os.getenv('LAB_ID'), 'r') as f:
    target_lab = ast.literal_eval(f.read())

def loop():
    print(" Looping through systems... ")
    for system in target_lab:
        print(" ######################################################### ")
        print(" BEGIN PROCESSING FOR " + system['name'] )
        print(" ######################################################### ")
        term_server_ip = system['term_server_ip']
        telnet_port = system['telnet_port']
        port_arg = telnet_port
        # print(term_server_ip)
        # print("type:term_server_ip ")
        # print(type(term_server_ip))
        # print("type:telnet_port ")
        # print(telnet_port)
        # print(port_arg)
        # print(type(telnet_port))
        name = system['name']
        password = system['password']
        username = system['username']
        management_vrf = system['mgmt_vrf']
        management_ip = system['mgmt_ip']
        management_mask = system['mgmt_mask']
        management_default_gateway = system['mgmt_dgw']
        management_interface_name = system['mgmt_intf_name']
        # print(" ######################################################### ")
        for key, values in system.items():
            if key == "problems":
                problem_list = values
                # print(type(problem_list))
                # print ("problem list " + str(values))
        # print(" ######################################################### ")
        try:
            # print("checkpoint 2 ****************************************************************************")
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  #SOCK_STREAM means TCP AF_INET means IPv4 address family
            # print("checkpoint 3 ****************************************************************************")
            #s.connect((HOST,SharedSvsPORT))
            s.connect((term_server_ip,telnet_port))
            # print("checkpoint 4 ****************************************************************************")
            s.sendall(b'\xff\xfe\x01\xff\xfd\x03\xff\xfc\x18\xff\xfc\x1f')
            # print("checkpoint 5 ****************************************************************************")
            time.sleep(2)
            # print("checkpoint 6 ****************************************************************************")
            s.send(b'\r')
            # print("checkpoint 7 ****************************************************************************")
            time.sleep(2)
            # print("checkpoint 8 ****************************************************************************")
            s.send(b'\r')
            response = s.recv(1024)
            # print("checkpoint 9 ****************************************************************************")
            response = s.recv(1024)
            # print("checkpoint 10 ****************************************************************************")
            print("****************************************************************************")
            print(" Print initial response after telnet session established to switch")
            print("****************************************************************************")
            print(response)
            print(" Complete command sequence to enter config terminal mode on switch...")
            if b'rommon' in response:
                print("****************************************************************************")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("  ERROR:  SWITCH IS IN ROMMON MODE!! ")
                print("****************************************************************************")
            if b'>' in response:
                print("****************************************************************************")
                print("  Discovered `>` in response ")
                print("****************************************************************************")
                print(b'Switch is NOT in enable mode ' + response)
                s.send(b'enable\r')
                time.sleep(2)
                response = s.recv(1024)
                if b'Password:' in response:
                    send_string = password
                    s.send(send_string.encode())
                    s.send(b'\r')
                    time.sleep(2)
                s.send(b'config terminal')
                time.sleep(2)
                response = s.recv(1024)
                s.send(b'\r')
                time.sleep(2)
                print(" Switch should be in config mode now")
                response = s.recv(1024)
                print(response)
                print(" Standardize usernames to include both `cisco` and `admin` ")
                s.send(b'username cisco privilege 15 password 0 cisco!123\r')
                time.sleep(2)
                s.send(b'username admin privilege 15 password 0 cisco!123\r')
                time.sleep(2)
                # s.send(b'exit\r')
                # time.sleep(2)
                response = s.recv(2048)
                s.send(b'do show run | i username\r')
                response = s.recv(2048)
                print(response)
            #   s.send(b'logout\r')
            #   response = s.recv(2048)
            #   print(response)
            #   print("Call remediation function")
            #   s.close()
            #   remediation(problem_list, term_server_ip, telnet_port)
            elif b'(config)#' in response:
                print("****************************************************************************")
                print("Discovered `(config)#` in response ")
                print("****************************************************************************")
                print(b'Switch appears to be in config mode already' + response)
                s.send(b'\r')
                print(" Standardize usernames to include both `cisco` and `admin` ")
                s.send(b'username cisco privilege 15 password 0 cisco!123\r')
                time.sleep(2)
                s.send(b'username admin privilege 15 password 0 cisco!123\r')
                time.sleep(2)
                response = s.recv(2048)
                s.send(b'do show run | i username\r')
                response = s.recv(2048)
                print(response)
            #   print("Call remediation function")
            #   s.close()
            #   remediation(problem_list, term_server_ip, telnet_port)
            elif b'#' in response:
                print("****************************************************************************")
                print("Discovered `#` in response ")
                print("****************************************************************************")
                print(b'Switch appears to be in enable mode...' + response)
                print(" Enter configuration mode ")
                s.send(b'conf t')
                s.send(b'\r')
                print(" Standardize usernames to include both `cisco` and `admin` ")
                s.send(b'username cisco privilege 15 password 0 cisco!123\r')
                time.sleep(2)
                s.send(b'username admin privilege 15 password 0 cisco!123\r')
                time.sleep(2)
                response = s.recv(1024)
                s.send(b'do show run | i username\r\n')
                time.sleep(2)
                response = s.recv(1024)
                print(response)
            #   print("Call remediation function")
            #   s.close()
            #   remediation(problem_list, term_server_ip, telnet_port)
            else:
                print(b'Something else ' + response)
                s.close()
            for problem in problem_list:
                print(" Looping through problems now... ")
                print("The current problem is: " + problem)
                if problem == "aaa_authorization":
                    print("Send aaa commands to switch")
                    s.send(b'aaa new-model\n')
                    time.sleep(2)
                    s.send(b'aaa authorization exec default local\n')
                    time.sleep(2)
                    response = s.recv(1024)
                    s.send(b'do sh run | i aaa\n')
                    time.sleep(2)
                    response = s.recv(1024)
                    print(response)
                elif problem == "no_mgmt_ip":
                    print("Send interface configuration and default route commands to switch")
                    ########################################################
                    send_string = "ip vrf " + management_vrf
                    print(" Command sent to socket: " + send_string)
                    s.send(send_string.encode())
                    s.send(b'\r')
                    time.sleep(2)
                    ########################################################
                    send_string = "interface " + management_interface_name
                    print(" Command sent to socket: " + send_string)
                    s.send(send_string.encode())
                    s.send(b'\r')
                    time.sleep(2)
                    ########################################################
                    send_string = "ip vrf forwarding " + management_vrf
                    print(" Command sent to socket: " + send_string)
                    s.send(send_string.encode())
                    s.send(b'\r')
                    time.sleep(2)
                    ########################################################
                    send_string = "ip address " + management_ip + " " + management_mask
                    print(" Command sent to socket: " + send_string)
                    s.send(send_string.encode())
                    s.send(b'\r')
                    time.sleep(2)
                    ########################################################
                    s.send(b'no shutdown\r')
                    time.sleep(2)
                    ########################################################
                    send_string = "ip route 0.0.0.0 0.0.0.0 " + management_default_gateway
                    print(" Command sent to socket: " + send_string)
                    s.send(send_string.encode())
                    s.send(b'\r')
                    time.sleep(2)
            print(" For loop complete... ")
            s.send(b'exit\r')
            time.sleep(2)
            s.send(b'exit\r')
            time.sleep(2)
            s.send(b'logout\r')
            response = s.recv(2048)
            print(response)
        except:
            print("  ")
            print(" ######################################################### ")
            print(" PROBLEM " + name + ": " + term_server_ip + " " + str(telnet_port))
            print(" ######################################################### ")
            print("  ")
            s.close()
            #pass



def main():
    loop()

if __name__ == "__main__":
    main()




# for d in my_list:
#     for key in d:
#         print("{}: {}".format(key, d[key]))


# my_list = [
#     {'name': 'alex',
#      'last_name': 'leda'
#     },
#     {'name': 'john',
#      'last_name': 'parsons'
#     }
# ]


# print(type(systems))
# for item in systems:
#     print (item['problems'])
#     for problem in item['problems']:
#       print (problem)

# for x in range(len(str_list)):

# for item in systems:
#     for problem in range(len(item['problems'])):
#       print (problem)

# str_list = ["New York","Los Angeles","Chicago","Houston","Phoenix",
#             "Philadelphia"]
# for x in range(len(str_list)):
#     print(str_list[x])


# for system in systems:
#     term_server_ip = system['term_server_ip']
#     telnet_port = system['telnet_port']
#     name = system['name']
#     password = system['password']
#     username = system['username']
#     management_ip = system['mgmt_ip']
#     management_mask = system['mgmt_mask']
#     management_default_gateway = system['mgmt_dgw']
#     print(" ######################################################### ")
#     for key, values in system.items():
#         if key == "problems":
#           problem_list = values
#           print(type(problem_list))
#           print ("problem list " + str(values))
#     print(" ######################################################### ")

#     print("Telnet to host " + term_server_ip + " on port " + telnet_port)
#     try:
#       print("Trying now...")
#       tn = telnetlib.Telnet(host=term_server_ip, port=telnet_port, timeout=time_out)
#       tn.set_debuglevel(1)
#       print("  ")
#       print(" ######################################################### ")
#       print(" ######################################################### ")
#       print(" Successful telnet to " + name + ": " + term_server_ip + " " + telnet_port)
#       print(" ######################################################### ")
#       print("  ")
#       print("checkpoint 3 ")
#       tn.write(b"\r\n")
#       if b'>' in tn.read_until(b'>', timeout=1):
#         print("System Information >>>>>>>>>>:  "  + name + ": " + term_server_ip + " " + telnet_port)
#         print("> prompt detected")
#         tn.write(b'enable\n')
#         time.sleep(1)
#         tn.write(bytes(password, 'ascii') + b"\r\n")
#         time.sleep(1)
#         tn.write(b"configure terminal\n")
#         time.sleep(1)
#         tn.write(b"username cisco privilege 15 password 0 cisco!123\n")
#         time.sleep(1)
#         tn.write(b"username admin privilege 15 password 0 cisco!123\n")
#         time.sleep(1)
#         print("Here's the problem list: " + str(problem_list))
#         for problem in problem_list:
#           if problem == "aaa_authentication":
#             tn.write(b"aaa new-model\n")
#             time.sleep(1)
#             tn.write(b"aaa authorization exec default local\n")
#             time.sleep(1)
#           elif problem == "no_mgmt_ip":
#             tn.write(b"interface " + system['mgmt_intf_name'] + "\r\n")
#             time.sleep(1)
#             tn.write(b"vrf member management\r\n")
#             time.sleep(1)
#             tn.write(b"ip address 10.66.94.216/28\r\n")
#             time.sleep(1)
#             tn.write(b"vrf context management\r\n")
#             time.sleep(1)
#             tn.write(b"ip route 0.0.0.0/0 10.66.94.209\r\n")
#             time.sleep(1)
#           elif problem == "no_vrf":
#             print('No VRF')
#           elif problem == "no_ssh_keys":
#             print('No ssh keys')
#           else:
#             print('Error:  Undefined Problem')
#       elif b'#' in tn.read_until(b'#', timeout=1):
#         print("System Information >>>>>>>>>>:  "  + name + ": " + term_server_ip + " " + telnet_port)
#         print("exec prompt detected")
#         tn.write(b"configure terminal\n")
#         time.sleep(1)
#         print("Here's the problem list: " + str(problem_list))
#         for problem in problem_list:
#           if problem == "aaa_authentication":
#             tn.write(b"aaa new-model\n")
#             time.sleep(1)
#             tn.write(b"aaa authorization exec default local\n")
#             time.sleep(1)
#           elif problem == "no_mgmt_ip":
#             tn.write(b"interface " + system['mgmt_intf_name'] + "\r\n")
#             time.sleep(1)
#             tn.write(b"vrf member management\r\n")
#             time.sleep(1)
#             tn.write(b"ip address 10.66.94.216/28\r\n")
#             time.sleep(1)
#             tn.write(b"vrf context management\r\n")
#             time.sleep(1)
#             tn.write(b"ip route 0.0.0.0/0 10.66.94.209\r\n")
#             time.sleep(1)
#           elif problem == "no_vrf":
#             print('No VRF')
#           elif problem == "no_ssh_keys":
#             print('No ssh keys')
#           else:
#             print('Error:  Undefined Problem')
#         print(tn.read_all().decode('ascii'))
#         tn.sock.close()
#       else:
#         print("after carriage return, still can't read a prompt")
#         print("Here's the problem list: " + str(problem_list))
#       tn.sock.close()
#     except:
#         print("  ")
#         print(" ######################################################### ")
#         print(" Processing issue for " + name + ": " + term_server_ip + " " + telnet_port)
#         print(" ######################################################### ")
#         print("  ")
#         tn.sock.close()
#         pass




# systems = [
#     {'name': 'KLANSW-9348U-5',
#      'term_server_ip': '10.62.143.238',
#      'telnet_port': '2063',
#      'mgmt_ip': '10.62.149.174',
#      'mgmt_mask': '255.255.255.0',
#      'mgmt_dgw': '10.62.149.1', 
#      'mgmt_intf_name': "mgmt0",
#      'username': 'cisco',
#      'password': 'cisco!123',
#      #'problems': '[aaa_authorization, no_mgmt_ip, no_vrf, no_ssh_keys]'
#      'problems': '[aaa_authorization]'
#     },
#     {'name': 'KLANSW-9348U-6',
#      'term_server_ip': '10.62.143.238',
#      'telnet_port': '2058',
#      'mgmt_ip': '10.62.149.175',
#      'mgmt_mask': '255.255.255.0',
#      'mgmt_dgw': '10.62.149.1', 
#      'mgmt_intf_name': "mgmt0",
#      'username': 'cisco',
#      'password': 'cisco!123',
#      #'problems': '[aaa_authorization, no_mgmt_ip, no_vrf, no_ssh_keys]'
#      'problems': '[aaa_authorization]'
#     },
#     {'name': 'KLANSW-9606R-1',
#      'term_server_ip': '10.62.143.238',
#      'telnet_port': '2065',
#      'mgmt_ip': '10.62.149.173',
#      'mgmt_mask': '255.255.255.0',
#      'mgmt_dgw': '10.62.149.1', 
#      'mgmt_intf_name': "mgmt0",
#      'username': 'cisco',
#      'password': 'cisco!123',
#      #'problems': '[aaa_authorization, no_mgmt_ip, no_vrf, no_ssh_keys]'
#      'problems': '[aaa_authorization]'
#     }
# ]
