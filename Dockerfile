##################################################
# Dockerfile to build a confd image              #
# Version 0.1                                    #
##################################################
FROM alpine:3.3
LABEL confd_image.version="0.1" confd_image.release-date="2017-05-02"
MAINTAINER Carolina Santana "c.santanamartel@gmail.com"
RUN apk add --update curl && apk add --update jq && \
    curl -o /usr/bin/confd -L https://github.com/kelseyhightower/confd/releases/download/v0.7.1/confd-0.7.1-linux-amd64 && \
    chmod 755 /usr/bin/confd && rm -rf /var/cache/apk/*
ADD etc/confd/ /etc/confd
CMD /usr/bin/confd -interval=5 -node=http://$COREOS_PRIVATE_IPV4:4001

