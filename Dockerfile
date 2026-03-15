FROM debian:trixie

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=24
ENV TZ=Asia/Seoul \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    SHELL=/usr/bin/zsh \
    HOME=/home/debian \
    NPM_CONFIG_PREFIX=/home/debian/.npm-global \
    PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/debian/.deno/bin:/home/debian/.opencode/bin:/home/debian/.local/bin:/home/debian/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN sed -i -e 's|http://deb.debian.org/debian|http://ftp.kaist.ac.kr/debian|g' \
           -e 's|http://deb.debian.org/debian-security|http://ftp.kaist.ac.kr/debian-security|g' \
           /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
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
        git-lfs \
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
        libasound2 \
        libcups2 \
        libdrm2 \
        libfontconfig1 \
        libglib2.0-0 \
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
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && sed -i '/^#\s*en_US.UTF-8/s/^#\s*//' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && echo Asia/Seoul > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm cache clean --force \
    && rm -rf /home/debian/.npm \
    && mkdir -p -m 755 /etc/apt/keyrings /etc/apt/sources.list.d \
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && useradd -m -s /usr/bin/zsh -G sudo debian \
    && printf '%s\n' 'debian ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/debian \
    && chmod 0440 /etc/sudoers.d/debian \
    && mkdir -p /workspace \
    && chown debian:debian /workspace

USER debian

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["zsh"]
