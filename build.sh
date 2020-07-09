#!/usr/bin/env bash

self=$0
INFLUX_USER="influxdb"
TELEGRAF_USER="telegraf"
export GRAFANA_VOLUME="grafana-volume"
export GRAFANA_UID="472"  # default uid of grafana
export TELEGRAF_CONFIG="`pwd`/etc/telegraf"
export INFLUX_CONFIG="`pwd`/etc/influxdb"
export INFLUX_DATA="`pwd`/influxdb"


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
}

function prepare_grafana() {
    log "create docker volume $GRAFANA_VOLUME"
    docker volume create --name $GRAFANA_VOLUME
}

function prepare_influxdb() {
    log "getting uid gid of influxdb of container"
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

function start() {
    prepare_influxdb
    prepare_grafana
    log "starting docker containers"
    docker-compose up -d 
}

function stop(){
    log "stopping docker containers"
    docker-compose down
}

function display_help() {
    echo "Usage: $self {start|stop|restart|clean}"
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
    clean)
        clean
        ;;
    *)
        display_help
        exit 1
    esac
