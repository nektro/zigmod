#!/usr/bin/env bash

set -e

tag=r$(./release_num.sh)

GITHUB_TOKEN="$1"
PROJECT_USERNAME=$(echo $GITHUB_REPOSITORY | cut -d'/' -f1)
PROJECT_REPONAME=$(echo $GITHUB_REPOSITORY | cut -d'/' -f2)

# ghr uses Zigmod to build itself, so we need to use the binary to build Zigmod
curl -s https://api.github.com/repos/nektro/ghr-zig/releases | jq -r '.[0].assets[].browser_download_url' | grep $(uname -m) | grep linux | wget -i -
chmod +x ./ghr-linux-x86_64
./ghr-linux-x86_64 \
    -t ${GITHUB_TOKEN} \
    -u ${PROJECT_USERNAME} \
    -r ${PROJECT_REPONAME} \
    -b "$(./changelog.sh)" \
    -n "$tag" \
    "$tag" \
    "./bin/"
