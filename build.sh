#!/bin/sh
set -eu

docker build \
	-t contai:latest \
	--build-arg "UID=${CONTAI_UID:-$(id -u)}" \
	--build-arg "USERNAME=${CONTAI_USER:-$(id -un)}" \
	--build-arg "GID=${CONTAI_GID:-$(id -g)}" \
	--build-arg "GROUPNAME=${CONTAI_GROUP:-$(id -gn)}" \
	--build-arg "HOME_DIR=${CONTAI_HOME:-$HOME}" \
	"$@" \
	-f Dockerfile \
	.
