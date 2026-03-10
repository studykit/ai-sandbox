# ai-sandbox

Ubuntu-based Docker image for running `codex`, `claude`, `opencode`, `copilot`, and `carbonyl` from an interactive `zsh` shell.

## Included tools

- AI CLIs: `codex`, `claude`, `opencode`, `copilot` via `bootstrap-agents`
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
docker build -t ai-sandbox:latest .
```

## Run

Run the helper script from the host project directory you want to work in:

```bash
./ai-shell
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

- starts the container in `zsh`
- mounts the current host directory into the container at the exact same absolute path
- sets the container working directory to that same path
- mounts a persistent Docker volume to `/home/ubuntu` so agent binaries, login state, and settings survive container restarts
- bind-mounts host `~/.codex` to `/home/ubuntu/.codex` so Codex CLI auth state is shared with the host

## Bootstrap agents

The image includes runtimes and shared tools, but the agent binaries are installed into the mounted `/home/ubuntu` volume on demand.

Run this once inside the container:

```bash
bootstrap-agents
```

What it installs into the `/home/ubuntu` volume:

- `codex` via npm into `/home/ubuntu/.npm-global/bin`
- `claude` via `https://claude.ai/install.sh`
- `opencode` via `https://opencode.ai/install`
- `copilot` via `https://gh.io/copilot-install`

Because `/home/ubuntu` is a persistent Docker volume, you usually only need to run `bootstrap-agents` once per volume.

Inside the shell, run whichever agent you want:

```bash
codex
claude
opencode
copilot
```

`codex` reuses the host login state via the `~/.codex` bind mount. Other agents still store their login state in the Docker volume mounted at `/home/ubuntu`.

## Script options

You can override the defaults with environment variables:

```bash
IMAGE_NAME=my-ai-image:dev HOME_VOLUME=my-ai-home ./ai-shell
```

Optional variables:

- `IMAGE_NAME`: image tag to run, default `ai-sandbox:latest`
- `HOME_VOLUME`: Docker volume name mounted at `/home/ubuntu`, default `ai-sandbox-home`
- `CONTAINER_NAME`: optional explicit container name

## Notes

- The container runs as user `ubuntu`.
- Default browser-related calls inside the container resolve to `carbonyl`.
- Agent binaries are installed into the mounted `/home/ubuntu` volume by `bootstrap-agents`.
- `ai-shell` creates host `~/.codex` if needed and bind-mounts it into the container.
- The image opens a shell only. It does not auto-run any agent.
- Host and container share the same visible workspace path when launched through `ai-shell`.
