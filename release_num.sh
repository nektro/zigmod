#!/usr/bin/env bash

set -e

tagcount=$(git tag | wc -l)
tagcount=$((tagcount+1))

echo $tagcount
