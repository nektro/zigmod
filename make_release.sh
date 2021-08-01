#!/usr/bin/env bash

set -e

date=$(date +'%Y.%m.%d')
version=${CIRCLE_BUILD_NUM-$date}
tag=v$version
go get github.com/tcnksm/ghr
$GOPATH/bin/ghr \
    -t ${GITHUB_TOKEN} \
    -u ${CIRCLE_PROJECT_USERNAME} \
    -r ${CIRCLE_PROJECT_REPONAME} \
    -b "$(./changelog.sh)" \
    -n "$tag" \
    "$tag" \
    "/artifacts/"
