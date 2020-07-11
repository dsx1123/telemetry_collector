# telemetry_collector
Automatically build telemetry collector with telegraf, influxdb and grafana, `build.sh` script will create self-signled cerificates for TLS transport. Using docker images of telegraf, influxdb and grafana to create services using docker-compose. tested with `telegraf>=1.12.1`, `influxdb>=1.8.0` and `gafana>=7.0.5`.
