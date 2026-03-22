#!/bin/sh
set -eu

# Use RUNTIME from environment if set, otherwise auto-detect
if test -z "${RUNTIME:-}"; then
	RUNTIME=docker
	command -v container >/dev/null 2>&1 && RUNTIME=container
fi

if test "$RUNTIME" = "docker"; then
	$RUNTIME build \
		-t contai:latest \
		--build-arg UID="$(id -u)" \
		--build-arg USERNAME="$(id -un)" \
		--build-arg GID="$(id -g)" \
		--build-arg GROUPNAME="$(id -gn)" \
		"$@" \
		- <Dockerfile
else
	$RUNTIME --debug build \
		-t contai:latest \
		--build-arg UID="$(id -u)" \
		--build-arg USERNAME="$(id -un)" \
		--build-arg GID="$(id -g)" \
		--build-arg GROUPNAME="$(id -gn)" \
		"$@" \
		.
fi
