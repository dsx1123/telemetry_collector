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

self=$0
TELEGRAF_USER="telegraf"
TELEGRAF_CERT_PATH="$TELEGRAF_CONFIG/cert"
GNMI_CERT_PASSWD="cisco123"
pull_image=false # pull required image every time start

# swtiches accept gNMI dial-in
switches=( "172.25.74.70:50051" \
           "172.25.74.61:50051" \
           "172.25.74.87:50051" \
           "172.25.74.88:50051" \
           "172.25.74.163:50051" \
)

# user on swtich for authentication, need network-operator role at least
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

    log "deleting grafana volume $CHRONOGRAF_VOLUME"
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


    # modify token of telegraf.conf
    if [ ! -e $TELEGRAF_CONFIG/telegraf.conf ]; then
        log "telegraf.conf is missing"
        sed -e "0,/^token\ =.*/s//token\ = \"$INFLUXDB_INIT_TOKEN\"/" \
            -e "0,/^urls\ =.*/s//$urls/" \
            $TELEGRAF_CONFIG/telegraf.conf.example > $TELEGRAF_CONFIG/telegraf.conf
    fi

    # generate gnmi config file from example
    if [ ! -e $TELEGRAF_CONFIG/telegraf.d/gnmi.conf ]; then
        log "gnmi.conf is missing"
        sed -e "0,/^addresses\ =.*/s//$addresses/" \
            -e "0,/^username\ =.*/s//username\ = \"$gnmi_user\"/" \
            -e "0,/^password\ =.*/s//password\ = \"$gnmi_password\"/" \
            -e "0,/^token\ =.*/s//token\ = \"$INFLUXDB_INIT_TOKEN\"/" \
            $TELEGRAF_CONFIG/telegraf.d/gnmi.conf.example > $TELEGRAF_CONFIG/telegraf.d/gnmi.conf
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

function post_chronograf () {
    log "wait for chronograf getting ready"
    while true; do
        result=`curl --write-out '%{http_code}' --silent --output /dev/null http://localhost:8888/chronograf/v1/sources`
        if [ $result -eq 200 ]; then
            log "chronograf is ready"
            break
        fi
        sleep 3
    done

    result=`curl --silent http://localhost:8888/chronograf/v1/sources`
    if [[ $result == *'"sources":[]'* ]]; then
        log "datasource is empty, creating datasource"
        result=`curl \
            --write-out '%{http_code}' \
            --silent \
            --output /dev/null \
            -X POST \
            -H "Content-Type: application/json" \
            -d @$CHRONOGRAF_CONFIG/datasource.json \
            http://localhost:8888/chronograf/v1/sources`
        if [ $result -eq 200 ]  || [ $result -eq 201 ]; then
            log "datasource influxdb is created!"
        else
            log "datasource influxdb is not created! api error: $result"
        fi
    fi
    result=`curl --silent http://localhost:8888/chronograf/v1/dashboards`
    if [[ $result == *'"dashboards":[]'* ]]; then
        log "no dashboards, importing prebuild dashboards"
        for d in "fabric_dashboard" "fabric_dashboard_gnmi" ; do
            result=`curl \
                --write-out '%{http_code}' \
                --silent \
                --output /dev/null \
                -X POST \
                -H "Content-Type: application/json" \
                -d @$CHRONOGRAF_CONFIG/$d.json \
                http://localhost:8888/chronograf/v1/dashboards`
            if [ $result -eq 200 ]  || [ $result -eq 201 ]; then
                log "dashboard $d is created!"
            else
                log "failed to create dashboard $d! api error: $result"
            fi
        done
    fi
}


#bucket_id=$(influx bucket list -n isardvdi |grep isardvdi | cut -f1)
#influx auth create --write-bucket $bucket_id -o isardvdi -d hypervisor_remote_bucket_token -u admin -t $INFLUXDB_ADMIN_TOKEN_SECRET
#influx auth create --write-bucket $bucket_id -o isardvdi -d hypervisor_remote_bucket_token -u isardvdi -t $INFLUXDB_ADMIN_TOKEN_SECRET
# influx config create -u ï¿½http:/localhost:8086ï¿½ -o ï¿½your-orgï¿½ -t ï¿½your-user-tokenï¿½


function setup_influxdb() {
    # initalize infludb
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
        docker exec -t influxdb rm /etc/influxdb2/influx-configs

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

        docker exec -t influxdb influx bucket create -n $INFLUXDB_MDT_BUCKET --org-id $GENERATED_ORG_ID -r 10h -t $GENERATED_TOKEN
        docker exec -t influxdb influx bucket create -n nxos_dialout_2 --org-id $GENERATED_ORG_ID -r 10h -t $GENERATED_TOKEN
        docker exec -t influxdb influx bucket create -n nxos_dialout_3 --org-id $GENERATED_ORG_ID -r 10h -t $GENERATED_TOKEN

        docker exec -t influxdb influx bucket find -t $GENERATED_TOKEN
        
        docker exec -t influxdb influx org list -t $GENERATED_TOKEN
        docker exec -t influxdb influx bucket list -t $GENERATED_TOKEN
        docker exec -t influxdb influx org members list -n Cisco -t $GENERATED_TOKEN
        docker exec -t influxdb influx user create -n sclake -o Cisco -t $GENERATED_TOKEN
        docker exec -t influxdb influx user list -n sclake -t $GENERATED_TOKEN
        
        #docker exec -t influxdb influx bucket create -n nxos_dialout_2 --org-id 8baee1c8d62442f2 -r 10h -t R5Zn_KPIzvZagC5bcL_sQU3pgAV3NZd6wCDeEK64FKzsLDIU9SLC-VDY3xyfExN2fdSN4qZR1yKGGFIVCPZldg==

        #docker exec -t influxdb influx org find -t oL87xTVEx7l769hJH29pHnk4GNQgfU-fiZ0-kHRzxwgWgt-CsERN7YMQnQXeO-TeZvG0g9aSYOn4c3Y9xQ-y4A==
        

        # docker exec influxdb influx auth create -o $INFLUXDB_ORG \
        #   --description grafana \
        #   --read-bucket $INFLUX_BUCKET_ID \
        #   --read-checks \
        #   --read-dashboards \
        #   --read-dbrps \
        #   --read-notificationEndpoints \
        #   --read-notificationRules \
        #   --read-orgs \
        #   --read-tasks \
        #   --read-telegrafs \
        #   --read-user \
        #   --json | jq -r '.["token"]' | tee ../grafana.token.txt


        #  create second bucket for mdt dialout
        #  log "influx bucket create"
        #  docker exec -t influxdb influx bucket create \
        #  --name $INFLUXDB_MDT_BUCKET \
        #  --org $INFLUXDB_ORG \
        #  --token $INFLUXDB_INIT_TOKEN \
        #  --host http://127.0.0.1:8086 \
        #  --retention 2h \
        #  --skip-verify

        #docker exec -t influxdb influx -t $INFLUXDB_INIT_TOKEN bucket create -o $INFLUXDB_ORG -r 72h --name $INFLUXDB_MDT_BUCKET

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
