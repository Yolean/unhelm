FROM golang:1.12.4-alpine \
  as install

RUN apk add --no-cache git make

#ENV GO111MODULE=on
#RUN go get github.com/google/go-jsonnet/cmd/jsonnet@v0.12.1
RUN go get github.com/google/go-jsonnet/cmd/jsonnet

ENV GO111MODULE=on
RUN go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.1.0

RUN sha256sum /go/bin/*

FROM alpine:3.9@sha256:28ef97b8686a0b5399129e9b763d5b7e5ff03576aa5580d6f4182a49c5fe1913 \
  as runner

RUN apk add --no-cache git make

COPY --from=install /go/bin/jb /usr/local/bin/jb
COPY --from=install /go/bin/jsonnet /usr/local/bin/jsonnet

RUN jb -h 2>&1
RUN jsonnet -h
