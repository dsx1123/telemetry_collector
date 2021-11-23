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

# Reset time to Pacific
export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/US/Pacific /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata
echo ""

# Fix ssh issue between newer ubuntu versions and cisco devices
# See https://unix.stackexchange.com/questions/615987/ssh-to-cisco-device-fails-with-diffie-hellman-group1-sha1
# Note:  "config" file not visible with "ls -a ~/.ssh" unless su to root
echo -n "Ciphers " >> "$HOME/.ssh/config"
echo "******** What's in the config file? *******"
echo $PWD
cd /$HOME/.ssh
echo $PWD
echo $(ls -a)
echo $(ls -a /$HOME/.ssh)
cat "$HOME/.ssh/config"
echo "*******************************************"
echo "*******************************************"
ssh -Q cipher | tr '\n' ',' | sed -e 's/,$//' >> "$HOME/.ssh/config"
echo "******** What's in the config file? *******"
cat "$HOME/.ssh/config"
echo "*******************************************"
echo >> "$HOME/.ssh/config"
echo -n 'MACs ' >> "$HOME/.ssh/config"
ssh -Q mac | tr '\n' ',' | sed -e 's/,$//' >> "$HOME/.ssh/config"
echo >> "$HOME/.ssh/config"
echo -n 'HostKeyAlgorithms ' >> "$HOME/.ssh/config"
ssh -Q key | tr '\n' ',' | sed -e 's/,$//' >> "$HOME/.ssh/config"
echo >> "$HOME/.ssh/config"
echo -n 'KexAlgorithms ' >> "$HOME/.ssh/config"
ssh -Q kex | tr '\n' ',' | sed -e 's/,$//' >> "$HOME/.ssh/config"
echo >> "$HOME/.ssh/config"
echo "******** What's in the config file? *******"
echo $PWD
echo $(ls -a)
cat "$HOME/.ssh/config"
echo "*******************************************"
echo "*******************************************"

# Done
echo "******Initial Setup Complete!******"

grep --include=\config -rnw '/' -e "Ciphers"
