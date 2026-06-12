#!/usr/bin/env bash

set -euo pipefail

# fort build-runner

fort build-app --release
fort install --app-name aurora_recovery --local-path build
fort launch --app-name aurora_recovery --scale 2.5 --release

rm -rf ./aurora_recovery
adb pull /tmp/aurora_recovery ./aurora_recovery