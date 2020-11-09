#!/usr/bin/env bash

date=$(date +'%Y.%m.%d')
version=${CIRCLE_BUILD_NUM-$date}
tag=v$version-$(git log --format=%h -1)
go get -v -u github.com/tcnksm/ghr
$GOPATH/bin/ghr \
    -t ${GITHUB_TOKEN} \
    -u ${CIRCLE_PROJECT_USERNAME} \
    -r ${CIRCLE_PROJECT_REPONAME} \
    -b "$(./changelog.sh)" \
    "$tag" \
    "./bin/"
