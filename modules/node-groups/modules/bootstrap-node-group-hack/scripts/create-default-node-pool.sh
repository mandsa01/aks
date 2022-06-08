#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${AZURE_ENVIRONMENT:-}" ]]
then
  az cloud set --name "${AZURE_ENVIRONMENT}"
fi

if [[ -n "${AZURE_TENANT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_SECRET:-}" ]]
then
  az login --service-principal --user "${AZURE_CLIENT_ID}"  --password "${AZURE_CLIENT_SECRET}" --tenant "${AZURE_TENANT_ID}"
fi

lookup="$(az aks nodepool list \
  --subscription "${AZURE_SUBSCRIPTION_ID}" \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --cluster-name "${CLUSTER_NAME}" \
  | jq -r --arg node_pool_name "${NODE_POOL_NAME}" '.[] | select(.name == $node_pool_name)')"

if [[ -z "${lookup}" ]]
then
  az aks nodepool add \
    --enable-encryption-at-host \
    --subscription "${AZURE_SUBSCRIPTION_ID}" \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --cluster-name "${CLUSTER_NAME}" \
    --vnet-subnet-id "${SUBNET_ID}" \
    --name "${NODE_POOL_NAME}" \
    --mode System \
    --node-count 1 \
    --node-vm-size "${VM_SIZE}" \
    --node-osdisk-type Managed
fi

if [[ -n "${AZURE_TENANT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_ID:-}" ]] && [[ -n "${AZURE_CLIENT_SECRET:-}" ]]
then
  az logout --username "${AZURE_CLIENT_ID}"
fi
