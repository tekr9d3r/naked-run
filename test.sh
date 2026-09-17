#!/bin/sh
# Build with the unit tests compiled in and run them in the simulator.
# The simulator must already be running (./build.sh does not start it):
#
#   "$CIQ_SDK/bin/connectiq" &      # once
#   ./test.sh                       # as often as you like
set -e

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

SDK="${CIQ_SDK:-$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2}"
KEY="${CIQ_KEY:-keys/developer_key.der}"
DEVICE="${1:-instinct3amoled50mm}"

mkdir -p dist
"$SDK/bin/monkeyc" -f monkey.jungle -o "dist/NakedRun-test.prg" -y "$KEY" -d "$DEVICE" -w -t
"$SDK/bin/monkeydo" "dist/NakedRun-test.prg" "$DEVICE" -t
