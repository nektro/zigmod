#!/bin/sh

set -ex

./test_repo.sh https://github.com/nektro/zigmod-test-basic
./test_repo.sh https://github.com/nektro/zigmod-test-git-dep
./test_repo.sh https://github.com/nektro/zigmod-test-hg-dep
