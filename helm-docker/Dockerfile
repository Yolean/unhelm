FROM alpine:3.9@sha256:28ef97b8686a0b5399129e9b763d5b7e5ff03576aa5580d6f4182a49c5fe1913 \
  as runner

ENV \
  HELM_VERSION=v2.13.1 \
  HELM_TGZ_SHA256=c1967c1dfcd6c921694b80ededdb9bd1beb27cb076864e58957b1568bc98925a

RUN set -e; \
  apk add --no-cache git curl; \ 
  curl -o helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz; \
  echo "${HELM_TGZ_SHA256}  helm.tar.gz" | sha256sum -c -; \
  tar -zxvf helm.tar.gz; \
  mv linux-amd64/helm /usr/local/bin/helm; \
  rm -rf helm.tar.gz linux-amd64; \
  \
  helm init --client-only;
