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
export INFLUXDB_BUCKET="nxos_gnmi"
export INFLUXDB_MDT_BUCKET="nxos_dialout"

export GRAFANA_ADMIN_USER="grafana"
export GRAFANA_ADMIN_PASSWD="cisco123"
export INFLUXDB_INIT_TOKEN="MySecretToken"

self=$0 # "$0" is just the name of the running shell script.
TELEGRAF_USER="telegraf"
TELEGRAF_CERT_PATH="$TELEGRAF_CONFIG/cert"
GNMI_CERT_PASSWD="cisco123"
pull_image=false # Set to "true" if you want docker-compose to pre-pull the image.

# switches accept gNMI dial-in
switches=( "172.25.74.70:50051" \
           "172.25.74.61:50051" \
           "172.25.74.87:50051" \
           "172.25.74.88:50051" \
           "172.25.74.163:50051" \
)
# The list of switches above will be used in the generation of telegraf.conf file
# to specify which switches are allowed to log in to telegraf to send data.


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

function join_by {
    local d=$1
    shift
    echo -n "$1"
    shift
    printf "%s" "${@/#/$d}"
}

function clean() {
    # clean database of influxdb and volume of grafana
    log "cleaning influxdb database"
    rm -rf $INFLUXDB_ENGINE
    rm -rf $INFLUXDB_CONFIG/influx-configs

    log "remove generated gnmi config"
    rm -rf $TELEGRAF_CONFIG/gnmi_on_change.conf
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

    for cn in $cn_mdt $cn_gnmi
    do
        if [ ! -e $TELEGRAF_CERT_PATH/$cn.key ] || [ ! -e $TELEGRAF_CERT_PATH/$cn.crt ]
        then
            log "$cn certificate does not exist, generating"
            generate_self_signed_cert $cn $TELEGRAF_CERT_PATH
        fi
    done
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

function generate_self_signed_cert() {
    # create csr config file
    common_name=$1 # CN of certificate
    path=$2 # folder of certificates
    csr_config=$path/$common_name.csr.conf
    key_file=$path/$common_name.key
    csr_file=$path/$common_name.csr
    cert_file=$path/$common_name.crt
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
    log "gernerating private key for CN $common_name"
    log "gernerating csr for CN $common_name"
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
    gen_telegraf_cert
    log "Certs generated, are we seeing some echoes here?"
    for a in ${switches[@]}; do
        echo "\" $a \" "
    done

    # Modify the addresses in gnmi config to the switches provided
    switch_list=`printf -- "\"%s\"," ${switches[*]} | cut -d "," -f 1-${#switches[@]}`
    addresses="addresses = [$switch_list]"

    # Modify urls in the ping plugin
    IPs=()
    for sw in "${switches[@]}"; do
        IFS=':' read -a ip <<< "$sw"
        IPs+=(${ip[0]})
    done
    url_list=`printf -- "\"%s\"," ${IPs[*]} | cut -d "," -f 1-${#IPs[@]}`
    urls="urls = [$url_list]"


    # generate telegraf config file from example
    if [ ! -e $TELEGRAF_CONFIG/telegraf.conf ]; then
        log "telegraf.conf is missing"
        sed -e "0,/^token\ =.*/s//token\ = \"$INFLUXDB_INIT_TOKEN\"/" \
            -e "0,/^urls\ =.*/s//$urls/" \
            $TELEGRAF_CONFIG/telegraf.conf.example > $TELEGRAF_CONFIG/telegraf.conf
        log "telegraf.conf has been generated from telegraf.conf.example template"
    fi

    # generate gnmi config file from example
    if [ ! -e $TELEGRAF_CONFIG/telegraf.d/gnmi.conf ]; then
        log "gnmi.conf is missing"
        sed -e "0,/^addresses\ =.*/s//$addresses/" \
            -e "0,/^username\ =.*/s//username\ = \"$gnmi_user\"/" \
            -e "0,/^password\ =.*/s//password\ = \"$gnmi_password\"/" \
            -e "0,/^token\ =.*/s//token\ = \"$INFLUXDB_INIT_TOKEN\"/" \
            $TELEGRAF_CONFIG/telegraf.d/gnmi.conf.example > $TELEGRAF_CONFIG/telegraf.d/gnmi.conf
        log "gnmi.conf has been generated from gnmi.conf.example template"
    fi

    if [ "$pull_image" = true ]; then
        log "pull the latest version of image $TELEGRAF_IMAGE"
        docker-compose pull telegraf
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

        log "install jq json processor in influxdb container"
        docker exec -t influxdb apt-get update -y && apt-get install jq -y

        log "influx config create"
        docker exec -t influxdb influx config create \
        --config-name telemetry_collector \
        --host-url http://127.0.0.1:8086 \
        --org $INFLUXDB_ORG \
        --token $INFLUXDB_INIT_TOKEN \
        --active 

        log "remove old influx-configs file"
	# below is for testing only when container is already up, configs won't be present, on new build
        docker exec -t influxdb rm /etc/influxdb2/influx-configs

	# below will generate /etc/influxdb2/influx-configs
        log "influx setup"
        docker exec -t influxdb influx setup \
        --org $INFLUXDB_ORG \
        --bucket $INFLUXDB_BUCKET \
        --username $INFLUXDB_USER \
        --password $INFLUXDB_PASSWD \
        --retention 2h \
        --force

        GENERATED_TOKEN=`docker exec influxdb influx auth list --user $INFLUXDB_USER --json | jq -r ".[] | .token"`
        echo "GENERATED_TOKEN = $GENERATED_TOKEN"

        GENERATED_ORG_ID=`docker exec influxdb influx org find -t $GENERATED_TOKEN --json | jq -r ".[] | .id"`
        echo "generated org id = $GENERATED_ORG_ID for $INFLUXDB_ORG"

        INITIAL_BUCKET_ID=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"$INFLUXDB_BUCKET\").id"`
        echo "$INFLUXDB_BUCKET id = $INITIAL_BUCKET_ID"

        userName=`docker exec influxdb influx auth list --user $INFLUXDB_USER --json | jq -r ".[] | .userName"`
        echo "userName = $userName"

        userID=`docker exec influxdb influx auth list --user $INFLUXDB_USER --json | jq -r ".[] | .id"`
        echo "userID for $userName = $userID"

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
    log "starting docker containers"
    echo $DOCKER_PASS | docker login -u$DOCKER_USER --password-stdin
    docker-compose up -d
    check_influxdb
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
        chronograf)
            docker-compose restart chronograf
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
