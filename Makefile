IMAGE_NAME   ?= ai-sandbox
HOME_VOLUME  ?= ai-sandbox-home
DOCKER       := $(shell which docker)

.PHONY: build home-volume update install clean-home-volume

# Prompt to copy host config files if missing in preferences/
define ensure-host-configs
	@mkdir -p credentials
	@if [ ! -f credentials/codex_auth.json ]; then \
		if [ -f "$$HOME/.codex/auth.json" ]; then \
			printf "credentials/codex_auth.json not found. Copy from ~/.codex/auth.json? [y/N] "; \
			read ans; \
			case "$$ans" in \
				[yY]*) cp "$$HOME/.codex/auth.json" credentials/codex_auth.json; \
				       echo "Copied ~/.codex/auth.json → credentials/codex_auth.json";; \
				*) echo "Skipping codex auth.";; \
			esac; \
		fi; \
	fi
	@if [ ! -f credentials/claude_credentials.json ]; then \
		if [ -e "$$HOME/.claude/.credentials.json" ] && [ ! -f "$$HOME/.claude/.credentials.json" ]; then \
			echo "WARNING: ~/.claude/.credentials.json exists but is not a regular file. Skipping." >&2; \
		elif [ -f "$$HOME/.claude/.credentials.json" ]; then \
			printf "credentials/claude_credentials.json not found. Copy from ~/.claude/.credentials.json? [y/N] "; \
			read ans; \
			case "$$ans" in \
				[yY]*) cp "$$HOME/.claude/.credentials.json" credentials/claude_credentials.json; \
				       echo "Copied ~/.claude/.credentials.json → credentials/claude_credentials.json";; \
				*) echo "Skipping claude credentials.";; \
			esac; \
		fi; \
	fi
	@if [ ! -f credentials/ssh_github ]; then \
		if [ -f "$$HOME/.ssh/github.com" ]; then \
			printf "credentials/ssh_github not found. Copy from ~/.ssh/github.com? [y/N] "; \
			read ans; \
			case "$$ans" in \
				[yY]*) cp "$$HOME/.ssh/github.com" credentials/ssh_github; \
				       echo "Copied ~/.ssh/github.com → credentials/ssh_github";; \
				*) echo "Skipping ssh github key.";; \
			esac; \
		fi; \
	fi
	@if [ ! -f preferences/gitconfig ]; then \
		if [ -f "$$HOME/.gitconfig" ]; then \
			printf "preferences/gitconfig not found. Copy from ~/.gitconfig? [y/N] "; \
			read ans; \
			case "$$ans" in \
				[yY]*) cp "$$HOME/.gitconfig" preferences/gitconfig; \
				       echo "Copied ~/.gitconfig → preferences/gitconfig";; \
				*) echo "Skipping gitconfig.";; \
			esac; \
		fi; \
	fi
endef

define docker-provision
	$(DOCKER) run --rm \
		--log-driver=none \
		-v $(HOME_VOLUME):/home:z \
		-v "$$(pwd)/preferences":/preferences:ro \
		-v "$$(pwd)/credentials":/credentials:ro \
		-v "$$(pwd)/completions/container":/completions/container:ro \
		-v "$$(pwd)/scripts/provision":/usr/local/bin/provision:ro \
		$(IMAGE_NAME) provision $(1)
endef

all: build home-volume

build:
	$(DOCKER) build -t $(IMAGE_NAME) .

# Create a named volume pre-populated with dotfiles and powerlevel10k
create-home-volume:
	@if $(DOCKER) volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) already exists. Run 'make clean-home-volume' first to recreate."; \
		exit 1; \
	fi
	$(ensure-host-configs)
	$(DOCKER) volume create $(HOME_VOLUME)
	$(call docker-provision,--init)
	@echo "Volume $(HOME_VOLUME) created and populated."


# Copy config files from preferences/ and completions/ into existing volume
update:
	@if ! $(DOCKER) volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) does not exist. Run 'make home-volume' first."; \
		exit 1; \
	fi
	$(ensure-host-configs)
	$(call docker-provision)
	@echo "Config files updated in volume $(HOME_VOLUME)."

# Install one or more programs into an existing volume.
# Example: make install PROGRAMS="codex playwright"
install:
	@if ! $(DOCKER) volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) does not exist. Run 'make home-volume' first."; \
		exit 1; \
	fi
	@if [ -z "$(PROGRAMS)" ]; then \
		echo "PROGRAMS is required."; \
		echo "Installable programs: all uv deno powerlevel10k codex claude opencode copilot typescript typescript-language-server pyright homebrew playwright"; \
		echo "Example: make install PROGRAMS=\"codex playwright\""; \
		exit 1; \
	fi
	$(call docker-provision,--install $(PROGRAMS))
	@echo "Installed programs into volume $(HOME_VOLUME): $(PROGRAMS)"

clean-home-volume:
	$(DOCKER) volume rm -f $(HOME_VOLUME)
