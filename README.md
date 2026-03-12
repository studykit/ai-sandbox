# ai-sandbox

Ubuntu-based Docker image for running `codex`, `claude`, `opencode`, `copilot`, and `carbonyl` from an interactive `zsh` shell.

## Included tools

- AI CLIs: `codex`, `claude`, `opencode`, `copilot`
- Terminal browser: `carbonyl`
- Runtimes: `node`, `npm`, `python`, `python3`, `pip`, `uv`, `perl`
- Common tools: `awk`, `sed`, `grep`, `find`, `fd`, `rg`, `jq`, `git`, `curl`, `wget`, `make`, `patch`, `tar`, `zip`, `unzip`, `tree`, `tmux`

## Build

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ai-sandbox:latest \
  --push \
  .
```

If you only need a local build for the current architecture:

```bash
make build
```

## Setup

Create and provision the persistent home volume:

```bash
make home-volume
```

This runs `scripts/provision --init`, which:

- Copies dotfiles and preferences from `preferences/` into `/home/ubuntu`
- Copies zsh completions from `completions/container/` into `/home/ubuntu/.local/zsh/completion/`
- Clones powerlevel10k
- Installs `uv`
- Installs agent CLIs (`codex`, `claude`, `opencode`, `copilot`)
- Installs global npm language tools (`typescript`, `typescript-language-server`, `pyright`)

Because `/home/ubuntu` is a persistent Docker volume, you only need to run this once per volume.

## Update configs

To re-sync dotfiles and preferences into an existing volume without reinstalling agents:

```bash
make update
```

## Reset

To destroy and recreate the home volume from scratch:

```bash
make clean-home-volume
make home-volume
```

## Run

Run the helper script from the host project directory you want to work in:

```bash
./ai-shell
```

If you want the container to open directly into iTerm2 tmux control mode:

```bash
./ai-shell --tmux

# Or set an explicit tmux session name
./ai-shell --tmux my-session
./ai-shell --tmux=my-session
```

You can also run the container directly. `-it` is required so `zsh` and the agent CLIs can use an interactive TTY:

```bash
docker run --rm -it \
  --mount type=bind,source="$(pwd)",target="$(pwd)" \
  --mount type=volume,source=ai-sandbox-home,target=/home/ubuntu \
  --mount type=bind,source="$HOME/.codex",target=/home/ubuntu/.codex \
  -w "$(pwd)" \
  ai-sandbox:latest zsh
```

What the script does:

- starts the container in `zsh` by default
- can start the container in `tmux -CC` with `--tmux`
- uses the current working directory name as the default tmux session name for `--tmux`
- mounts the current host directory into the container at the exact same absolute path
- sets the container working directory to that same path
- mounts a persistent Docker volume to `/home/ubuntu` so agent binaries, login state, and settings survive container restarts
- bind-mounts host `~/.codex` to `/home/ubuntu/.codex` so Codex CLI auth state is shared with the host

Inside the shell, run whichever agent you want:

```bash
codex
claude
opencode
copilot
```

## Passing environment variables

Use `-e` to forward host environment variables into the container:

```bash
# Forward by name (reads the current value from the host shell)
./ai-shell -e OPENAI_API_KEY -e ANTHROPIC_API_KEY

# Set an explicit value
./ai-shell -e DEBUG=1

# Mix both forms
./ai-shell -e OPENAI_API_KEY -e MY_VAR=hello
```

### Host-side tab completion

`completions/host/_ai-shell` provides zsh completion for the `-e` flag, suggesting host environment variable names on Tab.

To enable it, add to your `~/.zshrc`:

```zsh
fpath=(/path/to/ai-sandbox/completions/host $fpath)
autoload -Uz compinit && compinit
```

## Script options

You can override the defaults with environment variables:

```bash
IMAGE_NAME=my-ai-image:dev HOME_VOLUME=my-ai-home ./ai-shell
```

Optional variables:

- `IMAGE_NAME`: image tag to run, default `ai-sandbox:latest`
- `HOME_VOLUME`: Docker volume name mounted at `/home/ubuntu`, default `ai-sandbox-home`
- `CONTAINER_NAME`: optional explicit container name
- `TMUX_SESSION_NAME`: tmux session name used with `./ai-shell --tmux` when no CLI session name is provided; default behavior uses the current working directory name

## Completions directory

```
completions/
├── host/          # Loaded by the host zsh (e.g. _ai-shell)
└── container/     # Copied into the container during provisioning (e.g. _claude, _gemini)
```

## Notes

- The container runs as user `ubuntu`.
- Default browser-related calls inside the container resolve to `carbonyl`.
- `ai-shell` creates host `~/.codex` if needed and bind-mounts it into the container.
- The image opens a shell only. It does not auto-run any agent.
- Host and container share the same visible workspace path when launched through `ai-shell`.
