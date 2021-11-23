#!/usr/bin/env bash

echo "******* Install SSH *********"
sudo apt-get update
sudo apt-get install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
echo ""

echo "******* Install Misc Utilities *********"
yes Y | sudo apt install jq
yes Y | sudo apt install mc
yes Y | sudo apt install curl
yes Y | sudo apt install busybox
yes Y | sudo apt install wget
echo ""

echo "******* Install Python / Ansible *********"
sudo apt-get update
echo ""

echo "******Installing PIP package*******"
yes Y | sudo apt install python3-pip
echo ""

echo "******Installing python3-setuptools*******"
yes Y | sudo apt install python3-setuptools
echo ""

echo "******Installing pexpect package*******"
pip install pexpect
echo "******Installing paramiko package*******"
pip install paramiko
echo "******Installing ncclient package*******"
pip install ncclient
echo "******Installing pylint package*******"
pip install pylint
echo "******Installing passlib package*******"
pip install passlib
echo "******Installing scp package*******"
pip install scp
echo "******Installing jmespath package*******"
pip install jmespath
echo "******Installing textfsm package*******"
pip install textfsm



echo "******** Installing Git*******"
sudo apt-get install git
sudo apt-get install -y sshpass
echo ""

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
export ANSIBLE_LIBRARY=/ansible/library
echo "ANSIBLE_LIBRARY is: " $ANSIBLE_LIBRARY
export PYTHONPATH=/ansible/lib
export PATH=/ansible/bin:$PATH
echo ""

echo "******** Configure Ansible "Pretty Output" Variable *******"
export ANSIBLE_STDOUT_CALLBACK=debug
echo "ANSIBLE_STDOUT_CALLBACK is: " $ANSIBLE_STDOUT_CALLBACK
echo ""

echo "******Installing Ansible*******"
pip install ansible==2.9.15
echo ""

echo "******** Installing Ansible Galaxy and Network Engine******"
ansible-galaxy install ansible-network.network-engine
echo ""

# Reset time to Pacific
export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/US/Pacific /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata
echo ""

mkdir /etc/ansible/
cp /vagrant/etc/playbook/ansible.cfg.master /etc/ansible/ansible.cfg

echo ""
echo "******Initial Setup Complete!******"
echo ""
echo "****** Now Running Python Script to Enable SSH on Lab Devices ******"
python3 /vagrant/etc/playbook/telnet_lab_fixer.py
echo ""
echo "****** Now Running Lab Configuration Playbook ******"
ansible-playbook /vagrant/etc/playbook/telemetry.yml -i /vagrant/etc/playbook/hosts
echo ""
echo ""
echo "******Lab Configuration Complete!******"

