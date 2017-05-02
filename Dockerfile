##################################################
# Dockerfile to build a confd image #
# Version 0.1                                    #
##################################################
FROM ubuntu:14.04
LABEL confd_image.version="0.1" confd_image.release-date="2017-05-02"
MAINTAINER Carolina Santana "c.santanamartel@gmail.com"
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl && \
    curl -o /usr/bin/confd -L https://github.com/kelseyhightower/confd/releases/download/v0.7.1/confd-0.7.1-linux-amd64 && \
    chmod 755 /usr/bin/confd && \
    apt-get autoclean && apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -f /tmp/* /var/tmp/*
ADD etc/confd/ /etc/confd
CMD /usr/bin/confd -interval=5 -node=http://$COREOS_PRIVATE_IPV4:4001

