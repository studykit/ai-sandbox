IMAGE_NAME   ?= ai-sandbox
HOME_VOLUME  ?= ai-sandbox-home

.PHONY: build home-volume update clean-home-volume

all: build home-volume

build:
	docker build -t $(IMAGE_NAME) .

# Create a named volume pre-populated with dotfiles and powerlevel10k
create-home-volume: 
	@if docker volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) already exists. Run 'make clean-home-volume' first to recreate."; \
		exit 1; \
	fi
	docker volume create $(HOME_VOLUME)
	docker run --rm \
		-v $(HOME_VOLUME):/home/ubuntu \
		-v "$$(pwd)/preferences":/preferences:ro \
		-v "$$(pwd)/zsh-completion":/zsh-completion:ro \
		-v "$$(pwd)/scripts/provision":/usr/local/bin/provision:ro \
		$(IMAGE_NAME) provision --init
	@echo "Volume $(HOME_VOLUME) created and populated."


# Copy config files from preferences/ and zsh-completion/ into existing volume
update:
	@if ! docker volume inspect $(HOME_VOLUME) >/dev/null 2>&1; then \
		echo "Volume $(HOME_VOLUME) does not exist. Run 'make home-volume' first."; \
		exit 1; \
	fi
	docker run --rm \
		-v $(HOME_VOLUME):/home/ubuntu \
		-v "$$(pwd)/preferences":/preferences:ro \
		-v "$$(pwd)/zsh-completion":/zsh-completion:ro \
		-v "$$(pwd)/scripts/provision":/usr/local/bin/provision:ro \
		$(IMAGE_NAME) provision
	@echo "Config files updated in volume $(HOME_VOLUME)."

clean-home-volume:
	docker volume rm -f $(HOME_VOLUME)
