#!/usr/bin/env bash

export GRAFANA_VOLUME="grafana-volume"
export CHRONOGRAF_VOLUME="chronograf-volume"
export TELEGRAF_CONFIG="`pwd`/etc/telegraf"
export CHRONOGRAF_CONFIG="`pwd`/etc/chronograf"
export INFLUX_CONFIG="`pwd`/etc/influxdb"
export INFLUX_DATA="`pwd`/influxdb"
export CURRENT_UID=`id -u`
export CURRENT_GID=`id -g`

self=$0
INFLUX_USER="influxdb"
TELEGRAF_USER="telegraf"
TELEGRAF_CERT_PATH="$TELEGRAF_CONFIG/cert"
GNMI_CERT_PASSWD="cisco123"

# swtiches accept gNMI dial-in
switches=( \
    "172.25.74.70:50051" \ 
    "172.25.74.61:50051" \
    "172.25.74.87:50051" \ 
    "172.25.74.88:50051" \
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
    rm -rf $INFLUX_DATA
    log "remove generated gnmi config"
    rm -rf $TELEGRAF_CONFIG/gnmi_on_change.conf
    rm -rf $TELEGRAF_CONFIG/telegraf.d/gnmi.conf
    #log "deleting grafana volume $GRAFANA_VOLUME"
    #docker volume rm $GRAFANA_VOLUME
    log "deleting chronograf volume $CHRONOGRAF_VOLUME"
    docker volume rm $CHRONOGRAF_VOLUME
}

function prepare_grafana() {
    log "create docker volume $GRAFANA_VOLUME"
    docker volume create --name $GRAFANA_VOLUME
}

function prepare_chronograf() {
    docker volume inspect chronograf-volume 1>/dev/null 2>/dev/null
    if [ ! $? -eq 0 ]; then
        log "create docker volume $CHRONOGRAF_VOLUME"
        docker volume create --name $CHRONOGRAF_VOLUME
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
            generate_self_signed_cert $cn
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
    common_name=$1
    csr_config=$TELEGRAF_CERT_PATH/$common_name.csr.conf
    key_file=$TELEGRAF_CERT_PATH/$common_name.key
    csr_file=$TELEGRAF_CERT_PATH/$common_name.csr
    cert_file=$TELEGRAF_CERT_PATH/$common_name.crt
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
    if [ ! -d $INFLUX_DATA ]; then
        log "influxdb database folder is not existed, creating one"
        mkdir $INFLUX_DATA
    fi
    log "change permission of config and data folder of influxdb"
    #chown -R $INFLUX_UID:$INFLUX_GID $INFLUX_CONFIG
    #chown -R $INFLUX_UID:$INFLUX_GID $INFLUX_DATA
}

function prepare_telegraf() {
    # generate certificate if doesn't exist
    gen_telegraf_cert

    for a in ${swtiches[@]}; do
        echo "\" $a \" "
    done

    # Modify the addresses in gnmi config to the switches provided
    switch_list=`printf -- "\"%s\"," ${switches[*]} | cut -d "," -f 1-${#switches[@]}`
    addresses="addresses = [$switch_list]"

    # generate gnmi config file from example
    if [ ! -e $TELEGRAF_CONFIG/gnmi_on_change.conf ]; then
        sed -e "0,/^addresses\ =.*/s//$addresses/" \
            -e "0,/^username\ =.*/s//username\ = \"$gnmi_user\"/" \
            -e "0,/^password\ =.*/s//password\ = \"$gnmi_password\"/" \
            $TELEGRAF_CONFIG/gnmi_on_change.conf.example > $TELEGRAF_CONFIG/gnmi_on_change.conf
    fi

    if [ ! -e $TELEGRAF_CONFIG/telegraf.d/gnmi.conf ]; then
        sed -e "0,/^addresses\ =.*/s//$addresses/" \
            -e "0,/^username\ =.*/s//username\ = \"$gnmi_user\"/" \
            -e "0,/^password\ =.*/s//password\ = \"$gnmi_password\"/" \
            $TELEGRAF_CONFIG/telegraf.d/gnmi.conf.example > $TELEGRAF_CONFIG/telegraf.d/gnmi.conf
    fi
}
function check_influxdb () {
    # check if influxdb is ready for connection
    log "waiting for influxdb getting ready"
    while true; do
        result=`curl -w %{http_code} --silent --output /dev/null localhost:8086/ping`
        if [ $result -eq 204 ]; then
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
    sleep 3
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

function start() {
    docker --version >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        log "docker is not installed, exist"
        exit 1
    fi
    prepare_influxdb
    prepare_telegraf
    prepare_chronograf
    #prepare_grafana
    log "starting docker containers"
    docker-compose up -d
    check_influxdb
    post_chronograf
}

function stop(){
    log "stopping docker containers"
    docker-compose down
}

function reset () {
    # reset project to initial state
    stop
    clean
    # remove certificates
    rm -rf $TELEGRAF_CERT_PATH
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
            docker-compose restart telegraf2
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
    echo "  start  :   start docker service for telegraf/influxdb/grafana"
    echo "  stop   :   stop docker service for telegraf/influxdb/grafana"
    echo "  restart:   restart docker service for telegraf/influxdb/grafana"
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
