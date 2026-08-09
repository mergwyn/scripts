#!/usr/bin/env bash

# BWS S3 Credential Loading Module
# Provides functions to load S3 credentials from BWS (Bitwarden Secrets Manager)

# Load BWS token
[[ -f "/etc/kopia/.bws_env" ]] && source "/etc/kopia/.bws_env"
[[ -z "${BWS_ACCESS_TOKEN}" ]] && { log_error "BWS_ACCESS_TOKEN not set"; exit 1; }

declare -A STORE_UUIDS=(
  [idrive]="31c6c57d-7a0d-4e3c-afaf-b1ec01031b4f"
  [minio]="232cb3fe-cf1d-493b-b879-b1ec00fe24c5"
  [repo-pw]="500f90e6-0977-40e9-a425-b42100fe869a"
)

load_bws_s3() {
  local store=$1
  local uuid=${STORE_UUIDS[$store]}
  [[ -z "$uuid" ]] && { log_error "No UUID configured for store '${store}'"; return 1; }

  local raw
  raw=$(bws secret get "$uuid" --output json | jq -r '.value')

  while IFS= read -r line; do
    [[ $line == *:* ]] || continue
    local k v
    k=$(echo "${line%%:*}" | xargs)
    v=$(echo "${line#*:}" | xargs)
    export "$k"="$v"
  done <<< "$raw"

  # TODO remove TLS exception when enabled for minio
  if [[ "$store" == "minio" ]] || [[ "$ENDPOINT" == *":9000"* ]]; then
    log_debug "Disabling TLS for ${store} (${ENDPOINT})"
    TLS_FLAG="--disable-tls"
  else
    export TLS_FLAG=""
  fi
}

load_repo_password() {
  KOPIA_PASSWORD=$(bws secret get "${STORE_UUIDS[repo-pw]}" --output json | jq -r '.value')
  [[ -z "$KOPIA_PASSWORD" ]] && { log_error "Failed to load repo password"; return 1; }
  return 0
}
