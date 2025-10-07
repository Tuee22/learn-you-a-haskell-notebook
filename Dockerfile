# ARM64-friendly IHaskell + JupyterLab (Ubuntu 22.04, runs as root)
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# System deps for GHC/Cabal, IHaskell, and Jupyter
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates xz-utils git patch \
    build-essential pkg-config \
    libffi-dev libgmp-dev libncurses-dev zlib1g-dev libtinfo6 \
    libzmq3-dev libmagic1 \
    python3 python3-venv python3-pip \
 && rm -rf /var/lib/apt/lists/*

# ---- Python/Jupyter in a virtualenv (avoids system pip issues) ----
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "${VIRTUAL_ENV}" \
 && "${VIRTUAL_ENV}/bin/pip" install --no-cache-dir --upgrade pip \
 && "${VIRTUAL_ENV}/bin/pip" install --no-cache-dir jupyterlab ipykernel ipywidgets
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# ---- Haskell toolchain via GHCup (ARM64 binaries) ----
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_INSTALL_STACK=never \
    BOOTSTRAP_HASKELL_GHC_VERSION=9.4.8 \
    BOOTSTRAP_HASKELL_CABAL_VERSION=recommended

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | bash -s -- -y \
 && . "/root/.ghcup/env" \
 && ghcup install ghc ${BOOTSTRAP_HASKELL_GHC_VERSION} || true \
 && ghcup set ghc ${BOOTSTRAP_HASKELL_GHC_VERSION} \
 && ghcup install cabal ${BOOTSTRAP_HASKELL_CABAL_VERSION} || true \
 && cabal update

ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:${PATH}"

# Keep cabal memory usage low and builds reproducible
RUN printf 'jobs: 1\ndocumentation: False\n' >> /root/.cabal/config || true

# ---- Install IHaskell and register the kernel ----
# Using -j1 and no docs keeps RAM low on Colima.
COPY docker/ihaskell-no-command-lint.patch /tmp/ihaskell-no-command-lint.patch
RUN . "/root/.ghcup/env" \
 && cabal get ihaskell-0.12.0.0 \
 && cd ihaskell-0.12.0.0 \
 && patch -p1 < /tmp/ihaskell-no-command-lint.patch \
 && cabal v2-install \
      -j1 \
      --disable-documentation \
      --installdir=/usr/local/bin \
      --overwrite-policy=always \
      . \
 && ihaskell install --prefix=/usr/local

# Workspace for your notebooks (bind mount lands here)
WORKDIR /root/work

EXPOSE 8888

# Start JupyterLab as root, no browser, no auth
CMD jupyter lab --ip=0.0.0.0 --no-browser --allow-root --ServerApp.token=''
