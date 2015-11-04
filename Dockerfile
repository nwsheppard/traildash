FROM ubuntu:14.04
MAINTAINER AppliedTrust

RUN apt-get update && apt-get -y install openjdk-7-jre-headless wget git golang \
    build-essential python-pip curl && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN wget -q -O /usr/src/elasticsearch.deb https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.deb \
    && dpkg -i /usr/src/elasticsearch.deb

#
RUN echo "# CORS settings:\nhttp.cors.enabled: true\nhttp.cors.allow-origin: true\n" >> /etc/elasticsearch/elasticsearch.yml
RUN git clone https://github.com/nwsheppard/traildash.git /tmp
WORKDIR /tmp

RUN export GOPATH=/tmp && export PATH=$GOPATH/bin:$PATH && go get github.com/robfig/glock \
    && go get github.com/jteeuwen/go-bindata && go get -d github.com/nwsheppard/traildash \
    && glock sync github.com/nwsheppard/traildash \
    && cd src/github.com/jteeuwen/go-bindata/go-bindata/ && go build && \
    scp go-bindata $GOPATH/bin/ && cd $GOPATH && make && go get github.com/aws/aws-sdk-go/service/ec2 \
    && make dist

RUN mkdir /usr/local/traildash
RUN cp dist/linux/amd64/traildash /usr/local/traildash/traildash

#
RUN cp assets/start /root/start
RUN chmod 755 /root/start /usr/local/traildash/traildash

# Clean up
RUN apt-get -y purge git golang build-essential python-pip curl
RUN apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /

EXPOSE 7000
CMD ["/root/start"]
