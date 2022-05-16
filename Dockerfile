# Wait until this is resolved before upgrading to 22.04:
# https://stackoverflow.com/questions/71941032/why-i-cannot-run-apt-update-inside-a-fresh-ubuntu22-04
FROM ubuntu:20.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        pkg-config tini build-essential git \
        ccache cmake ninja-build llvm clang clang-format clang-tidy curl python3 \
        bison flex \
        brotli rsync \
        libssl-dev \
        libpthread-stubs0-dev \
        libboost-all-dev \
        firefox \
        wget gnupg ca-certificates procps libxss1 \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/google.list

SHELL ["/bin/bash", "-c"]

ENV NVM_DIR=/opt/nvm
ARG NVM_VERSION="v0.39.1"
ARG NODE_VERSION="v17.6.0"
RUN mkdir -p /opt/nvm \
    && ls -lisah /opt/nvm \
    && curl https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash \
    && source ${NVM_DIR}/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm alias default ${NODE_VERSION} \
    && nvm use default \
    && npm install --global yarn

ARG RUST_VERSION="1.60.0"
RUN export RUSTUP_HOME=/opt/rust \
    && export CARGO_HOME=/opt/rust \
    && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain ${RUST_VERSION} -y \
    && export PATH=$PATH:/opt/rust/bin \
    && rustup target add wasm32-unknown-unknown \
    && cargo install wasm-pack wrangler

ENTRYPOINT ["tini", "-v", "--", "/opt/entrypoint.sh"]
WORKDIR /github/workspace
