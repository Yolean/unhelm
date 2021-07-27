#!/usr/bin/env bash
set -x
set -e

echo "Please confirm that this is an ephemeral test cluster"
kubectl context current-context
read -p "Ok? [y/n] " ok && [ "$ok" = "y" ] || exit 1

# meant to run from the unhelp root dir
stat redpanda/redpanda-operator

kubectl create namespace cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.1/cert-manager.yaml
kubectl -n cert-manager rollout status deploy cert-manager
kubectl -n cert-manager rollout status deploy cert-manager-webhook

kubectl create namespace redpanda-system
kubectl apply -f redpanda/redpanda-operator-crd/redpanda-operator-crd.yaml
kubectl -n redpanda-system apply -k apply -k redpanda/redpanda-operator/
kubectl -n redpanda-system rollout status deploy unhelm-redpanda-operator

kubectl create namespace redpanda-example
for example in \
    https://github.com/vectorizedio/redpanda/raw/dev/src/go/k8s/config/samples/one_node_cluster.yaml \
    https://github.com/vectorizedio/redpanda/raw/dev/src/go/k8s/config/samples/tls.yaml \
    https://github.com/vectorizedio/redpanda/raw/dev/src/go/k8s/config/samples/external_connectivity.yaml \
  ; do
  name=$(basename $example | cut -d. -f1)
  echo "# trying $name ..."
  
  exampledir=redpanda/examples/$name
  rm -r $exampledir 2>/dev/null || true
  mkdir -p $exampledir
  
  curl -L $example \
    | sed 's/^  name: .*/  name: redpanda/' \
    > $exampledir/example.yaml

  kubectl -n redpanda-example apply -f $exampledir/example.yaml
  sleep 5
  kubectl -n redpanda-example rollout status statefulset redpanda
  kubectl -n redpanda-example get service redpanda -o yaml > $exampledir/service.yaml
  kubectl -n redpanda-example get statefulset redpanda -o yaml > $exampledir/statefulset.yaml
  kubectl -n redpanda-example get configmap redpanda-base -o yaml > $exampledir/configmap.yaml
  for i in $(seq 0 2); do
    kubectl -n redpanda-example exec redpanda-$i -- cat /etc/redpanda/redpanda.yaml > $exampledir/redpanda-$i.yaml || echo "Failed to get config from pod $i"
  done
  kubectl -n redpanda-example delete -f $exampledir/example.yaml
done
