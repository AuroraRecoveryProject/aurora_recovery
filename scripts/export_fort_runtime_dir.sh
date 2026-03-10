#!/usr/bin/env bash

set -euo pipefail

# fort build-runner

fort build-app
fort install --app-name aurora_recovery --local-path build
fort launch --app-name aurora_recovery

rm -rf ./aurora_runtime
adb pull /tmp/aurora_recovery ./aurora_runtime