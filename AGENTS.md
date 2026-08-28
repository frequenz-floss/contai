# AGENTS.md

This file provides guidance for AI coding agents working in the contai repository.

## Project Overview

contai is a Docker-based sandbox for running AI CLI tools (OpenCode, GitHub Copilot,
OpenAI Codex, Google Gemini, Claude Code, RTK) in isolation. It's a minimal project
with shell scripts and a Dockerfile - no package.json, no TypeScript, no complex build
system.

Read README.md for complete project documentation including features and usage.

## Project Structure

```
contai/
├── AGENTS.md              # This file - AI agent instructions
├── README.md              # Project documentation
├── Dockerfile             # Container definition with dev tools
├── build.sh               # Build script with user permission handling
├── contai                 # Container runner script
├── contai-bootstrap       # Runtime container bootstrap for RTK setup
└── agent-instructions.md  # Global agent instructions for end users
```

## Build Commands

| Command      | Description                                              |
|--------------|----------------------------------------------------------|
| `./build.sh` | Builds Docker image tagged as `contai:latest`            |
| `./contai`   | Runs the container with current directory mounted        |

### Building the Container

```sh
./build.sh
```

The build script passes host UID/GID to ensure proper file permissions inside the container.

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
4. Verifying binary-installed tools work: `./contai rtk --version`
5. Verifying RTK bootstrap writes the expected runtime config for shipped tools

## Linting

No project-level linting is configured. However, the container includes these tools:
- Shell: `shellcheck`, `shfmt`
- Python: `ruff`, `flake8`, `pylint`, `mypy`, `black`, `isort`

To lint shell scripts locally (if shellcheck is installed):
```sh
shellcheck build.sh contai contai-bootstrap
shfmt -d build.sh contai contai-bootstrap
```

## Code Style Guidelines

### Shell Scripts

All shell scripts in this project follow these conventions:

#### Shebang and Error Handling
```sh
#!/bin/sh
set -eu
```
- Prefer `#!/bin/sh` (POSIX shell): these scripts run on the host, before
  the container exists, so the fewer things they need the better
- Use `#!/usr/bin/env bash` only when a script genuinely needs bash, and say
  why. `contai` does, for arrays: it builds lists of arguments of unknown
  length and has to keep every element quoted, which POSIX `sh` cannot express
  without either `eval` or juggling the positional parameters. Prefer `env`
  over `#!/bin/bash`, as bash is not at that path everywhere, and list the
  requirement in the README
- Always include `set -eu` immediately after the shebang
  - `-e`: Exit immediately on command failure
  - `-u`: Treat unset variables as errors
  - with bash, note that `"${array[@]}"` on an empty array needs bash 4.4
    or newer under `-u`

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
3. **New AI tools**: Add to the appropriate Dockerfile install section
   (`npm install -g` for npm CLIs, release downloads for shipped binaries)
4. **New system tools**: Add to apt-get install section in Dockerfile
5. **Runtime tool initialization**: Keep startup logic in `contai-bootstrap`
   when it depends on the mounted container home or current project

**Important**: When making any changes to the project, especially structural changes
(adding/removing files, changing build process, modifying project conventions), update
this AGENTS.md file to reflect those changes.

## Common Tasks

### Adding a New AI Tool
1. Determine whether the tool should be installed from npm or release binaries
2. Add it to the matching install section in Dockerfile
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
