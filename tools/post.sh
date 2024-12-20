#!/bin/bash

set -e

echo "::debug::Dumping local git config:"
git config --list --local

echo "::debug::Dumping global git config:"
git config --list --global

echo "::debug::Dumping git interceptor log:"
cat /tmp/git_interceptor.log
