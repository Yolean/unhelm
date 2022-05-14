#!/usr/bin/env bash
set -x
set -e

echo "WARNING Current operator creates a statefulset with"
echo "  updateStrategy:"
echo "    type: OnDelete"
echo "which is an indication that it can no longer run without the operator"

echo "Please confirm that this is an ephemeral test cluster"
echo "For example: k3d cluster create redpanda --agents 3"
kubectl config current-context
read -p "Ok? [y/n] " ok && [ "$ok" = "y" ] || exit 1

# meant to run from the unhelp root dir
stat redpanda/redpanda-operator

kubectl create namespace cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.8.0/cert-manager.yaml
kubectl -n cert-manager rollout status deploy cert-manager
kubectl -n cert-manager rollout status deploy cert-manager-webhook

kubectl create namespace redpanda-system
kubectl apply -f redpanda/redpanda-operator-crd/redpanda-operator-crd.yaml
sleep 5
kubectl -n redpanda-system apply -k apply -k redpanda/redpanda-operator/
kubectl -n redpanda-system rollout status deploy unhelm-redpanda-operator

kubectl create namespace redpanda-example
for example in \
    development.yaml \
    notdevelopment.yaml \
    https://github.com/vectorizedio/redpanda/raw/dev/src/go/k8s/config/samples/one_node_cluster.yaml \
    https://github.com/vectorizedio/redpanda/raw/dev/src/go/k8s/config/samples/tls.yaml \
    https://github.com/vectorizedio/redpanda/raw/dev/src/go/k8s/config/samples/external_connectivity.yaml \
  ; do
  name=$(basename $example | cut -d. -f1)
  echo "# trying $name ..."

  exampledir=redpanda/examples/$name
  rm redpanda/examples/$name/* 2>/dev/null || true
  mkdir -p $exampledir

  if [ -f redpanda/examples/$example ]; then
    cp redpanda/examples/$example $exampledir/example.yaml
  else
    curl -L $example \
      | sed 's/^  name: .*/  name: redpanda/' \
      > $exampledir/example.yaml
  fi

  kubectl -n redpanda-example apply -f $exampledir/example.yaml
  sleep 5
  kubectl -n redpanda-example get service redpanda -o yaml > $exampledir/service.yaml
  kubectl -n redpanda-example get statefulset redpanda -o yaml > $exampledir/statefulset.yaml
  kubectl -n redpanda-example get configmap redpanda-base -o yaml > $exampledir/configmap.yaml
  replicas=$(kubectl -n redpanda-example get statefulset redpanda -o jsonpath='{.spec.replicas}')
  for i in $(seq 0 $((replicas - 1))); do
    kubectl -n redpanda-example wait --for=condition=Ready pod/redpanda-$i
    kubectl -n redpanda-example exec redpanda-$i -- cat /etc/redpanda/redpanda.yaml > $exampledir/redpanda-$i.yaml || echo "Failed to get config from pod $i"
  done
  kubectl -n redpanda-example delete -f $exampledir/example.yaml
done
