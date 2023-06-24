#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

HDIR="$PWD/helm"
export HELM_CACHE_HOME="$HDIR/cache"
export HELM_CONFIG_HOME="$HDIR/config"
export HELM_DATA_HOME="$HDIR/data"
export HELM_REPOSITORY_CACHE="$HDIR/repository"
export HELM_REPOSITORY_CONFIG="$HDIR/repositories.yaml"

[ $# -eq 0 ] && >&2 echo "First arg must be a value file path" && exit 1
VALUES=$1

CHART=$(echo $VALUES | cut -d'.' -f1)
NAME=$(echo $VALUES | cut -d'.' -f2)
REPO=$(cat $VALUES | grep '^# unhelm-template-repo:' | cut -d' ' -f3)
echo "=> repo=$REPO chart=$CHART name=$NAME"

helm repo add $CHART.$NAME $REPO
helm repo update
helm show chart $CHART.$NAME/$CHART

BASE="./$CHART/$NAME"
echo "$BASE" | grep '//' || rm -r "./$BASE" 2>/dev/null || true
mkdir -p $BASE

cat << EOF > $BASE/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
EOF

helm template $NAME $CHART.$NAME/$CHART -f $VALUES \
    --namespace unhelm-namespace-placeholder \
    --output-dir $BASE \
    | sed "s|wrote $BASE/|- ./|" \
    | sort | uniq \
    | tee -a $BASE/kustomization.yaml
