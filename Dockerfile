FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=24
ENV TZ=Asia/Seoul \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    SHELL=/usr/bin/zsh \
    HOME=/home/ubuntu \
    NPM_CONFIG_PREFIX=/home/ubuntu/.npm-global \
    PATH=/home/ubuntu/.opencode/bin:/home/ubuntu/.local/bin:/home/ubuntu/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bzip2 \
        ca-certificates \
        coreutils \
        curl \
        diffutils \
        direnv \
        emacs \
        file \
        findutils \
        gawk \
        git \
        gnupg \
        grep \
        gzip \
        jq \
        less \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libgbm1 \
        libgtk-3-0 \
        libexpat1 \
        locales \
        make \
        libasound2t64 \
        libcups2t64 \
        libdrm2 \
        libfontconfig1 \
        libglib2.0-0t64 \
        libnspr4 \
        libnss3 \
        libu2f-udev \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        xauth \
        xvfb \
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
        fonts-liberation \
        python-is-python3 \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo Asia/Seoul > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm cache clean --force \
    && rm -rf /home/ubuntu/.npm \
    && mkdir -p -m 755 /etc/apt/keyrings /etc/apt/sources.list.d \
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && usermod -s /usr/bin/zsh -aG sudo ubuntu \
    && printf '%s\n' 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu \
    && mkdir -p /workspace \
    && chown ubuntu:ubuntu /workspace

USER ubuntu

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["zsh"]
