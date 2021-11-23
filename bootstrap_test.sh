#!/bin/bash 

echo "##################################"
#. ./.env && echo "This is the host file being procesed:  ${HOSTS_LAB}"
. /vagrant/.env && echo "This is the host file being procesed:  ${HOSTS_LAB}"
echo "##################################"
echo "##################################"
echo "This is the host file being procesed:  ${HOSTS_LAB}"
echo "##################################"

echo ""
echo "******Initial Setup Complete!******"
echo ""
echo ""
echo ""
echo "****** Now running python script to copy            ******"
echo "****** configuration scenario from env file         ******"
echo "****** and replace scenario variable in Ansible     ******"
echo "****** playbook                                     ******"
python3 /vagrant/modify_defaults_w_env_scenario.py
echo ""
echo ""
# echo ""
# echo ""
# echo "****** Now running python script to enable SSH on   ******"
# echo "****** lab devices that are unreachable by SSH when ******"
# echo "****** lab is first reserved.                       ******"
# #python3 /vagrant/telnet_lab_fixer.py
# echo ""
# echo ""
# echo "****** Now running python script to extract switch  ******"
# echo "****** hostname information from target host file   ******"
# echo "****** to feed variable *switches* in build.sh      ******"
# echo "****** script.                                      ******"
# #python3 /vagrant/yaml_extractor.py
# echo ""
# echo ""
# echo "****** Now Running Lab Configuration Playbook ******"

# a="ansible-playbook /vagrant/etc/playbook/telemetry.yml -i /vagrant/etc/playbook/${HOSTS_LAB}"
# echo 
# echo $a
# $a
# echo ""
# echo ""
# echo "******Lab Configuration Complete!******"


# ansible-playbook /vagrant/etc/playbook/telemetry.yml -i /vagrant/etc/playbook/hosts1940

# # "#!/usr/bin/env bash"
# echo "##################################"
# . ./.env && echo ${HOSTS_LAB}
# echo "##################################"
# echo $PWD
# echo "##################################"
# # name="python3 $PWD/yaml_extractor.py"
# # echo "Execute name command"
# # echo $name
# #$name
# python3 ./yaml_extractor.py
# # This runs a python script that telnets to lab devices based on the lab file
# # in the .env file
# # >>  Need to figure out if we can delete the .env file in this folder
# #####################################################################################
# #
# #####################################################################################
# #python3 $(pwd)telnet_lab_fixer.py
# # This runs a python script that telnets to lab devices based on the lab file
# # in the .env file
# # >>  Need to figure out if we can delete the .env file in this folder
# #####################################################################################
# echo ""
# cat /vagrant/switches.txt
# echo "****** Now Running Lab Configuration Playbook ******"
# a="ansible-playbook /vagrant/etc/playbook/telemetry.yml -i /vagrant/etc/playbook/${HOSTS_LAB}"
# echo $a
# $a
# #ansible-playbook /vagrant/etc/playbook/telemetry.yml -i /vagrant/etc/playbook/hosts
# echo ""
# echo ""
# echo "******Lab Configuration Complete!******"