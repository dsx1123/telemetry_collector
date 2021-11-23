import yaml, json, jmespath, os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

with open(os.getenv('HOSTS_LAB'), 'r') as f:
    try:
        result=yaml.safe_load(f)
    except yaml.YAMLError as exc:
        print(exc)
host_file_keys = list(result.keys())

for level1 in host_file_keys:
      list_of_switch_names = list(result[level1]['hosts'].keys())
      python_switch_list = []
      for switch in list_of_switch_names:
        python_switch_list.append(result[level1]['hosts'][switch]['ansible_host'] + ':50051')
      switches = "( " + ' '.join(python_switch_list) + " )"
      print(switches)
#     with open("switches.txt", 'w') as f:
      with open("/vagrant/switches.txt", 'w') as f:
        f.write(switches)

