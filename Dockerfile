FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=24
ARG CARBONYL_NPM_PACKAGE=carbonyl@latest

ENV TZ=Asia/Seoul \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    SHELL=/usr/bin/zsh \
    HOME=/home/ubuntu \
    BROWSER=/usr/local/bin/open-browser \
    NPM_CONFIG_PREFIX=/home/ubuntu/.npm-global \
    PATH=/home/ubuntu/.local/bin:/home/ubuntu/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bzip2 \
        ca-certificates \
        coreutils \
        curl \
        diffutils \
        file \
        findutils \
        gawk \
        git \
        gnupg \
        grep \
        gzip \
        jq \
        less \
        libexpat1 \
        locales \
        make \
        libasound2t64 \
        libfontconfig1 \
        libnss3 \
        openssh-client \
        patch \
        perl \
        pkg-config \
        procps \
        psmisc \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        sed \
        sudo \
        tar \
        tini \
        tmux \
        tree \
        unzip \
        util-linux \
        vim \
        wget \
        xdg-utils \
        xz-utils \
        zip \
        zsh \
        build-essential \
        fd-find \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo Asia/Seoul > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "${CARBONYL_NPM_PACKAGE}" \
    && npm cache clean --force

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && ln -sf /usr/bin/pip3 /usr/local/bin/pip \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && printf '%s\n' '#!/usr/bin/env bash' 'exec carbonyl "$@"' > /usr/local/bin/open-browser \
    && chmod +x /usr/local/bin/open-browser \
    && ln -sf /usr/local/bin/open-browser /usr/local/bin/x-www-browser \
    && ln -sf /usr/local/bin/open-browser /usr/local/bin/gnome-www-browser \
    && if ! id -u ubuntu >/dev/null 2>&1; then useradd --create-home --shell /usr/bin/zsh ubuntu; fi \
    && usermod -aG sudo ubuntu \
    && printf '%s\n' 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu \
    && grep -q '^auth\s\+sufficient\s\+pam_wheel.so trust group=sudo$' /etc/pam.d/su || sed -i '/^auth\s\+sufficient\s\+pam_rootok.so$/a auth sufficient pam_wheel.so trust group=sudo' /etc/pam.d/su \
    && mkdir -p /home/ubuntu/.local/bin /home/ubuntu/.npm-global /workspace \
    && chown -R ubuntu:ubuntu /home/ubuntu /workspace \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 bootstrap-agents /usr/local/bin/bootstrap-agents
COPY --chown=ubuntu:ubuntu tmux.conf /usr/local/share/default-tmux.conf

WORKDIR /workspace
USER ubuntu

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["zsh"]
