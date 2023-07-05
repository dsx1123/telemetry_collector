# telemetry_collector
Automatically build telemetry collector with [Telegraf](https://github.com/influxdata/telegraf), [Influxdb](https://github.com/influxdata/influxdb), and [Grafana](https://github.com/grafana/grafana), the example of sensor paths is using the native yang model and OpenConfig yang model of NX-OS as an example. `build.sh` script will create self-signed certificates for TLS transport. Using docker images of Telegraf, Influxdb, and Grafana to create containers with docker-compose. tested with `telegraf >= 1.12.1`, `influxdb >= 2.0` and `grafana>=8.1`.

# NOTE:
This project has upgraded the Influxdb to 2.0 which is not supported by Chronograf anymore, the dashboard is changed to Grafana with a new set of sensor paths. original code is moved to branch [chronograf_influxdb_1_x](https://github.com/dsx1123/telemetry_collector/tree/chronograf_influxdb_1_x)
# Screenshoot
![gnmi dashboard](https://github.com/dsx1123/telemetry_collector/blob/master/examples/gnmi.png?raw=true)
## Requirements:
docker-ce, OpenSSL, docker-compose, any Linux distribution, see Known Issues if trying it on MacOS
## How to use

 1. To quickly start, set environment variables `GNMI_USER` and `GNMI_PASSWORD`, this user needs to be configured on nxos with a network-operator role at least, then use `sudo ./build.sh start` to start the containers:
    ```bash
    export GNMI_USER=telemetry
    export GNMI_PASSWORD=SuperSecretPassword
    ./build.sh start
    ```
    ```
    2020-07-30T22:49:02--LOG--influxdb database folder does not exist, creating one
    2020-07-30T22:49:02--LOG--change permission of config and data folder of influxdb
    2020-07-30T22:49:02--LOG--generating self-signed certificates for telegraf plugins
    2020-07-30T22:49:02--LOG--telegraf certificate does not exist, generating
    2020-07-30T22:49:02--LOG--gernerating private key for CN telegraf
    ...<ommited>
    ```

    By default, telegraf listens on `tcp:57000` for gRPC dial-out, if you want to modify the port, change the config file `etc/telegraf/telegraf.conf.example` in the project folder

    gnmi dial-in is also enabled by default,  modify the `switches` in `build.sh` with mgmt address and grpc port:

    ```ini
    # swtiches accept gNMI dial-in
    switches=( "172.25.74.70:50051" "172.25.74.61:50051" )
    ```
    When first starting the service, the script will check if certificates are generated, if not, it will create them for mdt and gnmi plugins to validate for 10 years.
    use `http://<ip_address_of_host>:3000 ` to open Grafana gui. login is `grafana/cisco123`

2. TLS is enabled on cisco_telemetry_mdt plugin, comment below lines in `etc/telegraf/telegraf.conf` to disable it:
    ```ini
    # uncomment below to enable tls for dial-out plguin
    tls_cert = "/etc/telegraf/cert/telegraf.crt"
    tls_key = "/etc/telegraf/cert/telegraf.key"
    ```
    certificate `./etc/telegraf/cert/telegraf.crt` need be copied to nx-os to verify the collector's identity, then use the below command to enable TLS transport for the destination group, the `<certificate name>`  needs to match the common name of `telegraf.crt`, it is set to `telegraf` in `build.sh`:
    ```
    switch(config)# telemetry
    switch(config-telemetry)# destination-group 1
    switch(conf-tm-dest)# ip address <collector address> port 57000 protocol gRPC encoding GPB
    switch(conf-tm-dest)# certificate /bootflash/telegraf.crt <certificate name>

    ```

3. TLS need to be enabled for the gNMI plugin as well as nx-os, when configuring feature gRPC on a switch, a default certificate with 1-day validation is auto-generated, to configure the certificate for gRPC on nx-os, copy `etc/telegraf/cert/gnmi.pfx` to bootflash, then use below commands to import the certificate, the `<export password>` is set to `cisco123` by default, you could modify it in `build.sh`, these steps are optional as the gnmi plugin in telegraf is set to disable certificate verification. 
    ```
    switch(config)# crypto ca trustpoint gnmi_trustpoint
    switch(config-trustpoint)# crypto ca import gnmi_trustpoint pkcs12 bootflash:gnmi.pfx <export password>
    switch(config)# grpc certificate gnmi_trustpoint
    ```

4. This tool will import a couple of pre-built dashboards:
   -  The `fabric dashboard dialout` is an example of querying data from telemetry dial-out, you can find the example of the switch telemetry config that is used for this dashboard in [telemetry.cfg](/examples/telemetry.cfg).
   -  The `fabric dashboard gnmi` is an example of querying data from gNMI dial-in.
   -  The `Endpoints` shows the arp tables and Mac address tables of all the switches.
   -  The `Interface Counters` shows all kinds of interface counters that is collected using the Openconfig model.
   -  The `System Capacity` shows the current system utilization of NX-OS using metric collected from [icam](https://www.cisco.com/c/en/us/td/docs/dcn/nx-os/nexus9000/103x/configuration/icam/cisco-nexus-9000-series-nx-os-icam-configuration-guide-release-103x.html)

6. Example of telegraf configuration can be found below:
   - [telegraf.conf.example](etc/telegraf/telegraf.conf.example) example of cisco_telemetry_mdt config
   - [gnmi.conf.example](etc/telegraf/telegraf.d/gnmi.conf.example) exmaple of gnmi plugin config

## Known issue
1. Before NX-OS 10.1(1), a single subscription of gNMI dial-in can only be SAMPLE or ON_CHANGE, not both. In order to configure different types of subscriptions, need to start two telegraf instances to separate SAMPLE and ON_CHANGE sensor paths.
Please take a look at enhancement [CSCvu58102](https://bst.cloudapps.cisco.com/bugsearch/bug/CSCvu58102) for detail.
2. MacOS uses the BSD version of sed by default which doesn't work with this script, use `brew install gnu-sed` to install the gnu version of sed if you are trying this script on MacOS.

## Reference
1. [Cisco Nexus 9000 Series NX-OS Programmability Guide, Release 10.3(x)](https://www.cisco.com/c/en/us/td/docs/dcn/nx-os/nexus9000/103x/programmability/cisco-nexus-9000-series-nx-os-programmability-guide-release-103x.html)
