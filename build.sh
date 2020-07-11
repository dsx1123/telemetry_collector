#!/usr/bin/env bash

self=$0
INFLUX_USER="influxdb"
TELEGRAF_USER="telegraf"
export GRAFANA_VOLUME="grafana-volume"
export GRAFANA_UID="472"  # default uid of grafana
export GRAFANA_GID="472"  # default gid of grafana
export TELEGRAF_CONFIG="`pwd`/etc/telegraf"
export INFLUX_CONFIG="`pwd`/etc/influxdb"
export INFLUX_DATA="`pwd`/influxdb"


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
    echo "$ts-LOG-$@"
}

function clean() {
    # clean database of influxdb and volume of grafana
    log "cleaning influxdb database"
    rm -rf $INFLUX_DATA
    log "deleting grafana volume"
    docker volume rm $GRAFANA_VOLUME

    #clean certificates
    log "cleaning certificates"
    for cn in $cn_mdt $cn_gnmi
    do
        rm -rf $cn.csr.conf
        rm -rf $TELEGRAF_CONFIG/$cn.csr
        rm -rf $TELEGRAF_CONFIG/$cn.key
        rm -rf $TELEGRAF_CONFIG/$cn.crt
    done

}

function prepare_grafana() {
    log "create docker volume $GRAFANA_VOLUME"
    docker volume create --name $GRAFANA_VOLUME
}

function gen_telegraf_cert() {
    log "gernerating self-signed certificates for telegraf plugins"
    generate_self_signed_cert $cn_mdt
    generate_self_signed_cert $cn_gnmi
}

function generate_self_signed_cert() {
    # create csr config file
    common_name=$1
    csr_config=./$common_name.csr.conf
    key_file=$TELEGRAF_CONFIG/$common_name.key
    csr_file=$TELEGRAF_CONFIG/$common_name.csr
    cert_file=$TELEGRAF_CONFIG/$common_name.crt
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
    log "getting uid gid of influxdb inside container"
    export INFLUX_UID=`docker run --rm -ti influxdb id -u $INFLUX_USER| tr -d '\r'`
    export INFLUX_GID=`docker run --rm -ti influxdb id -u $INFLUX_USER| tr -d '\r'`
    log "got user $INFLUX_USER id:$INFLUX_UID and gid:$INFLUX_GID"
    if [ ! -d $INFLUX_DATA ]; then
        log "influxdb database folder is not existed, creating one"
        mkdir $INFLUX_DATA
    fi
    log "change permission of config and data folder of influxdb"
    chown -R $INFLUX_UID:$INFLUX_GID $INFLUX_CONFIG
    chown -R $INFLUX_UID:$INFLUX_GID $INFLUX_DATA
}

function prepare_telegraf() {
    log "getting uid gid of telegraf inside container"
    export TELEGRAF_UID=`docker run --rm -ti telegraf id -u $TELEGRAF_USER| tr -d '\r'`
    export TELEGRAF_GID=`docker run --rm -ti telegraf id -u $TELEGRAF_USER| tr -d '\r'`
    log "got user $TELEGRAF_USER id:$TELEGRAF_UID and gid:$TELEGRAF_GID"

    log "change permission of config of telegraf"
    chown -R $TELEGRAF_UID:$TELEGRAF_GID $TELEGRAF_CONFIG
}

function start() {
    # generate certificate if doesn't exist
    for cn in $cn_mdt $cn_gnmi
    do
        if [ ! -e $TELEGRAF_CONFIG/$cn.key ] || [ ! -e $TELEGRAF_CONFIG/$cn.crt ]
        then
            log "$cn certificate does not exist, generating"
            generate_self_signed_cert $cn
        fi
    done

    prepare_influxdb
    prepare_telegraf
    prepare_grafana
    log "starting docker containers"
    docker-compose up -d
}

function stop(){
    log "stopping docker containers"
    docker-compose down
}

function display_help() {
    echo "Usage: $self {start|stop|restart|cert|clean}"
}

if [ $# -gt 1 ]; then
    display_help
fi

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    cert)
        gen_telegraf_cert
        ;;
    clean)
        clean
        ;;
    *)
        display_help
        exit 1
    esac
