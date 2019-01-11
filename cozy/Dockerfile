FROM golang:1.11-alpine3.8 AS builder-go
RUN apk add --update git
RUN go get -v -ldflags '-X github.com/cozy/cozy-stack/pkg/config.BuildMode=production' github.com/cozy/cozy-stack

FROM alpine:3.8 AS builder-nsjail
RUN apk add --update git build-base bison flex linux-headers bsd-compat-headers protobuf-dev
COPY ./nsjail.patch /
RUN git clone --depth=1 --branch=2.8 https://github.com/google/nsjail.git \
	&& cd /nsjail \
	&& patch -p1 < /nsjail.patch \
	&& make

FROM alpine:3.8
RUN apk add --update git imagemagick
RUN mkdir -p /usr/share/cozy/ \
	&& wget https://github.com/cozy/debian-cozy/blob/master/konnector-nsjail-run.sh -O /usr/share/cozy/konnector-nsjail-run.sh \
	&& chmod +x /usr/share/cozy/konnector-nsjail-run.sh
COPY --from=builder-go /go/bin/cozy-stack /usr/local/bin/
COPY --from=builder-nsjail /nsjail/nsjail /usr/local/bin/
COPY ./cozy.yaml /etc/cozy/
EXPOSE 8080
VOLUME /etc/cozy/ /var/lib/cozy/
ENV COZY_COUCHDB_URL=http://couchdb:5984 \
	COZY_MAIL_HOST=mailhog \
	COZY_MAIL_PORT=1025
CMD ["/usr/local/bin/cozy-stack", "serve", "--allow-root"]
