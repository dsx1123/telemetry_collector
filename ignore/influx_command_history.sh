vagrant@telemetry-collector:/vagrant$ history
    1  docker exec -it telegraf /bin/sh
    2  docker exec -t influxdb influx org create -n telegraf
    3  docker exec -t influxdb influx bucket create -n telegraf -o telegraf -r 72h
    4  docker exec -t influxdb bucketId=`influx -o telegraf bucket list|grep telegraf|awk '{print $1}'`
    5  bucketId=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"telegraf\").id"`
    6  docker exec influxdb influx bucket list --json
    7  docker exec -t influxdb influx bucket create -n telegraf -o telegraf -r 72h
    8  docker exec -t influxdb influx bucket -help
    9  docker exec -t influxdb influx bucket -h
   10  docker exec -t influxdb influx bucket list -h
   11  docker exec -t influxdb influx bucket list -t -h
   12  docker exec -t influxdb influx bucket list
   13  docker exec -t influxdb influx bucket delete telegraf
   14  docker exec -t influxdb influx bucket delete -h
   15  docker exec -t influxdb influx bucket delete -n telegraf
   16  docker exec -t influxdb influx bucket delete -n -hel[
   17  docker exec -t influxdb influx bucket delete -n -help
   18  docker exec -t influxdb influx bucket -h
   19  docker exec -t influxdb influx bucket delete -h
   20  docker exec -t influxdb influx bucket delete -n telegraf
   21  docker exec -t influxdb influx bucket create -n telegraf -o telegraf -r 72h
   22  docker exec -t influxdb influx bucket create -h
   23  bucketId=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"gnmi\").id"`
   24  bucketId=`docker exec influxdb influx bucket list --json
   25  docker exec influxdb influx bucket list --json
   26  bucketId=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"nxos_gnmi\").id"`
   27  docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"telegraf\").id"
   28  docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"tasks\").id"
   29  docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"$INFLUXDB_BUCKET\").id"
   30  echo "docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"$INFLUXDB_BUCKET\").id"
   31  docker         INITIAL_BUCKET_ID=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"$INFLUXDB_BUCKET\").id"`exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"$INFLUXDB_BUCKET\").id"
   32  bucketId=`docker exec influxdb influx bucket list --json
   33  docker exec influxdb influx bucket list --json
   34  docker exec -t influxdb influx org list
   35  docker exec -t influxdb influx org find
   36  docker exec -t influxdb influx org find --json
   37  docker exec -t influxdb influx org find --json | jq -r ".[] | select(.name==\"telegraf\").id"
   38  docker exec -t influxdb influx bucket create -n telegraf -o telegraf -r 72h
   39  bucketId=`docker exec influxdb influx bucket list --json | jq -r ".[] | select(.name==\"nxos_gnmi\").id"`
   40  docker exec -t influxdb influx bucket delete
   41  docker exec -t influxdb influx bucket delete telegraf
   42  docker exec -t influxdb influx bucket delete -n
   43  docker exec -t influxdb influx bucket delete -name telegraf
   44  docker exec -t influxdb influx bucket delete -h
   45  docker exec influxdb influx bucket list --json
   46  pwd
   47  cd /vagrant
   48  build.sh restart influxdb
   49  ./build.sh restart influxdb
   50  docker exec influxdb influx bucket list --json
   51  docker exec -t influxdb influx bucket create -n telegraf -o telegraf -r 72h
   52  docker exec -t influxdb influx bucket create -n telegraf2 -o telegraf -r 72h
   53  docker exec influxdb influx bucket list --json
   54  docker exec -t influxdb influx bucket create -n telegraf2 -o telegraf -r 72h
   55  docker exec influxdb influx bucket list --json
   56  history
vagrant@telemetry-collector:/vagrant$


   51  docker exec -t influxdb influx bucket create -n telegraf -o telegraf -r 72h
   52  docker exec -t influxdb influx bucket create -n telegraf2 -o telegraf -r 72h
   59  docker exec influxdb influx bucket list -o telegraf
   60  docker exec influxdb influx bucket delete -n telegraf -o telegraf
   61  docker exec influxdb influx bucket delete -n telegraf2 -o telegraf



  telegraf:
    # Full tag list: https://hub.docker.com/r/library/telegraf/tags/
    build:
      context: ./images/telegraf/
      dockerfile: ./${TYPE}/Dockerfile
      args:
        TELEGRAF_TAG: ${TELEGRAF_TAG}
    image: "telegraf"
    environment:
      HOSTNAME: "telegraf-getting-started"
    # Telegraf requires network access to InfluxDB
    links:
      - influxdb
    volumes:
      # Mount for telegraf configuration
      - ./telegraf/:/etc/telegraf/
      # Mount for Docker API access
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - influxdb



