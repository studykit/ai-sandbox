IMAGE_NAME   ?= ai-sandbox
HOME_VOLUME  ?= ai-sandbox-home

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

all: build home-volume

build:
	docker build -t $(IMAGE_NAME) .

# Create a named volume pre-populated with dotfiles and powerlevel10k
create-home-volume:
	@if docker volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) already exists. Run 'make clean-home-volume' first to recreate."; \
		exit 1; \
	fi
	$(ensure-host-configs)
	docker volume create $(HOME_VOLUME)
	docker run --rm \
		-v $(HOME_VOLUME):/home/ubuntu:z \
		-v "$$(pwd)/preferences":/preferences:ro \
		-v "$$(pwd)/credentials":/credentials:ro \
		-v "$$(pwd)/completions/container":/completions/container:ro \
		-v "$$(pwd)/scripts/provision":/usr/local/bin/provision:ro \
		$(IMAGE_NAME) provision --init
	@echo "Volume $(HOME_VOLUME) created and populated."


# Copy config files from preferences/ and completions/ into existing volume
update:
	@if ! docker volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) does not exist. Run 'make home-volume' first."; \
		exit 1; \
	fi
	$(ensure-host-configs)
	docker run --rm \
		-v $(HOME_VOLUME):/home/ubuntu:z \
		-v "$$(pwd)/preferences":/preferences:ro \
		-v "$$(pwd)/credentials":/credentials:ro \
		-v "$$(pwd)/completions/container":/completions/container:ro \
		-v "$$(pwd)/scripts/provision":/usr/local/bin/provision:ro \
		$(IMAGE_NAME) provision
	@echo "Config files updated in volume $(HOME_VOLUME)."

# Install one or more programs into an existing volume.
# Example: make install PROGRAMS="codex playwright"
install:
	@if ! docker volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) does not exist. Run 'make home-volume' first."; \
		exit 1; \
	fi
	@if [ -z "$(PROGRAMS)" ]; then \
		echo "PROGRAMS is required."; \
		echo "Installable programs: all uv powerlevel10k codex claude opencode copilot typescript typescript-language-server pyright playwright"; \
		echo "Example: make install PROGRAMS=\"codex playwright\""; \
		exit 1; \
	fi
	docker run --rm \
		-v $(HOME_VOLUME):/home/ubuntu:z \
		-v "$$(pwd)/preferences":/preferences:ro \
		-v "$$(pwd)/credentials":/credentials:ro \
		-v "$$(pwd)/completions/container":/completions/container:ro \
		-v "$$(pwd)/scripts/provision":/usr/local/bin/provision:ro \
		$(IMAGE_NAME) provision --install $(PROGRAMS)
	@echo "Installed programs into volume $(HOME_VOLUME): $(PROGRAMS)"

clean-home-volume:
	docker volume rm -f $(HOME_VOLUME)
