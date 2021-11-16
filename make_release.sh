#!/usr/bin/env bash

set -e

date=$(date +'%Y.%m.%d')
version=${CIRCLE_BUILD_NUM-$date}
tag=v$version

# ghr uses Zigmod to build itself, so we need to use the binary to build Zigmod
curl -s https://api.github.com/repos/nektro/ghr-zig/releases | jq -r '.[0].assets[].browser_download_url' | grep $(uname -m) | grep linux | wget -i -
chmod +x ./ghr-linux-x86_64
./ghr-linux-x86_64 \
    -t ${GITHUB_TOKEN} \
    -u ${CIRCLE_PROJECT_USERNAME} \
    -r ${CIRCLE_PROJECT_REPONAME} \
    -b "$(./changelog.sh)" \
    -n "$tag" \
    "$tag" \
    "/artifacts/"
