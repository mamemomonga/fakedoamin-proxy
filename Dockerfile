FROM alpine:3.12

RUN set -xe && \
	apk --update add \
		tinyproxy \
		dnsmasq \
		nginx \
		supervisor \
		curl \
		perl \
		perl-yaml \
		openssl && \
	rm -rf /var/cache/apk/*

RUN set -xe && \
	mkdir -p /opt/certs && \
	mkdir -p /run/nginx

ADD assets/ /

ENTRYPOINT ["/opt/startup.pl"]

