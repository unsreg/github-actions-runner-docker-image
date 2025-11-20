ARG BASE_IMAGE="ubuntu:24.04"
ARG RUNNER_VERSION="2.330.0"

FROM ${BASE_IMAGE}

ARG RUNNER_VERSION="${RUNNER_VERSION}"
ENV USER_NAME="github-actions-runner"
ENV WORK_DIR="/home/${USER_NAME}/actions-runner"

RUN DEBIAN_FRONTEND=noninteractive \
    && apt update -y \
    && apt upgrade -y \
    && apt autoremove -y \
    && apt install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        gnupg \
        jq \
        libffi-dev \
        libicu-dev \
        libssl-dev \
        lsb-release \
        sudo \
        tini \
    # Install Docker CLI for job container builds
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt update \
    && apt install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Create runner user
RUN useradd -m -s /bin/bash ${USER_NAME}

# Create working directory and set permissions
RUN mkdir -p ${WORK_DIR} \
    && chown -R ${USER_NAME}:${USER_NAME} ${WORK_DIR}

WORKDIR ${WORK_DIR}

# Download and extract GitHub Actions runner
RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R ${USER_NAME}:${USER_NAME} ${WORK_DIR}

# Copy entrypoint script
COPY --chmod=0755 ./start.sh ./start.sh

RUN chown -R ${USER_NAME}:${USER_NAME} ${WORK_DIR}

LABEL org.opencontainers.image.title="github-actions-runner-docker-image" \
    org.opencontainers.image.version="${RUNNER_VERSION}" \
    org.opencontainers.image.source="https://github.com/unsreg/github-actions-runner-docker-image"

USER ${USER_NAME}

# Entrypoint runs the registration and runner process. tini is used to properly handle signals.
ENTRYPOINT ["/usr/bin/tini", "--", "./start.sh"]
