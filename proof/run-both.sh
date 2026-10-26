#!/usr/bin/env bash
# Usage: run-both.sh <built-main-checkout> <built-branch-checkout>
set -uo pipefail
cd "$(dirname "$0")"
./demo.sh "$1" "main"
./demo.sh "$2" "this branch"
