#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Script use for testing to simulate slow command
sleep "${1}"
echo "${2}"
