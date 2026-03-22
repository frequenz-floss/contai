# Contain AI! 📦🤖

`contai` is a very opinionated Docker-based sandbox for running AI CLI tools
for people paranoid enough to not wanting to give them access to their whole
system (i.e. normal people).

## Features

- **Sandboxed Environment**: Runs AI CLI tools in an isolated Docker container
  to protect your host system
- **Pre-installed AI CLI Tools**: Includes [OpenCode](https://opencode.ai/),
  [OpenAI Codex](https://developers.openai.com/codex/cli/),
  [GitHub Copilot](https://github.com/features/copilot/cli),
  [Google Gemini](https://github.com/google-gemini/gemini-cli), and
  [Claude Code](https://www.claude.com/product/claude-code) out of the box
- **User Permission Mapping**: Maintains your host UID/GID for seamless file
  access and ownership
- **Persistent Home Directory**: Stores configuration and data in
  `~/.local/share/contai/home` across container sessions
- **Current Directory Mounting**: Automatically mounts and uses your current
  working directory
- **Development Tools Included**: Comes with ripgrep, bat, git, Python,
  Node.js, and other essential tools
- **On-demand Tool Installation**: Includes [pkgx](https://pkgx.dev/) for
  installing additional tools without root access
- **Symlink-friendly**: Can be symlinked as different tool names (e.g.,
  `opencode` symlink runs OpenCode directly)
- **Apple Container Runtime**: Supports Apple's new `container` runtime with
  automatic detection, falling back to Docker
- **Timezone Passthrough**: Automatically detects and passes your host timezone
  to the container for correct git commit timestamps

## Build

To build the container image:

```sh
./build.sh
```

This will create a Docker image tagged as `contai:latest` with your host user's
UID/GID for proper file permissions.

The build script automatically detects Apple's `container` runtime if available,
falling back to Docker. You can override the runtime with the `RUNTIME` environment
variable:

```sh
RUNTIME=docker ./build.sh
```

## Installation

### Using Makefile (Recommended)

The easiest way to install `contai` is using the provided Makefile:

```sh
make install                    # Install to ~/.local/bin
sudo make install PREFIX=/usr/local  # Install system-wide
                                     # (requires "make image" step separately)
```

The Makefile will:
- Build the image if needed (unless running as root)
- Copy `contai` to `$(PREFIX)/bin`
- Create symlinks for each AI tool (`opencode`, `copilot`, `codex`, `gemini`, `claude`)

To install via symlink instead of copy:

```sh
METHOD=link make install
```

**Note**: The symlink method is useful for development, as changes to `contai` in
your source tree take effect immediately without reinstalling. Not recommended
for system-wide installations as the source directory becomes a trusted path.

Other useful targets:

```sh
make image  # Build the Docker image
make clean  # Remove the image and build stamp
make help   # Show available targets
```

### Manual Installation

After building, you can install `contai` to your PATH:

```sh
# Create a bin directory in your home (if it doesn't exist)
mkdir -p ~/bin

# Copy the contai script
cp contai ~/bin/

# Make sure ~/bin is in your PATH (add to ~/.bashrc or ~/.zshrc if needed)
export PATH="$HOME/bin:$PATH"
```

### Optional: Create Symlinks for Direct Tool Access

You can create symlinks to run specific AI tools directly:

```sh
cd ~/bin
ln -s contai opencode
ln -s contai copilot
ln -s contai codex
ln -s contai gemini
ln -s contai claude
```

Now you can run tools directly (e.g., `opencode` instead of `contai opencode`).

### Install AI Agent Instructions

To enable AI agents to work best inside the container (e.g., using `pkgx` for
missing tools instead of `apt-get`), install the provided `agent-instructions.md`
file to the appropriate location for your AI tool:

```sh
# Create the container's home config directories
home=~/.local/share/contai/home
mkdir -p "$home"
```

#### OpenCode

```sh
# OpenCode
mkdir -p "$home/.config/opencode"
cp agent-instructions.md "$home/.config/opencode/AGENTS.md"
```

#### Claude Code

```sh
mkdir -p "$home/.claude"
cp agent-instructions.md "$home/.claude/CLAUDE.md"
```

#### Google Gemini CLI

```sh
mkdir -p "$home/.gemini"
cp agent-instructions.md "$home/.gemini/GEMINI.md"
```

#### OpenAI Codex CLI

```sh
mkdir -p "$home/.codex"
cp agent-instructions.md "$home/.codex/AGENTS.md"
```

#### GitHub Copilot CLI

GitHub Copilot CLI only supports project-level instructions (not global), so
you would need to copy the file to each project's
`.github/copilot-instructions.md`.

## Usage

Run AI tools in the sandboxed environment:

```sh
# Run a specific tool
contai opencode

# Or use symlinks for direct access
opencode

# The container automatically mounts your current directory
cd /path/to/your/project
contai opencode
```

Your configuration and data will be persisted in `~/.local/share/contai/home`
across container sessions.

## Environment Variables

You can define environment variables in the container by writing to a
`~/.local/share/contai/env.list` file. The file is expected to have the
standard [docker `--env-file`
format](https://docs.docker.com/reference/cli/docker/container/run/#env).

### Runtime Variables

The following environment variables control the container runtime:

- `RUNTIME`: Override the container runtime (`docker` or `container`). By default,
  the script auto-detects Apple's `container` runtime, falling back to Docker.
- `TZ`: Override the timezone passed to the container. By default, the script
  detects the host timezone from `/etc/localtime`.

## Known Issues

* Tested almost exclusively with OpenCode for now.

* When configuring MCP servers that need OAuth, for example using
  [`mcp-remote`](https://github.com/geelen/mcp-remote), for completing the
  OAuth flow, you need to open a browser on your host machine. For now, you need
  to run the OAuth flow outside the container, as the container does not
  have access to your host's browser, and then copy the credentials manually.

  For example:

  ```sh
  cp -r ~/.mcp-auth/* ~/.local/share/contai/home/.mcp-auth/
  ```

## Roadmap

- [ ] Add installer script and/or Debian package for easier installation
  (including symlinks to the shipped tools)
- [ ] Add pre-built images (needs some thought about how to deal with user IDs)
- [ ] Add auto-image build when invoking `contai` if image is not found
- [ ] Find a way to complete OAuth flows from within the container
- [ ] Integrate with `docker-compose` for easier multi-container setups, for
  cases where other services are needed, like MCP servers
- [ ] Support forwarding environment variables from the current environment.
- [ ] Add configuration file to be able to customize, for example:

  * Mapping of directories to mount into the container
  * Extra packages to install to the image
