#!/bin/bash

set -e -u -o pipefail # Exit immediately on any command failure, unset variables, or pipeline failure

# Validate essential dependencies
for cmd in curl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

# Validate required environment variables
if [ -z "${RUNNER_NAME}" ]; then
    echo "Error: RUNNER_NAME must be set." >&2
    exit 1
fi

# Require either ACCESS_TOKEN (to request a registration token) or a pre-generated REGISTRATION_TOKEN
if [ -z "${ACCESS_TOKEN:-}" ] && [ -z "${REGISTRATION_TOKEN:-}" ]; then
    echo "Error: Either ACCESS_TOKEN or REGISTRATION_TOKEN must be set." >&2
    exit 1
fi

# Determine registration URL based on organization or repository
if [ -n "${ORGANIZATION:-}" ]; then
    REG_TOKEN_URL="https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token"
    REG_TOKEN_CONFIG_URL="https://github.com/${ORGANIZATION}"
elif [ -n "${OWNER:-}" ] && [ -n "${REPOSITORY:-}" ]; then
    REG_TOKEN_URL="https://api.github.com/repos/${OWNER}/${REPOSITORY}/actions/runners/registration-token"
    REG_TOKEN_CONFIG_URL="https://github.com/${OWNER}/${REPOSITORY}"
else
    echo "Error: When configuring for a repository, OWNER and REPOSITORY must be set, or ORGANIZATION must be set." >&2
    exit 1
fi

# Obtain registration token
if [ -n "${REGISTRATION_TOKEN:-}" ]; then
    REG_TOKEN="${REGISTRATION_TOKEN}"
    echo "Using provided registration token."
else
    echo "Requesting registration token from GitHub..."
    API_RESPONSE=$(curl -sS -X POST -H "Authorization: token ${ACCESS_TOKEN}" "${REG_TOKEN_URL}")
    REG_TOKEN=$(echo "${API_RESPONSE}" | jq -r .token)
fi

if [ -z "${REG_TOKEN}" ] || [ "${REG_TOKEN}" = "null" ]; then
    echo "Error: Failed to get registration token." >&2
    exit 1
fi

# Configure the runner in unattended mode
./config.sh --url "${REG_TOKEN_CONFIG_URL}" --token "${REG_TOKEN}" --name "${RUNNER_NAME}" --unattended --replace --labels "${RUNNER_LABELS:-default}"

# Cleanup function to remove runner registration on exit
cleanup() {
    echo "Removing runner..."
    if [ -n "${REG_TOKEN:-}" ]; then
        ./config.sh remove --token "${REG_TOKEN}"
    else
        echo "Warning: No registration token available for removal. Manual cleanup may be required." >&2
    fi
}

# Trap signals for graceful shutdown
trap 'cleanup' INT TERM

# Start the runner
./run.sh & wait $!

# Final cleanup
cleanup