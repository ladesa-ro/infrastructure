#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "uso: $0 <tipo> <nome> <namespace>" >&2
  exit 1
fi

TIPO="$1"
NOME="$2"
NAMESPACE="$3"

kubectl get "$TIPO" "$NOME" -n "$NAMESPACE" -o json \
  | jq 'del(
      .metadata.creationTimestamp,
      .metadata.resourceVersion,
      .metadata.uid,
      .metadata.generation,
      .metadata.selfLink,
      .metadata.managedFields,
      .metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"],
      .metadata.annotations["deployment.kubernetes.io/revision"],
      .status
    )'
