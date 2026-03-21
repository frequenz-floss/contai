ARG UBUNTU_VERSION=25.10

FROM ubuntu:${UBUNTU_VERSION}

ARG UID
ARG USERNAME
ARG GID
ARG GROUPNAME

RUN userdel --force --remove ubuntu && \
	(getent group ${GID} || groupadd --gid ${GID} ${GROUPNAME}) && \
	useradd --create-home --shell /bin/bash --gid ${GID} --uid ${UID} ${USERNAME}

RUN apt-get update && apt-get install -y \
	bash-completion \
	bat \
	curl \
	direnv \
	file \
	git \
	jq \
	python3 \
	python3-pip \
	shellcheck \
	shfmt \
	ripgrep

RUN pip install --break-system-packages \
	black \
	flake8 \
	isort \
	mypy \
	pylint \
	ruff \
	uv

RUN curl -fsSL https://github.com/tamasfe/taplo/releases/latest/download/taplo-linux-x86_64.gz \
	| gzip -d - | install -m 755 /dev/stdin /usr/local/bin/taplo

RUN (type -p wget >/dev/null || (apt update && apt install wget -y)) \
	&& mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& apt update \
	&& apt install gh -y \
	&& rm -fr $out

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
	apt update && \
	apt install -y nodejs

RUN npm install -g \
	@github/copilot \
	@google/gemini-cli \
	@openai/codex \
	opencode-ai

RUN curl -fsSL https://claude.ai/install.sh | bash

RUN curl -Ls https://pkgx.sh/$(uname)/$(uname -m) -o /usr/local/bin/pkgx && \
	chmod +x /usr/local/bin/pkgx

RUN curl -L https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m) \
	-o /usr/local/bin/nix-portable && chmod +x /usr/local/bin/nix-portable

ENV PATH="$PATH:/home/${USERNAME}/.local/bin"
