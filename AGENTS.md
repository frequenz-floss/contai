# AGENTS.md

This file provides guidance for AI coding agents working in the contai repository.

## Project Overview

contai is a Docker-based sandbox for running AI CLI tools (OpenCode, GitHub Copilot,
OpenAI Codex, Google Gemini, Claude Code) in isolation. It's a minimal project with
shell scripts and a Dockerfile - no package.json, no TypeScript, no complex build system.

Read README.md for complete project documentation including features and usage.

## Project Structure

```
contai/
├── AGENTS.md              # This file - AI agent instructions
├── README.md              # Project documentation
├── Dockerfile             # Container definition with dev tools
├── build.sh               # Build script with user permission handling
├── contai                 # Container runner script
└── agent-instructions.md  # Global agent instructions for end users
```

## Build Commands

| Command      | Description                                              |
|--------------|----------------------------------------------------------|
| `./build.sh` | Builds Docker image tagged as `contai:latest`            |
| `./contai`   | Runs the container with current directory mounted        |
| `make image` | Build the Docker image (via Makefile)                    |
| `make install` | Install contai to `~/.local/bin` (or custom `PREFIX`)  |
| `make clean` | Remove the Docker image and build stamp                  |

### Building the Container

```sh
./build.sh
```

The build script passes host UID/GID to ensure proper file permissions inside the container.

### Installing with Makefile

```sh
make install                    # Install to ~/.local/bin (builds image if needed)
make install PREFIX=/usr/local # Install to /usr/local/bin
sudo make install PREFIX=/usr/local # Install as root (requires pre-built image)
METHOD=link make install        # Symlink instead of copy
```

Note: Running `make install` as root requires the image to be built first (run `make image` as non-root).

### Running the Container

```sh
./contai opencode    # Run a specific AI tool
./contai             # Start container shell
```

## Testing

This project has no test suite. Changes should be verified by:
1. Building the container: `./build.sh`
2. Running the container and testing functionality: `./contai`
3. Verifying the AI tools work: `./contai opencode --version`

## Linting

No project-level linting is configured. However, the container includes these tools:
- Shell: `shellcheck`, `shfmt`
- Python: `ruff`, `flake8`, `pylint`, `mypy`, `black`, `isort`

To lint shell scripts locally (if shellcheck is installed):
```sh
shellcheck build.sh contai
shfmt -d build.sh contai
```

## Code Style Guidelines

### Shell Scripts

All shell scripts in this project follow these conventions:

#### Shebang and Error Handling
```sh
#!/bin/sh
set -eu
```
- Always use `#!/bin/sh` (POSIX shell), not `#!/bin/bash`
- Always include `set -eu` immediately after the shebang
  - `-e`: Exit immediately on command failure
  - `-u`: Treat unset variables as errors

#### Variable Naming
- Use lowercase with underscores: `data_dir`, `home_dir`, `env_file`
- Never use camelCase or UPPER_CASE for local variables

#### Quoting
- Always quote variables in strings: `"$home_dir"`
- Use double quotes for strings containing variables
- Single quotes for literal strings without variables

#### Command Substitution
- Use `$(command)` syntax, not backticks
- Example: `$(id -u)`, `$(basename "$0")`

#### Conditionals
- Use `test` command or `[` for conditions: `if test "$tool" = "contai"`
- Use `=` for string comparison, not `==`

#### Indentation
- Use tabs for indentation, not spaces
- Indent continuation lines in multi-line commands

#### Line Continuation
- Use backslash `\` for multi-line commands
- Place backslash at end of line with no trailing whitespace

#### Example Shell Script Pattern
```sh
#!/bin/sh
set -eu

# Variables
data_dir=~/.local/share/contai
home_dir=$data_dir/home

# Conditionals
if test -d "$home_dir"
then
	echo "Directory exists"
fi

# Multi-line commands
docker run \
	--rm \
	-it \
	-v "$home_dir:$HOME" \
	contai:latest
```

### Dockerfile

#### Base Image
- Use explicit Ubuntu version: `ubuntu:25.10`
- Never use `ubuntu:latest` - specify version number
- Update version when new Ubuntu releases are available

#### Build Arguments
```dockerfile
ARG UBUNTU_VERSION=25.10
ARG UID
ARG USERNAME
ARG GID
ARG GROUPNAME
```
- Use ARG for build-time configuration
- Always support UID/GID mapping for host compatibility

#### RUN Commands
- Chain related commands with `&&` in single RUN layers
- Use backslash `\` for line continuation
- Indent continuation lines with tabs
- Group package installations logically

#### Package Installation Order
1. System packages via `apt-get`
2. Python packages via `pip` (with `--break-system-packages`)
3. Node.js setup and npm packages
4. Binary downloads and installations

#### Example Dockerfile Pattern
```dockerfile
ARG UBUNTU_VERSION=25.10

FROM ubuntu:${UBUNTU_VERSION}

ARG UID
ARG GID

RUN apt-get update && apt-get install -y \
	package1 \
	package2 \
	package3

RUN pip install --break-system-packages \
	python-package1 \
	python-package2
```

## Data Directories

The container uses these host directories:
- `~/.local/share/contai/home`: Persistent home directory
- `~/.local/share/contai/env.list`: Environment variables for container

## Adding New Features

When modifying this project:

1. **New shell scripts**: Follow the shell style guide above
2. **New Dockerfile layers**: Group related installations, maintain layer efficiency
3. **New AI tools**: Add to npm install section in Dockerfile
4. **New system tools**: Add to apt-get install section in Dockerfile

**Important**: When making any changes to the project, especially structural changes
(adding/removing files, changing build process, modifying project conventions), update
this AGENTS.md file to reflect those changes.

## Common Tasks

### Adding a New AI Tool
1. Find the npm package name for the tool
2. Add it to the `npm install -g` section in Dockerfile
3. Rebuild: `./build.sh`
4. Test: `./contai <tool-name>`

### Adding System Packages
1. Add package to `apt-get install -y` section
2. Rebuild and test

### Debugging Container Issues
```sh
# Run container interactively
./contai bash

# Check installed tools
./contai which opencode
./contai node --version
```
