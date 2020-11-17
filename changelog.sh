#!/usr/bin/env bash

set -e

read-log() {
    git log --format=format:"%h%n%H%n%an%n%s%n%d%n"
}

hash_abrev=''
hash=''
author=''
title=''

c=0
t=0
read-log |
while IFS= read -r lineVAR; do
    if [[ "$c" == '0' ]]; then
        hash_abrev="$lineVAR"
    fi
    if [[ "$c" == '1' ]]; then
        hash="$lineVAR"
    fi
    if [[ "$c" == '2' ]]; then
        author="$lineVAR"
    fi
    if [[ "$c" == '3' ]]; then
        title="$lineVAR"
    fi
    if [[ "$c" == '4' ]]; then
        if [ ! -z "$lineVAR" ]; then
            t=$(($t+1))
        fi
        if [[ "$t" == '2' ]]; then
            break
        fi
        echo "<li><a href='https://github.com/nektro/$CIRCLE_PROJECT_REPONAME/commit/$hash'><code>$hash_abrev</code></a> $title ($author)</li>"
    fi
    c=$(($c+1))
    #
    if [[ "$c" == '6' ]]; then
        c=0
    fi
done
