#!/bin/bash
set -e

print_header() {
  lightcyan="\033[1;36m"
  nocolor="\033[0m"
  echo -e "\n${lightcyan}$1${nocolor}\n"
}

cleanup() {
  trap "" EXIT

  if [ -e ./config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    while true; do
      ./config.sh remove --unattended --auth "PAT" --token "${AZP_PAT}" && break
      echo "Retrying in 30 seconds..."
      sleep 30
    done
  fi
}

# Validate required environment variables
if [ -z "${AZP_URL}" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "${AZP_PAT}" ]; then
  echo 1>&2 "error: missing AZP_PAT environment variable"
  exit 1
fi

if [ -z "${AZP_POOL}" ]; then
  echo 1>&2 "error: missing AZP_POOL environment variable"
  exit 1
fi

print_header "1. Determining matching Azure Pipelines agent..."

AZP_AGENT_PACKAGES=$(curl -LsS \
    -u user:"${AZP_PAT}" \
    -H "Accept:application/json;" \
    "${AZP_URL}/_apis/distributedtask/packages/agent?platform=${TARGETARCH}&top=1")

AZP_AGENT_PACKAGE_LATEST_URL=$(echo "${AZP_AGENT_PACKAGES}" | jq -r ".value[0].downloadUrl")

if [ -z "${AZP_AGENT_PACKAGE_LATEST_URL}" ] || [ "${AZP_AGENT_PACKAGE_LATEST_URL}" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent"
  echo 1>&2 "check that account '${AZP_URL}' is correct and the token is valid"
  exit 1
fi

print_header "2. Downloading and extracting Azure Pipelines agent..."

curl -LsS "${AZP_AGENT_PACKAGE_LATEST_URL}" | tar -xz &
wait $!

source ./env.sh

trap "cleanup; exit 0" EXIT
trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

print_header "3. Configuring Azure Pipelines agent..."

AGENT_ARGS=(
  --unattended
  --agent "${AZP_AGENT_NAME:-$(hostname)}"
  --url "${AZP_URL}"
  --token "${AZP_PAT}"
  --pool "${AZP_POOL}"
  --work "_work"
  --replace
  --acceptTeeEula
)

# Add tags if TAG_VALUE is set
if [ -n "${TAG_VALUE}" ]; then
  AGENT_ARGS+=(--addvirtualmachineresourcetags "${TAG_VALUE}")
fi

./config.sh "${AGENT_ARGS[@]}" &
wait $!

print_header "4. Running Azure Pipelines agent..."

chmod +x ./run.sh
./run.sh "$@" &
wait $!

cleanup
