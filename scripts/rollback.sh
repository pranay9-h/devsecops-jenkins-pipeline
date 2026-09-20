#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-devsecops-demo}"
DEPLOYMENT="${DEPLOYMENT:-sample-api}"

echo "Rolling back deployment/${DEPLOYMENT} in namespace ${NAMESPACE}..."
kubectl -n "${NAMESPACE}" rollout undo "deployment/${DEPLOYMENT}"
kubectl -n "${NAMESPACE}" rollout status "deployment/${DEPLOYMENT}" --timeout=180s
echo "Rollback completed."
