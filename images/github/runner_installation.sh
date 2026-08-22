#!/bin/bash
set -e

print_header() {
  lightcyan="\033[1;36m"
  nocolor="\033[0m"
  echo -e "\n${lightcyan}$1${nocolor}\n"
}

# --- Validate required environment variables ---
: "${GH_TOKEN:?missing GH_TOKEN environment variable}"
: "${GH_OWNER:?missing GH_OWNER environment variable}"

RUNNER_SCOPE="${RUNNER_SCOPE:-org}"
GITHUB_SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
GITHUB_API_URL="${GITHUB_API_URL:-https://api.github.com}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux}"
EPHEMERAL="${EPHEMERAL:-true}"

# --- Resolve scope-specific runner URL and token API endpoint ---
case "${RUNNER_SCOPE}" in
  org)
    RUNNER_URL="${GITHUB_SERVER_URL}/${GH_OWNER}"
    TOKEN_API="${GITHUB_API_URL}/orgs/${GH_OWNER}/actions/runners"
    ;;
  repo)
    : "${GH_REPOSITORY:?missing GH_REPOSITORY environment variable for repo scope}"
    RUNNER_URL="${GITHUB_SERVER_URL}/${GH_OWNER}/${GH_REPOSITORY}"
    TOKEN_API="${GITHUB_API_URL}/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners"
    ;;
  ent | enterprise)
    RUNNER_URL="${GITHUB_SERVER_URL}/enterprises/${GH_OWNER}"
    TOKEN_API="${GITHUB_API_URL}/enterprises/${GH_OWNER}/actions/runners"
    ;;
  *)
    echo 1>&2 "error: invalid RUNNER_SCOPE '${RUNNER_SCOPE}' (expected: org | repo | ent)"
    exit 1
    ;;
esac

# GitHub registration tokens are short-lived (~1h), so they must be minted at
# startup from the long-lived PAT rather than baked into the image.
get_token() {
  # $1 = registration | remove
  curl -fsSL -X POST \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${TOKEN_API}/${1}-token" | jq -r .token
}

cleanup() {
  trap "" EXIT

  if [ -e ./config.sh ]; then
    print_header "Cleanup. Removing GitHub Actions runner..."

    REMOVE_TOKEN=$(get_token remove || true)
    if [ -n "${REMOVE_TOKEN}" ] && [ "${REMOVE_TOKEN}" != "null" ]; then
      ./config.sh remove --token "${REMOVE_TOKEN}" || true
    fi
  fi
}

print_header "1. Requesting a runner registration token..."

REG_TOKEN=$(get_token registration)

if [ -z "${REG_TOKEN}" ] || [ "${REG_TOKEN}" == "null" ]; then
  echo 1>&2 "error: could not obtain a registration token"
  echo 1>&2 "check that GH_TOKEN is valid and has the required scope for '${RUNNER_SCOPE}' scope on '${GH_OWNER}'"
  exit 1
fi

print_header "2. Configuring GitHub Actions runner..."

RUNNER_ARGS=(
  --url "${RUNNER_URL}"
  --token "${REG_TOKEN}"
  --name "${RUNNER_NAME:-$(hostname)}"
  --labels "${RUNNER_LABELS}"
  --work "_work"
  --unattended
  --replace
)

# One job per runner, then exit (recommended for security & clean state).
if [ "${EPHEMERAL}" == "true" ]; then
  RUNNER_ARGS+=(--ephemeral)
fi

# Optional runner group (org/enterprise scopes).
if [ -n "${RUNNER_GROUP}" ]; then
  RUNNER_ARGS+=(--runnergroup "${RUNNER_GROUP}")
fi

./config.sh "${RUNNER_ARGS[@]}"

trap "cleanup; exit 0" EXIT
trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

print_header "3. Running GitHub Actions runner..."

./run.sh "$@" &
wait $!

cleanup
