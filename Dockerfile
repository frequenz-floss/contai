ARG UBUNTU_VERSION=25.10

FROM ubuntu:${UBUNTU_VERSION}

ARG UID
ARG USERNAME
ARG GID
ARG GROUPNAME

# The home directory is the host's own, so that the persistent home the runner
# mounts there sits at one path on both sides. See the ENV at the end.
ARG HOME_DIR

RUN userdel --force --remove ubuntu && \
	groupadd --gid ${GID} ${GROUPNAME} && \
	useradd --create-home --home-dir "${HOME_DIR}" --shell /bin/bash \
		--gid ${GID} --uid ${UID} ${USERNAME}

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

RUN arch=$(uname -m) && \
	case "$arch" in \
		x86_64|amd64) rtk_target=x86_64-unknown-linux-musl ;; \
		aarch64|arm64) rtk_target=aarch64-unknown-linux-gnu ;; \
		*) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
	esac && \
	tmp_dir=$(mktemp -d) && \
	curl -fsSL "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-$rtk_target.tar.gz" \
	| tar -xzf - -C "$tmp_dir" && \
	install -m 755 "$tmp_dir/rtk" /usr/local/bin/rtk && \
	rm -rf "$tmp_dir"

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

# The native Claude installer is user-scoped, so use its system-wide npm
# package alongside the other globally installed CLI tools.
#
# opencode-ai's postinstall script runs the binary it just downloaded once, as a
# smoke test, and merely loading that binary creates /tmp/opencode. The build
# runs as root, so the directory is baked into the image owned by root, and the
# mapped account cannot write to it at run time even though opencode tells the
# agents it runs that the directory is theirs to use. Delete it here, with -f so
# a future opencode-ai that stops creating it does not fail the build.
RUN npm install -g \
	@anthropic-ai/claude-code@latest \
	@github/copilot@latest \
	@google/gemini-cli@latest \
	@openai/codex@latest \
	opencode-ai@latest && \
	rm -rf /tmp/opencode

RUN curl -Ls https://pkgx.sh/$(uname)/$(uname -m) -o /usr/local/bin/pkgx && \
	chmod +x /usr/local/bin/pkgx

RUN curl -L https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m) \
	-o /usr/local/bin/nix-portable && chmod +x /usr/local/bin/nix-portable

COPY --chmod=755 contai-bootstrap /usr/local/bin/contai-bootstrap

# $HOME has to be the very path the runner mounts the persistent home at, or
# whatever a tool writes below it lands in the image and is gone on the next
# run. Both sides use the host's home directory: it keeps a path meaning the
# same thing inside and outside the container, and the image already carries
# the building account's UID, GID and names, so this adds no new coupling.
#
# These come last so that no RUN sees them: the build runs as root, and a root
# HOME pointing at the account's home would leave root-owned files in it.
ENV HOME="${HOME_DIR}"
ENV PATH="$PATH:${HOME_DIR}/.local/bin"
