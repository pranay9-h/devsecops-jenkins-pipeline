#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-devsecops-demo}"
DEPLOYMENT="${DEPLOYMENT:-sample-api}"
HEALTH_URL="${HEALTH_URL:-}"

echo "Waiting for rollout of deployment/${DEPLOYMENT} in namespace ${NAMESPACE}..."
kubectl -n "${NAMESPACE}" rollout status "deployment/${DEPLOYMENT}" --timeout=180s

if [[ -n "${HEALTH_URL}" ]]; then
  echo "Checking ${HEALTH_URL}..."
  status="$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 10 "${HEALTH_URL}")"
  if [[ "${status}" != "200" ]]; then
    echo "Health check failed with HTTP ${status}"
    exit 1
  fi
  echo "HTTP health check passed."
else
  echo "HEALTH_URL not provided; rollout readiness is the deployment health gate."
fi
