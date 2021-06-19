FROM docker.io/yolean/builder-base:d7f3df65d07364f6fa700cd3dd437fcaf4d166fc@sha256:4f1b977e2c05b155a27d5ea3ae4db596ba1a1e358b26e02bfd501b13bf02aa0a

WORKDIR /tmp

RUN curl -o helm.tgz -L https://get.helm.sh/helm-v3.6.1-linux-amd64.tar.gz

RUN echo "c64f2c7b1d00c5328b164cea4bbd5e0752c103193037173c9eadea9d6a57eddb helm.tgz" | sha256sum -c -

RUN tar xvzf helm.tgz

FROM docker.io/yolean/builder-base:d7f3df65d07364f6fa700cd3dd437fcaf4d166fc@sha256:4f1b977e2c05b155a27d5ea3ae4db596ba1a1e358b26e02bfd501b13bf02aa0a

COPY --from=0 /tmp/linux-amd64/helm /usr/local/src/ystack/bin/helm
