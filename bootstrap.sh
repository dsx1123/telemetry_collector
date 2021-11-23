#!/bin/bash 
# "#!/usr/bin/env bash"

echo "##################################"
. ./.env && echo "This is the host file being procesed:  ${HOSTS_LAB}"
echo "##################################"

echo "******* Install SSH *********"
sudo apt-get update
sudo apt-get install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo apt-get install -y sshpass
echo ""

echo "******** Installing Git*******"
sudo apt-get install git
echo ""

echo "******* Install Misc Utilities *********"
yes Y | sudo apt install jq
yes Y | sudo apt install mc
yes Y | sudo apt install curl
yes Y | sudo apt install busybox
yes Y | sudo apt install wget
#yes Y | sudo apt install rustc
echo ""

echo "******Installing PIP package*******"
yes Y | sudo apt install python3-pip
echo ""

echo "******Installing python3-setuptools*******"
yes Y | sudo apt install python3-setuptools
echo ""

echo "******Installing pexpect package*******"
pip3 install pexpect
echo "******Installing paramiko package*******"
pip3 install paramiko
echo "******Installing ncclient package*******"
pip3 install ncclient
echo "******Installing pylint package*******"
pip3 install pylint
echo "******Installing passlib package*******"
pip3 install passlib
echo "******Installing scp package*******"
pip3 install scp
echo "******Installing jmespath package*******"
pip3 install jmespath
echo "******Installing textfsm package*******"
pip3 install textfsm
echo "******Installing xmltodict package*******"
pip3 install xmltodict
echo "******Installing jinja2 package*******"
pip3 install jinja2
echo "******Installing dotenv package*******"
pip3 install python-dotenv
#echo "******Installing setuptools-rust*******"
#pip3 install setuptools-rust
#echo "******Installing cryptography package*******"
#pip3 install cryptography
#echo ""

echo "******** Configure Ansible Environment Vars *******"
export ANSIBLE_RETRY_FILES_ENABLED=0
echo "ANSIBLE_RETRY_FILES_ENABLED is: " $ANSIBLE_RETRY_FILES_ENABLED
export ANSIBLE_GATHERING=smart
echo "ANSIBLE_GATHERING is: " $ANSIBLE_GATHERING
export ANSIBLE_HOST_KEY_CHECKING=false
echo "ANSIBLE_HOST_KEY_CHECKING is: " $ANSIBLE_HOST_KEY_CHECKING
export ANSIBLE_RETRY_FILES_ENABLED=false
echo "ANSIBLE_RETRY_FILES_ENABLED is: " $ANSIBLE_RETRY_FILES_ENABLED
#export ANSIBLE_ROLES_PATH=/ansible/playbooks/roles
export ANSIBLE_ROLES_PATH=/root/.ansible/roles
echo "ANSIBLE_ROLES_PATH is: " $ANSIBLE_ROLES_PATH
export ANSIBLE_SSH_PIPELINING=True
echo "ANSIBLE_SSH_PIPELINING is: " $ANSIBLE_SSH_PIPELINING
# export ANSIBLE_LIBRARY=/ansible/library
# echo "ANSIBLE_LIBRARY is: " $ANSIBLE_LIBRARY
export PYTHONPATH=/ansible/lib
export PATH=/ansible/bin:$PATH
echo ""

echo "******** Configure Ansible "Pretty Output" Variable *******"
export ANSIBLE_STDOUT_CALLBACK=debug
echo "ANSIBLE_STDOUT_CALLBACK is: " $ANSIBLE_STDOUT_CALLBACK
echo ""

echo "******Installing Ansible*******"
pip3 install ansible==2.9.15
echo ""

echo "******** Installing Ansible Galaxy and Network Engine******"
sudo ansible-galaxy install ansible-network.network-engine
# ansible-galaxy install ansible-network.network-engine
echo ""

# Reset time to Pacific
export DEBIAN_FRONTEND=noninteractive
sudo ln -fs /usr/share/zoneinfo/US/Pacific /etc/localtime
sudo apt-get install -y tzdata
sudo dpkg-reconfigure --frontend noninteractive tzdata
# ln -fs /usr/share/zoneinfo/US/Pacific /etc/localtime
# apt-get install -y tzdata
# dpkg-reconfigure --frontend noninteractive tzdata
echo ""

mkdir /etc/ansible/
sudo cp /vagrant/etc/playbook/ansible.cfg.master /etc/ansible/ansible.cfg

echo ""
echo "******Initial Setup Complete!******"
echo ""
echo "****** Now running python script to copy            ******"
echo "****** configuration scenario from env file         ******"
echo "****** and replace scenario variable in Ansible     ******"
echo "****** playbook                                     ******"
python3 /vagrant/modify_defaults_w_env_scenario.py
echo ""
echo ""
echo "****** Now running python script to enable SSH on   ******"
echo "****** lab devices that are unreachable by SSH when ******"
echo "****** lab is first reserved.                       ******"
python3 /vagrant/telnet_lab_fixer.py
echo ""
echo ""
echo "****** Now running python script to extract switch  ******"
echo "****** hostname information from target host file   ******"
echo "****** to feed variable `switches` in build.sh      ******"
echo "****** script.                                      ******"
python3 /vagrant/yaml_extractor.py
echo ""
echo ""
echo "****** Now Running Lab Configuration Playbook ******"
a="ansible-playbook /vagrant/etc/playbook/telemetry.yml -i /vagrant/etc/playbook/${HOSTS_LAB}"
echo $a
$a
echo ""
echo ""
echo "******Lab Configuration Complete!******"

