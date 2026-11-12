# Base image for the XiHan.UI per-workspace Orca environment.
#
# Build it with scripts/orca-vm/docker-base-image.sh, which downloads and
# checksum-verifies the Orca server tarball into the build context first.
# Debian (glibc) is required: the Orca server tarball targets linux-x64-glibc.
FROM node:24-bookworm-slim

ARG ORCA_SERVER_TARBALL=orca-server-linux-x64.tar.gz
ARG REPO_URL=https://github.com/TW199501/XiHan.UI.git
ARG REPO_REF=dev
ARG PROJECT_ROOT=/home/orca/XiHan.UI
ARG USER_NAME=orca
ARG USER_UID=1001

ENV DEBIAN_FRONTEND=noninteractive \
    GIT_ASKPASS=/usr/local/bin/orca-git-askpass \
    GIT_TERMINAL_PROMPT=0 \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    ORCA_PROJECT_ROOT=${PROJECT_ROOT}

# Base tooling. gh comes from GitHub's own apt repository.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl git gnupg jq less openssh-client procps python3 ripgrep tini unzip xz-utils; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    chmod 0644 /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh; \
    rm -rf /var/lib/apt/lists/*

# Orca headless server runtime. It bundles its own Node, so it does not touch
# the Node that builds the repo.
COPY ${ORCA_SERVER_TARBALL} /tmp/orca-server.tar.gz
RUN set -eux; \
    mkdir -p /opt/orca-server; \
    tar -xzf /tmp/orca-server.tar.gz -C /opt/orca-server --strip-components=1; \
    rm -f /tmp/orca-server.tar.gz; \
    ln -s /opt/orca-server/bin/orca-ide /usr/local/bin/orca-ide; \
    orca-ide --version

# Coding-agent CLIs. They are signed in once in the auth image, not here.
RUN npm install -g --no-fund --no-audit @anthropic-ai/claude-code @openai/codex \
    && claude --version && codex --version

COPY bin/ /usr/local/bin/
RUN chmod 0755 /usr/local/bin/orca-git-askpass /usr/local/bin/orca-serve-recipe /usr/local/bin/orca-sync-repo

RUN set -eux; \
    useradd --create-home --shell /bin/bash --uid "${USER_UID}" "${USER_NAME}"; \
    install -d -o "${USER_NAME}" -g "${USER_NAME}" "$(dirname "${PROJECT_ROOT}")"

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Warm checkout plus dependency install, so per-workspace create only fetches.
RUN set -eux; \
    git config --global advice.detachedHead false; \
    git config --global init.defaultBranch main; \
    git clone --branch "${REPO_REF}" "${REPO_URL}" "${PROJECT_ROOT}"; \
    cd "${PROJECT_ROOT}"; \
    git remote add upstream https://github.com/XiHanFun/XiHan.UI.git; \
    corepack enable --install-directory /home/${USER_NAME}/.local/bin
ENV PATH=/home/${USER_NAME}/.local/bin:${PATH}
RUN set -eux; \
    cd "${PROJECT_ROOT}/ui"; \
    pnpm install --frozen-lockfile

WORKDIR ${PROJECT_ROOT}
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]
