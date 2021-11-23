

import getpass
import sys
import telnetlib
import traceback
import time
import socket
import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())


with open(os.getenv('LAB_ID'), 'r') as f:
    result = ast.literal_eval(f.read())

print(type(result))
print(result)

for system in result:
    print(" ######################################################### ")
    print(" BEGIN PROCESSING FOR " + system['name'] )
    print(" ######################################################### ")
