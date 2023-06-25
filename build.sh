#!/usr/bin/env bash
[ -z "$DEBUG" ] || set -x
set -eo pipefail

mkdir -p generated

! (helm version | grep -v v3.12)

for VALUES in *.values.yaml; do
  echo "=> $VALUES"
  ./unhelm.sh $VALUES
  echo ""
done
