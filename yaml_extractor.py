from typing_extensions import ParamSpecArgs
import yaml, json, jmespath, os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
target_hostfile = "/vagrant/etc/playbook/" + os.getenv('HOSTS_LAB')
with open(target_hostfile, 'r') as f:
    try:
        result=yaml.safe_load(f)
    except yaml.YAMLError as exc:
        print(exc)
host_file_keys = list(result.keys())
# print(host_file_keys)

for level1 in host_file_keys:
    # print(result[level1])
    if level1 == 'all':
      list_of_switch_names = list(result[level1]['hosts'].keys())
      # print("List of switch names:  " + str(list_of_switch_names))
      python_switch_list = []
      for switch in list_of_switch_names:
        python_switch_list.append(result[level1]['hosts'][switch]['ansible_host'] + ':50051')
        # print("Python switch list:  " + str(python_switch_list))
      switches = "( " + ' '.join(python_switch_list) + " )"
      print("Formatted list of switches:  " + switches)
      with open("switches.txt", 'w') as f:
        f.write(switches)
    else:
      break

