#!/bin/sh
# Build the Connect IQ Store package.
#
# Produces dist/NakedRun.iq, the single file uploaded at
# apps.garmin.com -> Developer Dashboard -> Upload An App. It contains a
# build for every device listed in manifest.xml, which is why this takes
# considerably longer than ./build.sh.
#
#   -e  package the app as a .iq store bundle rather than a .prg sideload
#   -r  strip debug information (release build)
#
# -r also strips the (:test) annotated code in source/Tests.mc, so the test
# suite costs the shipped app nothing. Run ./test.sh before this, not after:
# this output is not the thing you can sideload and try.
set -e

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

SDK="${CIQ_SDK:-$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2}"
KEY="${CIQ_KEY:-keys/developer_key.der}"

if [ ! -f "$KEY" ]; then
    echo "Missing signing key at $KEY." >&2
    echo "This is the key the store ties the app identity to - if it is lost," >&2
    echo "updates can never be published against the existing listing." >&2
    exit 1
fi

mkdir -p dist
printf 'packaging every device in manifest.xml (this takes a while) ... '
"$SDK/bin/monkeyc" -e -r -f monkey.jungle -o dist/NakedRun.iq -y "$KEY" -w
printf 'ok\n\n'
ls -lh dist/NakedRun.iq
