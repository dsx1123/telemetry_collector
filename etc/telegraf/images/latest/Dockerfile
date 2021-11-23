FROM telegraf:latest

USER root
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        curl tcpdump mc
      
RUN mv /usr/sbin/tcpdump /usr/bin/tcpdump


