









rm config -f
rm test.sh -f
cat > test.sh <<EOF
echo -n "Ciphers " >> "$HOME/.ssh/config"
ssh -Q cipher | tr '\n' ',' | sed -e 's/,$//' >> "$HOME/.ssh/config"
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
EOF
cat ./test.sh
echo #########################
echo #########################
sudo bash ./test.sh
ls -a
cat config




rm test.sh -f
cat > test.sh <<EOF
declare -a switches
switches=( "172.25.74.70:50051" \
           "172.25.74.61:50051" \
           "172.25.74.87:50051" \
           "172.25.74.88:50051" \
           "172.25.74.163:50051" \
)
echo \${switches[0]}
echo \${switches[1]}
echo \${switches[2]}
test_var=\`ip \${switches[0]}\`
echo \$test_var

IPs=()
for sw in "\${switches[@]}"; do
    IFS=':' read -a ip <<< "\$sw"
    IPs+=(\${ip[0]})
done
echo These are the raw IPs: \${IPs[*]}
echo This is the number of elements in the list: \${#IPs[@]}
url_list=\`printf -- "\"%s\"," \${IPs[*]} | cut -d "," -f 1-\${#IPs[@]}\`
urls="urls=[\$url_list]"
echo This is the text string with the variable and the list elements:  \$urls
EOF
cat ./test.sh
echo #########################
echo #########################
sudo bash ./test.sh



rm test.sh -f
cat > test.sh <<EOF
docker pull jeremycohoe/tig_mdt
watch -e "! docker images | grep -m 1 \"jeremy\""
docker run -dit -p 3000:3000 -p 57500:57500 jeremycohoe/tig_mdt /start.sh
EOF
cat ./test.sh
echo #########################
echo #########################
sudo bash ./test.sh












# IFS sets the internal field separator to ":".  The default is " "
# The presence of the IFS allows the string to be treated as a list of
# elements.
# "read -a array_variable <<< array_value" creates an array variable
# that can parsed like any other list
# For example:
#   vagrant@telemetry-collector:~$ IFS=':'
#   vagrant@telemetry-collector:~$ read -a ip <<<'10.10.10.10:50051'
#   vagrant@telemetry-collector:~$ echo ${ip[0]}
#   10.10.10.10
#   vagrant@telemetry-collector:~$ echo ${ip[1]}
#   50051
# The read -a or readarray -t function is similar to a split function
# in python

# For this code:
#
# IPs=()
# for sw in "\${switches[@]}"; do
#     IFS=':' 
#     read -a ip <<< "\$sw"
#     IPs+=(\${ip[0]})
# done
#
# 1) start list of values that have a common delimiter 
#    (i.e, 1.1.1.1:1234 is ":")
# 2) change the default "internal field separator" to the 
#    common delimiter ":"
# 3) read each value into a separate array variable
# 4) parse out the required elements with element notation []
# 5) [For the above case] create a new list from the parsed
#    values

rm test.sh -f
cat > test.sh <<EOF
declare -a switches
switches=( "172.25.74.70:50051" \
           "172.25.74.61:50051" \
           "172.25.74.87:50051" \
           "172.25.74.88:50051" \
           "172.25.74.163:50051" \
)
echo \${switches[0]}
echo \${switches[1]}
echo \${switches[2]}
test_var=\`ip \${switches[0]}\`
echo \$test_var

IPs=()
for sw in "\${switches[@]}"; do
    IFS=':' read -a ip <<< "\$sw"
    IPs+=(\${ip[0]})
done
echo These are the raw IPs: \${IPs[*]}
echo This is the number of elements in the list: \${#IPs[@]}
url_list=\`printf -- "\"%s\"," \${IPs[*]} | cut -d "," -f 1-\${#IPs[@]}\`
urls="urls=[\$url_list]"
echo This is the text string with the variable and the list elements:  \$urls
EOF
cat ./test.sh
echo #########################
echo #########################
sudo bash ./test.sh

rm test.sh
cat > test.sh <<EOF
declare -a switches
switches=( "172.25.74.70:50051" \
           "172.25.74.61:50051" \
           "172.25.74.87:50051" \
           "172.25.74.88:50051" \
           "172.25.74.163:50051" \
)
echo This is the raw list \${switches[*]}
echo This is the number \${#switches[@]}
echo This is the raw list 1-\${#switches[@]}

switch_list=\`printf -- "\"%s\"," \${switches[*]} | cut -d "," -f 1-\${#switches[@]}\`
echo \$switch_list
addresses="addresses = [\$switch_list]"
echo \$addresses
switch_list=\`printf -- "\"%s\"," \${switches[*]}\`
echo \$switch_list
EOF

sudo bash ./test.sh

rm test.sh
cat > test.sh <<EOF
switches=( "172.25.74.70:50051" \
           "172.25.74.61:50051" \
           "172.25.74.87:50051" \
           "172.25.74.88:50051" \
           "172.25.74.163:50051" \
)
switch_list=\`printf -- "\"%s\"," ${switches[*]} | cut -d "," -f 1-${#switches[@]}\`
echo $switch_list
switch_list=\`printf -- "\"%s\"," ${switches[*]}\`
echo $switch_list
addresses="addresses = [$switch_list]"
echo $addresses
EOF

sudo bash ./test.sh

echo "Lorem:ipsum:dolor:sit:amet" | cut -d ':' -f 2
