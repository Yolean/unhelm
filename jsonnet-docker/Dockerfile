FROM golang:1.17.4-alpine \
  as install

RUN apk add --no-cache git make

RUN go get github.com/google/go-jsonnet/cmd/jsonnet

RUN go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.4.0

RUN go get github.com/brancz/gojsontoyaml

RUN sha256sum /go/bin/*

FROM alpine:3.15 \
  as runner

RUN apk add --no-cache git make bash

COPY --from=install /go/bin/gojsontoyaml /usr/local/bin/gojsontoyaml
COPY --from=install /go/bin/jb /usr/local/bin/jb
COPY --from=install /go/bin/jsonnet /usr/local/bin/jsonnet

RUN jb -h 2>&1
RUN jsonnet -h
