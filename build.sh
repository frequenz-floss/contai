#!/bin/sh
set -eu

runtime=docker
command -v container >/dev/null 2>&1 && runtime=container

if test "$runtime" = "docker"; then
	$runtime build \
		-t contai:latest \
		--build-arg UID="$(id -u)" \
		--build-arg USERNAME="$(id -un)" \
		--build-arg GID="$(id -g)" \
		--build-arg GROUPNAME="$(id -gn)" \
		"$@" \
		- <Dockerfile
else
	$runtime --debug build \
		-t contai:latest \
		--build-arg UID="$(id -u)" \
		--build-arg USERNAME="$(id -un)" \
		--build-arg GID="$(id -g)" \
		--build-arg GROUPNAME="$(id -gn)" \
		"$@" \
		.
fi
