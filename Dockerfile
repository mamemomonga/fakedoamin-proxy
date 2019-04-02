FROM alpine:3.8

RUN set -xe && \
	apk --update add \
		tinyproxy dnsmasq supervisor perl openssl && \
	rm -rf /var/cache/apk/*

ADD assets/ /

CMD ["/opt/startup.sh"]

