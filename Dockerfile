FROM golang:1.19.6-alpine3.17 as builder

ADD ./ /build/

WORKDIR /build

ENV GO111MODULE=on \
    GOPROXY=https://goproxy.cn,direct

RUN go mod tidy \
    && CGO_ENABLED=0 go build -o app main.go

FROM alpine:3.17.2

RUN mkdir -p /opt/go/config \
    && apk add tzdata\
    && PATH="/usr/local/bin:$PATH" \
    && export PATH

ENV TZ=Asia/Shanghai

COPY --from=builder /build/app /usr/local/bin

RUN chmod +x /usr/local/bin/app
COPY --from=builder /build/config/config.yaml /opt/go/config

RUN addgroup boot -g 1337 && adduser -D -h /opt/go -u 1337 -s /bin/ash boot -G boot

USER boot
WORKDIR /opt/go

EXPOSE 8080
CMD ["/bin/sh", "-c" ,"app --config /opt/go/config/config.yaml"]