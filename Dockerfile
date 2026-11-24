FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0 \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    NODE_VERSION=v26.13.1 \
    PATH="/home/ubuntu/.local/bin:/usr/local/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    sudo \
    git \
    openssh-client \
    openssh-server \
    gnupg \
    jq \
    iputils-ping \
    dnsutils \
    net-tools \
    docker.io \
    docker-compose-v2 \
    python3 \
    python3-pip \
    python3-venv \
    dumb-init \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-liberation \
    fonts-ipafont-gothic \
    fonts-ipafont-mincho \
    xauth \
    x11-apps \
    xvfb \
    mesa-utils \
    ffmpeg \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2t64 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

RUN id -u ubuntu >/dev/null 2>&1 || useradd -m -s /bin/bash ubuntu \
    && echo "ubuntu:0000" | chpasswd \
    && usermod -aG sudo,docker ubuntu \
    && mkdir -p /home/ubuntu/.ssh \
    && chown -R ubuntu:ubuntu /home/ubuntu \
    && chmod 700 /home/ubuntu/.ssh

RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
        amd64) NODE_ARCH="x64" ;; \
        arm64) NODE_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tar.xz

RUN npm install -g puppeteer playwright @anthropic-ai/claude-code @google/gemini-cli \
    && npx playwright install-deps chromium

USER ubuntu
RUN npx playwright install chromium \
    && (curl -fsSL https://cli.devin.ai/install.sh | bash || true) \
    && /home/ubuntu/.local/bin/devin --version

RUN echo "alias dvn='devin --permission-mode bypass'" >> /home/ubuntu/.bashrc \
    && echo "alias cld='claude --dangerously-skip-permissions'" >> /home/ubuntu/.bashrc \
    && echo "alias gmn='gemini --yolo'" >> /home/ubuntu/.bashrc \
    && echo "PS1='\[\e[31m\][VM] \[\e[94m\]\w \[\e[37m\]$ \[\e[0m\]'" >> /home/ubuntu/.bashrc

USER root

RUN printf '%s\n' \
    '#!/bin/bash' \
    'if [ -n "$HOST_GID" ] && [ "$(id -g ubuntu)" != "$HOST_GID" ]; then' \
    '  groupmod -o -g "$HOST_GID" ubuntu' \
    'fi' \
    'if [ -n "$HOST_UID" ] && [ "$(id -u ubuntu)" != "$HOST_UID" ]; then' \
    '  usermod -o -u "$HOST_UID" -g ubuntu ubuntu' \
    'fi' \
    'mkdir -p /home/ubuntu/.ssh /home/ubuntu/.config /home/ubuntu/.local/share /home/ubuntu/.claude /home/ubuntu/.gemini' \
    'if [ -n "$SSH_PUBLIC_KEY" ]; then' \
    '  echo "$SSH_PUBLIC_KEY" > /home/ubuntu/.ssh/authorized_keys' \
    '  chmod 600 /home/ubuntu/.ssh/authorized_keys' \
    'fi' \
    'chown -R ubuntu:ubuntu /home/ubuntu' \
    '/usr/sbin/sshd' \
    'if [ -n "$GIT_USER_NAME" ]; then' \
    '  su - ubuntu -c "git config --global user.name \"$GIT_USER_NAME\""' \
    'fi' \
    'if [ -n "$GIT_USER_EMAIL" ]; then' \
    '  su - ubuntu -c "git config --global user.email \"$GIT_USER_EMAIL\""' \
    'fi' \
    'su - ubuntu -c "git config --global --add safe.directory \"*\""' \
    'if [ -n "$GITHUB_TOKEN" ]; then' \
    '  su - ubuntu -c "echo \"$GITHUB_TOKEN\" | gh auth login --with-token 2>/dev/null || true"' \
    '  su - ubuntu -c "git config --global url.\"https://${GITHUB_TOKEN}@github.com/\".insteadOf \"https://github.com/\""' \
    'fi' \
    'exec "$@"' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

WORKDIR /home/ubuntu

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]

CMD ["sleep", "infinity"]
