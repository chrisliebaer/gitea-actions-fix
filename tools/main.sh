#!/bin/bash

set -e

SCRIPT_DIR=$(realpath $(dirname $0))

# if INPUT_DEBUG_GIT is set, enable a more verbose git output
if [[ $INPUT_DEBUG_GIT == "true" || $INPUT_DEBUG_GIT == "1" ]]; then
	export GIT_TRACE=1
	export GIT_CURL_VERBOSE=1
	
	echo "GIT_TRACE=$GIT_TRACE" >> $GITHUB_ENV
	echo "GIT_CURL_VERBOSE=$GIT_CURL_VERBOSE" >> $GITHUB_ENV
fi

# if server url has no trailing slash, add it
# this is important for .insteadoOf, as it would otherwise omit the slash
if [[ $INPUT_SERVER_URL != */ ]]; then
	INPUT_SERVER_URL="$INPUT_SERVER_URL/"
fi

INSTANCE_SCHEME=$(echo $INPUT_SERVER_URL | grep -oP 'https?')
INSTANCE_HOST=$(echo $INPUT_SERVER_URL | grep -oP '(?<=://)[^/]+')

# replace ssh submodule urls with https
git config --global url."$INPUT_SERVER_URL".insteadOf "git@$INSTANCE_HOST:"

echo "::debug::Current git config:"
git config --list --global

# add custom git wrapper to path with higher priority to prevent destructive config changes by actions/checkout
echo "$SCRIPT_DIR/interceptors/bin" > "$GITHUB_PATH"

# setup credentials helper
# dont place "$HOME" variable in config, since some mental actions will unset or change it
git config --global credential.helper "store --file $HOME/.git-credentials"
git config --global http.proactiveAuth true
git credential approve <<EOF
protocol=$INSTANCE_SCHEME
host=$INSTANCE_HOST
username=basic
password=$INPUT_TOKEN
EOF

echo "::info::Gitea setup completed"

exit 0
