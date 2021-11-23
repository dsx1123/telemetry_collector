 #!/usr/bin/env bash

cd /vagrant
export DOCKER_PASS="Ocwen1936!"
export DOCKER_USER="sclake"
export GRAFANA_VOLUME="grafana-volume"
export TELEGRAF_CONFIG="`pwd`/etc/telegraf"
export GRAFANA_CONFIG="`pwd`/etc/grafana"
export INFLUXDB_CONFIG="`pwd`/etc/influxdb"
export INFLUXDB_ENGINE="`pwd`/influxdb"
export CURRENT_UID=`id -u`
export CURRENT_GID=`id -g`

export TELEGRAF_IMAGE="telegraf:latest"
export INFLUXDB_IMAGE="influxdb:2.0.8"
export GRAFANA_IMAGE="grafana/grafana:8.1.2"

export INFLUXDB_USER="influxdb"
export INFLUXDB_PASSWD="cisco123"
export INFLUXDB_ORG="Cisco"

###########################################################################################
export INFLUXDB_BUCKET="nxos_gnmi"
export INFLUXDB_MDT_BUCKET="nxos_dialout"
###########################################################################################

export GRAFANA_ADMIN_USER="grafana"
export GRAFANA_ADMIN_PASSWD="cisco123"
export INFLUXDB_INIT_TOKEN="MySecretToken"

self=$0 # "$0" is just the name of the running shell script.
TELEGRAF_USER="telegraf"
TELEGRAF_CERT_PATH="$TELEGRAF_CONFIG/cert"
GNMI_CERT_PASSWD="cisco123"
pull_image=false # Set to "true" if you want docker-compose to pre-pull the image.

# switches=( "10.62.149.120:50051" \
# )
# switches=( "10.88.244.121:50051" \
# )
# switches=( "10.88.244.123:50051" \
#         #    "10.88.244.123:50051" \
#         #    "10.88.244.121:50051" \
#         #    "10.88.244.121:50051" \
#         #    "10.88.244.121:50051" \
# )

switches=( "10.62.149.173:50051" \
            "10.62.149.174:50051" \
            "10.62.149.175:50051" \
        #    "10.88.244.121:50051" \
        #    "10.88.244.121:50051" \
)

switches_test=$(<switches.txt)
echo "############################################"
echo "############################################"
echo "############################################"
echo "############################################"
echo "switches = $switches"
echo "############################################"
echo "############################################"
echo "############################################"
echo "############################################"



# user on switch for authentication, need network-operator role at least
gnmi_user="telemetry"
gnmi_password="cisco123"

#For telegraf certificate
country=US
state=CA
locality="San Jose"
organization=Cisco
organizationalunit=BU
email=telemetry@cisco.com
cn_mdt=telegraf
cn_gnmi=gnmi
cn_influxdb=influxdb


function log() {
    ts=`date '+%Y-%m-%dT%H:%M:%S'`
    echo "$ts--LOG--$@"
}

function clean() {
    # clean database of influxdb and volume of grafana
    log "cleaning influxdb database"
    rm -rf $INFLUXDB_ENGINE

    log "remove generated telegraf conf files"
    rm -rf $TELEGRAF_CONFIG/telegraf.conf
    rm -rf $TELEGRAF_CONFIG/telegraf.d/gnmi.conf

    log "deleting grafana volume $GRAFANA_VOLUME"
    docker volume rm $GRAFANA_VOLUME
}

function prepare_grafana() {
    log "create docker volume $GRAFANA_VOLUME"
    docker volume create --name $GRAFANA_VOLUME
    docker volume inspect $GRAFANA_VOLUME  1>/dev/null 2>/dev/null
    if [ ! $? -eq 0 ]; then
        log "create docker volume $GRAFANA_VOLUME"
        docker volume create --name $GRAFANA_VOLUME
    fi
    if [ "$pull_image" = true ]; then
        log "pull the latest image $GRAFANA_IMAGE"
        docker-compose  pull grafana
    fi
}

function gen_telegraf_cert() {
    if [ ! -d $TELEGRAF_CERT_PATH ]; then
        log "gernerating self-signed certificates for telegraf plugins"
        mkdir $TELEGRAF_CERT_PATH
    fi

    # The loop below checks to see if either the mdt or gnmi key is present
    # and if not, generates a new key (.key) and csr (.csr) based on a csr config file
    # and then generates the certificate (.crt)
    # The certificate is then exported to .pkcs12 format to load on switches
    # (via ansible)
    for cn in $cn_mdt $cn_gnmi
    do
        if [ ! -e $TELEGRAF_CERT_PATH/$cn.key ] || [ ! -e $TELEGRAF_CERT_PATH/$cn.crt ]
        then
            log "$cn certificate does not exist, generating"
            generate_self_signed_cert $cn $TELEGRAF_CERT_PATH #passing (2) args
        fi
    done
    # Note below variables used below come from previous operation
    if [ ! -e $TELEGRAF_CERT_PATH/$cn_gnmi.pfx ]; then
        log "export $cn_gnmi.crt to pkcs12 format to import to switches"
        openssl pkcs12 -export -out $TELEGRAF_CERT_PATH/$cn_gnmi.pfx \
            -inkey $TELEGRAF_CERT_PATH/$cn_gnmi.key \
            -in $TELEGRAF_CERT_PATH/$cn_gnmi.crt \
            -certfile $TELEGRAF_CERT_PATH/$cn_gnmi.crt \
            -password pass:$GNMI_CERT_PASSWD
        log "$TELEGRAF_CERT_PATH/$cn_gnmi.pfx has been exported with password $GNMI_CERT_PASSWD please use to import to switches"
    fi
}

function generate_self_signed_cert() {     #receiving (2) args
    # create csr config file
    common_name=$1 # CN of certificate
    path=$2 # folder of certificates (i.e., $TELEGRAF_CERT_PATH)
    csr_config=$path/$common_name.csr.conf
    key_file=$path/$common_name.key
    csr_file=$path/$common_name.csr
    cert_file=$path/$common_name.crt
    # Now construct file used to generate certs
    # Note <<EOF [text] EOF syntax copies below text to file
    cat > $csr_config <<EOF
[ req ]
default_bits        = 2048
default_md          = sha256
encrypt_key         = no
prompt              = no
distinguished_name  = $common_name

[ $common_name ]
C                   =$country
ST                  =$state
O                   =$organization
L                   =$locality
CN                  =$common_name
OU                  =$organizationalunit
emailAddress        =$email
EOF
    # Understand sequence of requiring config file to generate private key and 
    # certificate signing request, then using those as inputs to 
    # certificate generation

    log "gernerating private key for CN $common_name"
    log "gernerating certificate signing request for CN $common_name"
    openssl req -config $csr_config -new -newkey rsa:2048 -nodes -keyout $key_file -out $csr_file

    log "gerenrating certificate for CN $common_name "
    openssl x509 -req -days 3650 -in $csr_file  -signkey $key_file -out $cert_file

}

function prepare_influxdb() {
    if [ ! -d $INFLUXDB_DATA ]; then
        log "influxdb database folder does not exist, creating one"
        mkdir $INFLUXDB_DATA
    fi

    if [ "$pull_image" = true ]; then
        log "pull the required version of image $INFLUXDB_IMAGE"
        docker-compose pull influxdb
    fi
}

function prepare_telegraf() {
    # generate certificate if doesn't exist
    log "############################################"
    log "prepare_telegraf"
    log "############################################"
    gen_telegraf_cert
    log "Certs generated, are the switch names being echoed below?"
    for a in ${switches[@]}; do
        echo "\" $a \" "
    done

    # The concept with the code below is that we need to take a raw list
    # of switch IPs and create a variable string that reads 
    # "addresses = [list of addresses]" for use later in the code.
    # If you just print the list of addresses from the file (not echoing), 
    # there is a trailing comma.  
    # Note that printing the output changes the output to a comma-separated
    # notation with a trailing comma at the end of the list. 
    # For example, 
    #   echo \${switches[*]}
    # Returns
    #   172.25.74.70:50051 172.25.74.61:50051 172.25.74.87:50051 
    #   172.25.74.88:50051 172.25.74.163:50051
    # However...
    #   switch_list=\`printf -- "\"%s\"," \${switches[*]}\`
    #   echo $switch_list
    # Returns 
    #   "172.25.74.70:50051","172.25.74.61:50051","172.25.74.87:50051", /
    #   "172.25.74.88:50051","172.25.74.163:50051",
    # However, 
    #   switch_list=\`printf -- "\"%s\"," \${switches[*]} | cut -d "," -f 1-\${#switches[@]}\`
    #   echo $switch_list
    # Returns... 
    #   "172.25.74.70:50051","172.25.74.61:50051","172.25.74.87:50051",
    #   "172.25.74.88:50051","172.25.74.163:50051"
    # ...note how the trailing comma has been stripped with bash cut -fields syntax
    # And if 
    #    addresses="addresses = [\$switch_list]"
    # echo addresses returns...
    #    addresses = ["172.25.74.70:50051","172.25.74.61:50051","172.25.74.87:50051",
    #                 "172.25.74.88:50051","172.25.74.163:50051"]
    # IMPORTANT:  When building script files from the command line (as above
    #             with cat), quotes "" and dollar signs $ need to be escaped with "\"
    #             Apparently escaping is not necessary when running pre-built scripts
    # 
    # To summarize then, if you have a list of elements in a separate file, or a 
    # list of elements in a varible in a script ("bash array"), and you need 
    # to create an iterable list from either the file or the script variable, 
    # then you need to first create a comma-delimited list with the printf 
    # command and the [*] list iterator, then pass the output to the cut filter
    # and cut the number of fields equal to the number of elements in the list.
    # This will remove the trailing comma from the list.
    
    switch_list=`printf -- "\"%s\"," ${switches[*]} | cut -d "," -f 1-${#switches[@]}`
    addresses="addresses = [$switch_list]"
    echo $addresses

    # Create a list of switch ip's to be used in the telegraf.conf file
    IPs=()
    for sw in "${switches[@]}"; do
        IFS=':' read -a ip <<< "$sw"
        IPs+=(${ip[0]})
    done
    url_list=`printf -- "\"%s\"," ${IPs[*]} | cut -d "," -f 1-${#IPs[@]}`
    urls="urls = [$url_list]"

    # The above code parses each element in the switches list and extracts the
    # ip address from the "ip_address:port" notation by creating an array 
    # from each element with the read -a function, extracting the required
    # element from the array variable and appending that value to a new list

    echo "############################################"
    echo "delete old telegraf conf files"
    echo "############################################"
    rm -rf $TELEGRAF_CONFIG/telegraf.conf
    rm -rf $TELEGRAF_CONFIG/telegraf.d/gnmi.conf

    # generate telegraf config file from example
    if [ ! -e $TELEGRAF_CONFIG/telegraf.conf ]; then
        log "telegraf.conf is missing, new telegraf.conf will be generated"
        sed -e "0,/^token\ =.*/s//token\ = \"$INFLUXDB_INIT_TOKEN\"/" \
            -e "0,/^urls\ =.*/s//$urls/" \
            $TELEGRAF_CONFIG/telegraf.conf.example > $TELEGRAF_CONFIG/telegraf.conf
        log "telegraf.conf has been generated from telegraf.conf.example template"
        cat $TELEGRAF_CONFIG/telegraf.conf
    fi

    cat $TELEGRAF_CONFIG/telegraf.conf

    # generate gnmi config file from example
    if [ ! -e $TELEGRAF_CONFIG/telegraf.d/gnmi.conf ]; then
        log "gnmi.conf is missing, new gnmi.conf will be generated"
        echo $addresses
        echo $gnmi_user
        echo $gnmi_password
        echo $INFLUXDB_INIT_TOKEN
        sed -e "0,/^addresses\ =.*/s//$addresses/" \
            -e "0,/^username\ =.*/s//username\ = \"$gnmi_user\"/" \
            -e "0,/^password\ =.*/s//password\ = \"$gnmi_password\"/" \
            -e "0,/^token\ =.*/s//token\ = \"$INFLUXDB_INIT_TOKEN\"/" \
            $TELEGRAF_CONFIG/telegraf.d/gnmi.conf.example > $TELEGRAF_CONFIG/telegraf.d/gnmi.conf
        log "gnmi.conf has been generated from gnmi.conf.example template"
        cat $TELEGRAF_CONFIG/telegraf.d/gnmi.conf
    fi

    if [ "$pull_image" = true ]; then
        echo "############################################"
        echo "pull the latest version of image $TELEGRAF_IMAGE"
        echo "############################################"
        docker-compose --verbose pull telegraf
    fi
}

function check_influxdb () {
    # check if influxdb is ready for connection
    log "waiting for influxdb getting ready"
    while true; do
        result=`curl -w %{http_code} --silent --output /dev/null http://localhost:8086/api/v2/setup`
        if [ $result -eq 200 ]; then
            log "influxdb is online!"
            break
        fi
        sleep 3
    done
}

function setup_influxdb() {
    # initalize influxdb
    result=`curl --silent http://localhost:8086/api/v2/setup`
    if [[ $result == *'true'* ]]; then
        log "influxbd is not initialized, setup influxdb"
        # echo "##################################################################################"
        # echo "##################################################################################"
        # log "install jq json processor in influxdb container"
        # echo "##################################################################################"
        # echo "##################################################################################"
        # docker exec -t influxdb apt-get update -y && sudo apt-get install jq -y
        # Note that jq had to be added as the jq utility is required to parse json output
        # structures yielded by "influx auth list" and "influx org find" commands.
        # We did see some use of awk to get info out of these structures but not followed 
        # up on.  

        log "influx config create"
        # Note that instead of 100% using env vars as input to the setup activity, the 
        # "influx config create" command is run to create a config file
        docker exec -t influxdb influx config create \
        --config-name telemetry_collector \
        --host-url http://127.0.0.1:8086 \
        --org $INFLUXDB_ORG \
        --token $INFLUXDB_INIT_TOKEN \
        --active 

        echo "Remove old influx-configs file"
	    # below is for testing only when container is already up and we're running
        # the script again. the script fails if there is an old config file present
        docker exec -t influxdb rm /etc/influxdb2/influx-configs

	    # below will generate /etc/influxdb2/influx-configs
        echo "##################################################################################"
        echo "influx setup"
        echo "##################################################################################"
        # So this is essentially an initial "authorization create" that we will create the 
        # credentials to create successive authorization activities
        docker exec -t influxdb influx setup \
            --org $INFLUXDB_ORG\
            --bucket $INFLUXDB_BUCKET\
            --username $INFLUXDB_USER\
            --password $INFLUXDB_PASSWD\
            --token $INFLUXDB_INIT_TOKEN\
            --retention 2h \
            --force

        # vars repeated here for convenience.
        # export INFLUXDB_USER="influxdb"
        # export INFLUXDB_PASSWD="cisco123"
        # export INFLUXDB_ORG="Cisco"
        # export INFLUXDB_BUCKET="nxos_gnmi"
        # export INFLUXDB_MDT_BUCKET="nxos_dialout"

        # These statements expose the IDs and other info contained within the auth created above.
        echo "##################################################################################"
        echo " operator/admin authorization json structure "
        echo " note that the bucket token has not been generated yet"
        echo "##################################################################################"
        docker exec influxdb influx auth list --user $INFLUXDB_USER --json
        echo "##################################################################################"
        GENERATED_TOKEN=`docker exec influxdb influx auth list --user $INFLUXDB_USER --json | jq -r ".[] | .token"`
        echo "GENERATED_TOKEN = $GENERATED_TOKEN"
        echo "##################################################################################"
        log " Display all authentication informattion "
        echo "##################################################################################"
        docker exec influxdb influx org find -t $GENERATED_TOKEN --json
        echo "##################################################################################"
        GENERATED_ORG_ID=`docker exec influxdb influx org find -t $GENERATED_TOKEN --json | jq -r ".[] | .id"`
        echo "generated org id = $GENERATED_ORG_ID for $INFLUXDB_ORG"
        echo "##################################################################################"
        INITIAL_BUCKET_ID=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"$INFLUXDB_BUCKET\").id"`
        echo "$INFLUXDB_BUCKET id = $INITIAL_BUCKET_ID"
        echo "##################################################################################"
        userName=`docker exec influxdb influx auth list --user $INFLUXDB_USER --json | jq -r ".[] | .userName"`
        echo "userName = $userName"
        echo "##################################################################################"
        userID=`docker exec influxdb influx auth list --user $INFLUXDB_USER --json | jq -r ".[] | .id"`
        echo "userID for $userName = $userID"
        docker exec -t influxdb influx auth create -o Cisco -d GNMIBucketId --read-bucket $INITIAL_BUCKET_ID --write-bucket $INITIAL_BUCKET_ID

        echo "##################################################################################"
        echo "##################################################################################"
        echo " create new nxos_dialout bucket: "
        echo "##################################################################################"
        docker exec -t influxdb influx bucket create -n $INFLUXDB_MDT_BUCKET -o $INFLUXDB_ORG -r 72h
        MDTBucketId=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"$INFLUXDB_MDT_BUCKET\").id"`
        echo "INFLUXDB_MDT_BUCKET Bucket ID = $MDTBucketId"
        echo "##################################################################################"
        docker exec -t influxdb influx auth create -o Cisco -d MDTBucketId --read-bucket $MDTBucketId --write-bucket $MDTBucketId
        echo "##################################################################################"
        echo "##################################################################################"
        echo " user influxdb authorizations: "
        echo "##################################################################################"
        # docker exec influxdb influx auth list --user $INFLUXDB_USER --json

        
    fi
}

function start() {
    docker --version >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        log "docker is not installed, exist"
        exit 1
    fi
    prepare_influxdb
    prepare_telegraf
    prepare_grafana
    echo "############################################"
    echo "###  Configure Docker Authentication     ###"
    echo "############################################"
    echo $DOCKER_PASS | docker login -u$DOCKER_USER --password-stdin
    echo "############################################"
    echo "starting docker containers"
    echo "############################################"
    docker-compose up --build -d
    check_influxdb
    echo "############################################"
    echo "###  Now setup influxdb                  ###"
    echo "############################################"
    setup_influxdb
}

function stop () {
    log "stopping docker containers"
    docker-compose stop
}

function down () {
    log "stopping and cleaning docker containers"
    docker-compose down
}

function reset () {
    # reset project to initial state
    down
    clean
    # remove certificates
    rm -rf $TELEGRAF_CERT_PATH
    rm -rf $INFLUXDB_CONFIG/influx-configs
}

function restart_svc () {
    if [ $# -eq 0 ]; then
        stop
        start
        exit 0
    fi
    case "$1" in
        telegraf)
            docker-compose restart telegraf
            ;;
        influxdb)
            docker-compose restart influxdb
            ;;
        grafana)
            docker-compose restart grafana
            ;;
        *)
            display_help
            exit 1
    esac
}

function display_help() {
    echo "Usage: $self {start|stop|restart|cert|clean}"
    echo "  start  :   start docker containers for telegraf/influxdb/grafana"
    echo "  stop   :   stop docker containers for telegraf/influxdb/grafana"
    echo "  down   :   stop and remove docker containers for telegraf/influxdb/grafana"
    echo "  restart:   restart docker containers for telegraf/influxdb/grafana"
    echo "  cert   :   generate certificates for telegraf plugin"
    echo "  clean  :   clean the database of influxdb, volume of grafana"
    echo "  reset  :   reset project to inital state"
}


case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    down)
        down
        ;;
    restart)
        restart_svc $2
        ;;
    cert)
        gen_telegraf_cert
        ;;
    clean)
        clean
        ;;
    reset)
        reset
        ;;
    *)
        display_help
        exit 1
    esac
