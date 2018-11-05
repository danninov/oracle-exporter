FROM golang:stretch AS builder

RUN apt-get -qq update && \
    apt-get install --no-install-recommends --allow-unauthenticated -qq libaio1 rpm wget && \
    wget --no-check-certificate https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm && \
    wget --no-check-certificate https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm && \
    rpm -Uvh --nodeps oracle*rpm && \
    echo /usr/lib/oracle/12.2/client64/lib | tee /etc/ld.so.conf.d/oracle.conf && \
    ldconfig

COPY oci8.pc /usr/share/pkgconfig/oci8.pc
RUN go get -d github.com/freenetdigital/prometheus_oracle_exporter
RUN cd $GOPATH/src/github.com/freenetdigital/prometheus_oracle_exporter/ && GOOS=linux go build -ldflags "-s -w" -o /app .

FROM ubuntu:18.04
MAINTAINER Seth Miller <seth@sethmiller.me>
RUN apt-get -qq update && \
    apt-get install --no-install-recommends -qq libaio1 rpm wget -y && \
    wget --no-check-certificate https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm && \
    rpm -Uvh --nodeps oracle*rpm && \
    rm -f oracle*rpm && \
    apt-get remove -y rpm && \
    apt-get -y autoremove && apt-get -y autoclean && rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH /usr/lib/oracle/12.2/client64/lib
ENV NLS_LANG=AMERICAN_AMERICA.UTF8

COPY --from=builder /app /

ARG CONFD_VERSION="0.15.0"
ADD https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 /usr/bin/confd
ADD entrypoint.sh /
RUN chmod +x /usr/bin/confd /entrypoint.sh

#Add confd templates
RUN mkdir -p /etc/confd/conf.d && mkdir -p /etc/confd/templates
ADD ./conf.d /etc/confd/conf.d
ADD ./templates /etc/confd/templates

EXPOSE 9161
ENTRYPOINT ["/entrypoint.sh"]
