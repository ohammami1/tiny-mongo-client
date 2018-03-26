FROM alpine:3.7

RUN apk add --no-cache  \
	mongodb \
	bash \
	&& rm /usr/bin/mongoperf

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["sh", "-c", "'/entrypoint.sh'"]

