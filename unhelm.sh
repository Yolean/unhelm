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

IREPO="# unhelm-template-repo:"

CHART=$(echo $VALUES | cut -d'.' -f1)
NAME=$(echo $VALUES | cut -d'.' -f2)
! grep "^$IREPO" $VALUES && echo "Failed to find \"$IREPO \" in $VALUES" && exit 1
REPO=$(cat $VALUES | grep "^$IREPO" | cut -d' ' -f3)
echo "=> repo=$REPO chart=$CHART name=$NAME"

ORIGIN=$(echo $REPO | sed 's|.*://||' | sed 's|/$||' | sed 's|/|-|')

helm repo add $ORIGIN $REPO
helm repo update
helm show chart $ORIGIN/$CHART | grep ersion

BASE="./$CHART/$NAME"
echo "$BASE" | grep '//' || rm -r "./$BASE" 2>/dev/null || true
mkdir -p $BASE

echo "=> Generating a Kustomize base"

cat << EOF > $BASE/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
EOF

helm template $NAME $ORIGIN/$CHART -f $VALUES \
    --namespace unhelm-namespace-placeholder \
    --output-dir $BASE \
    | sed "s|wrote $BASE/|- ./|" \
    | sort | uniq \
    | tee -a $BASE/kustomization.yaml

echo "=> Looking for namespace references"

mkdir -p .namespace-test
cat << EOF > .namespace-test/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: unhelm-namespace-replaced
resources:
- .$BASE
EOF

NSINFO=$BASE/unhelm-namespace-placeholder.txt
cat << EOF > $NSINFO

Note the following instances of namespace strings that Kustomize won't replace
=============================================================================

EOF
kustomize build .namespace-test | grep -C 5 unhelm-namespace-placeholder >> $NSINFO || true
cat $NSINFO | grep unhelm-namespace-placeholder | wc -l || true
echo "=> Done"
