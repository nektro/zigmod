#!/bin/sh

set -ex
unset ZIG_LOCAL_CACHE_DIR # TODO: link issue here

./test_repo.sh https://github.com/nektro/zigmod-test-basic
./test_repo.sh https://github.com/nektro/zigmod-test-git-dep
./test_repo.sh https://github.com/nektro/zigmod-test-hg-dep
./test_repo.sh https://github.com/nektro/zigmod-test-http-dep
./test_repo.sh https://github.com/nektro/zigmod-test-systemlib-dep
./test_repo.sh https://github.com/nektro/zigmod-test-local-dep
./test_repo.sh https://github.com/nektro/zigmod-test-c-code
