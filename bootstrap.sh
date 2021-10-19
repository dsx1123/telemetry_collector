#!/usr/bin/env bash

echo "*******Install SSH*********"
sudo apt-get update
sudo apt-get install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
    

# echo "******Installing other misc packages*******"
# yes Y | sudo apt install mc
# yes Y | sudo apt install curl
# yes Y | sudo apt install busybox
# echo ""

# echo "******Installing SHYAML package*******"
# pip install shyaml
# echo ""

# echo "*******Reading Config File**********"
# cd /vagrant/ndovt-devbox
# ansiblever=$(shyaml get-value  Ansible < versions.yml)
# echo ""

# echo "******** Installing Git*******"
# sudo apt install git
# sudo apt-get install -y sshpass
# echo ""

# echo "******** Configure Ansible Environment Vars *******"
# export ANSIBLE_RETRY_FILES_ENABLED=0
# echo "ANSIBLE_RETRY_FILES_ENABLED is: " $ANSIBLE_RETRY_FILES_ENABLED
# export ANSIBLE_GATHERING=smart
# echo "ANSIBLE_GATHERING is: " $ANSIBLE_GATHERING
# export ANSIBLE_HOST_KEY_CHECKING=false
# echo "ANSIBLE_HOST_KEY_CHECKING is: " $ANSIBLE_HOST_KEY_CHECKING
# export ANSIBLE_RETRY_FILES_ENABLED=false
# echo "ANSIBLE_RETRY_FILES_ENABLED is: " $ANSIBLE_RETRY_FILES_ENABLED
# #export ANSIBLE_ROLES_PATH=/ansible/playbooks/roles
# export ANSIBLE_ROLES_PATH=/root/.ansible/roles
# echo "ANSIBLE_ROLES_PATH is: " $ANSIBLE_ROLES_PATH
# export ANSIBLE_SSH_PIPELINING=True
# echo "ANSIBLE_SSH_PIPELINING is: " $ANSIBLE_SSH_PIPELINING
# export ANSIBLE_LIBRARY=/ansible/library
# echo "ANSIBLE_LIBRARY is: " $ANSIBLE_LIBRARY
# export PYTHONPATH=/ansible/lib
# export PATH=/ansible/bin:$PATH
# echo ""

# echo "******** Configure Ansible "Pretty Output" Variable *******"
# export ANSIBLE_STDOUT_CALLBACK=debug
# echo "ANSIBLE_STDOUT_CALLBACK is: " $ANSIBLE_STDOUT_CALLBACK
# echo ""

# echo "******Installing Ansible*******"
# if [ -z "$ansiblever" ]
# then
#       echo "\$ansiblever is empty. Installing latest and Greatest..."
#       pip install ansible
# else
#       echo "\ansible version desired is $ansiblever"
#       pip install ansible==$ansiblever
# fi
# echo ""

# echo "******** Installing Ansible Galaxy and Network Engine******"
# ansible-galaxy install ansible-network.network-engine
# echo ""

# # Run Ansible DevBox provisioning playbook
# echo "******Running DevBox Setup Playbook******"
# #cd /vagrant/ndovt-devbox
# ansible-playbook -i hosts /vagrant/ndovt-devbox/devbox.yml
# echo ""

# # Reset time to Pacific
# export DEBIAN_FRONTEND=noninteractive
# ln -fs /usr/share/zoneinfo/US/Pacific /etc/localtime
# apt-get install -y tzdata
# dpkg-reconfigure --frontend noninteractive tzdata
# echo ""

# echo "******** Run Docker w/o sudo *******"
# sudo groupadd docker
# sudo gpasswd -a $USER docker
# echo ""

# Done
echo "******Initial Setup Complete!******"

