#!/bin/sh

# The goal here is to replace
# https://github.com/knative/docs/blob/master/docs/install/installing-istio.md
# with
#kubectl apply -k istio/crds/
#kubectl apply -k istio/namespace/
#kubectl apply -f istio/knative-lean/

export ISTIO_VERSION=1.1.11

curl -sLS -o istio.tar.gz https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istio-$ISTIO_VERSION-linux.tar.gz
tar xvzf istio.tar.gz && rm istio.tar.gz

mkdir -p istio/{namespace,crds,knative-lean,ingress}

cat <<EOF > istio/namespace/istio-system-injection-disabled.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
  labels:
    istio-injection: disabled
EOF

cp -v istio-$ISTIO_VERSION/install/kubernetes/helm/istio-init/files/crd*.yaml istio/crds/

# A lighter template, with just pilot/gateway.
# Based on install/kubernetes/helm/istio/values-istio-minimal.yaml
helm template --namespace=istio-system \
  --set prometheus.enabled=false \
  --set mixer.enabled=false \
  --set mixer.policy.enabled=false \
  --set mixer.telemetry.enabled=false \
  `# Pilot doesn't need a sidecar.` \
  --set pilot.sidecar=false \
  --set pilot.resources.requests.memory=128Mi \
  `# Disable galley (and things requiring galley).` \
  --set galley.enabled=false \
  --set global.useMCP=false \
  `# Disable security / policy.` \
  --set security.enabled=false \
  --set global.disablePolicyChecks=true \
  `# Disable sidecar injection.` \
  --set sidecarInjectorWebhook.enabled=false \
  --set global.proxy.autoInject=disabled \
  --set global.omitSidecarInjectorConfigMap=true \
  `# Set gateway pods to 1 to sidestep eventual consistency / readiness problems.` \
  --set gateways.istio-ingressgateway.autoscaleMin=1 \
  --set gateways.istio-ingressgateway.autoscaleMax=1 \
  `# Set pilot trace sampling to 100%` \
  --set pilot.traceSampling=100 \
  istio-$ISTIO_VERSION/install/kubernetes/helm/istio \
  > ./istio/knative-istio-lean.yaml

helm template --namespace=istio-system \
  --set prometheus.enabled=false \
  --set mixer.enabled=false \
  --set mixer.policy.enabled=false \
  --set mixer.telemetry.enabled=false \
  `# Pilot doesn't need a sidecar.` \
  --set pilot.sidecar=false \
  --set pilot.resources.requests.memory=128Mi \
  `# Disable galley (and things requiring galley).` \
  --set galley.enabled=false \
  --set global.useMCP=false \
  `# Disable security / policy.` \
  --set security.enabled=false \
  --set global.disablePolicyChecks=true \
  `# Disable sidecar injection.` \
  --set sidecarInjectorWebhook.enabled=false \
  --set global.proxy.autoInject=disabled \
  --set global.omitSidecarInjectorConfigMap=true \
  `# Set gateway pods to 1 to sidestep eventual consistency / readiness problems.` \
  --set gateways.istio-ingressgateway.autoscaleMin=1 \
  --set gateways.istio-ingressgateway.autoscaleMax=1 \
  `# Set pilot trace sampling to 100%` \
  --set pilot.traceSampling=100 \
  istio-$ISTIO_VERSION/install/kubernetes/helm/istio \
  --output-dir=istio/knative-lean \
  | tee istio/helm-output-knative-lean

rm -r istio-$ISTIO_VERSION

cat << EOF > istio/knative-lean/kustomization.yaml
resources:
EOF
cat istio/helm-output-knative-lean \
  | sed "s|wrote istio/knative-lean/|- |" \
  >> istio/knative-lean/kustomization.yaml
rm istio/helm-output-knative-lean

cat << EOF > istio/crds/kustomization.yaml
resources:
EOF
find istio/crds -name *.yaml \
  | grep -v kustomization.yaml \
  | sed "s|istio/crds/|- |" \
  >> istio/crds/kustomization.yaml

cat << EOF > istio/namespace/kustomization.yaml
resources:
- istio-system-injection-disabled.yaml
EOF
