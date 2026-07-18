# Containerized Codex CLI runner for install smoke (spec AC-010/AC-016, milestone AC-035).
#
# The CLI version is pinned in ONE place — runtimes/codex/adapter.yaml
# (codex_cli_version) — and injected here as a build-arg by the
# install-smoke-codex workflow. The default below is a fallback for local
# builds only; CI always passes the adapter.yaml value.
#
# Local run:
#   docker build -t add-codex-smoke --build-arg CODEX_CLI_VERSION=$(grep '^codex_cli_version' runtimes/codex/adapter.yaml | cut -d'"' -f2) tests/smoke/codex
#   docker run --rm -v "$PWD":/work -e OPENAI_API_KEY add-codex-smoke bash tests/smoke/codex/run-smoke.sh

ARG CODEX_CLI_VERSION=0.144.5

FROM node:22-slim

ARG CODEX_CLI_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends git jq python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g "@openai/codex@${CODEX_CLI_VERSION}"

# Surface the pin to the smoke script so it can assert `codex --version` matches.
ENV EXPECTED_CODEX_CLI_VERSION=${CODEX_CLI_VERSION}

WORKDIR /work
