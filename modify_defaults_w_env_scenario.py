
# import getpass
# import sys
# import telnetlib
# import traceback
# import time
# import socket
import os
# import ast
from dotenv import load_dotenv, find_dotenv
import re

load_dotenv(find_dotenv())

target_scenario = os.getenv('J2_TEMPLATE_SCENARIO')
print(type(target_scenario))
print("Target Scenario:  " + target_scenario)

ansible_role_defaults_file = "etc/playbook/roles/telemetry_configuration/defaults/main.yml"
with open(ansible_role_defaults_file, 'r') as f:
    # ansible_role_defaults_content = ast.literal_eval(f.read())
    ansible_role_defaults_content = f.read()
    print("ansible_role_defaults_content:  " + ansible_role_defaults_content)
    current_scenario = re.search(r'template_scenario: (\S+)$', ansible_role_defaults_content).group(1)
    # current_scenario = re.search(r'^(file.*)\.pdf$', string_one).group()

    if current_scenario:
        print("current_scenario is:  " + current_scenario)
        print(type(current_scenario))
        # print("current_scenario:  " + current_scenario.group(1))
        # print(current_scenario.group(1))
        # print(current_scenario.group(2))

with open(ansible_role_defaults_file, 'r') as f:
    # ansible_role_defaults_content = ast.literal_eval(f.read())
    ansible_role_defaults_content = f.read()
    print("type:  " + str(type(ansible_role_defaults_content)))
    print(ansible_role_defaults_content)
    ansible_role_defaults_new = ansible_role_defaults_content.replace(current_scenario, target_scenario)
    print("ansible_role_defaults_new:  " + ansible_role_defaults_new)

with open(ansible_role_defaults_file, 'w') as f:
    f.write(ansible_role_defaults_new)

