.PHONY: image clean help install

# Installation prefix (default: ~/.local)
PREFIX ?= $(HOME)/.local
# Installation method: 'copy' or 'link' (symlink)
METHOD ?= copy
# Detect container runtime (Apple container or Docker)
RUNTIME ?= $(shell command -v container >/dev/null 2>&1 \
	&& echo container || echo docker)
# Stampfile name includes runtime so switching runtimes triggers a rebuild
STAMPFILE = .build-stamp-$(RUNTIME)

# Build the image using build.sh. The stampfile tracks when the image was last
# built, allowing make to skip rebuilding if Dockerfile and build.sh haven't
# changed.
image: $(STAMPFILE)

$(STAMPFILE): Dockerfile build.sh
	./build.sh
	touch $(STAMPFILE)

# Install contai to $(PREFIX)/bin. Creates symlinks for each AI tool so they
# can be invoked directly (e.g., 'opencode' instead of 'contai opencode').
install: contai
# Running as root requires pre-built image (can't build as root)
ifeq ($(shell id -u),0)
	@if [ ! -f .build-stamp-* ]; then \
		echo "Error: Image not built. Run 'make image' as non-root" \
			"first." >&2; \
		exit 1; \
	fi
else
	$(MAKE) image
endif
	mkdir -p $(PREFIX)/bin
ifeq ($(METHOD),copy)
	cp contai $(PREFIX)/bin/
else ifeq ($(METHOD),link)
	ln -sf $(CURDIR)/contai $(PREFIX)/bin/contai
else
	$(error METHOD must be 'copy' or 'link', got '$(METHOD)')
endif
# Create symlinks for each AI tool (contai uses basename to detect tool)
	ln -sf $(PREFIX)/bin/contai $(PREFIX)/bin/opencode
	ln -sf $(PREFIX)/bin/contai $(PREFIX)/bin/copilot
	ln -sf $(PREFIX)/bin/contai $(PREFIX)/bin/codex
	ln -sf $(PREFIX)/bin/contai $(PREFIX)/bin/gemini
	ln -sf $(PREFIX)/bin/contai $(PREFIX)/bin/claude

# Remove all images and stampfiles (full clean)
# Extract runtime name from stampfile \
# container uses 'image delete', docker uses 'rmi'
clean:
	@for stamp in .build-stamp-*; do \
		if [ -f "$$stamp" ]; then \
			runtime=$${stamp#.build-stamp-}; \
			if [ "$$runtime" = "container" ]; then \
				$$runtime image delete contai:latest 2>/dev/null \
					|| true; \
			else \
				$$runtime rmi contai:latest 2>/dev/null || true; \
			fi; \
			rm -f "$$stamp"; \
		fi; \
	done

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  image   Build the Docker image"
	@echo "  install Install contai (builds image if needed, errors if"
	@echo "          run as root without image)"
	@echo "  clean   Remove all images and stampfiles"
	@echo "  help    Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX  Installation prefix (default: ~/.local)"
	@echo "  METHOD  Installation method: 'copy' (default) or 'link'"
	@echo "  RUNTIME Container runtime: 'docker' or 'container'"
	@echo "          (default: auto-detect)"
