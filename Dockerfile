ARG NODE_VERSION=20.15.1
ARG WORKDIR=/home/ghost

## Base Image used for all targets
FROM node:$NODE_VERSION-bullseye-slim AS base
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        jq \
        libjemalloc2 \
        python3 \
        tar

# Base DevContainer: for use in a Dev Container where your local code is mounted into the container
### Adding code and installing dependencies gets overridden by your local code/dependencies, so this is done in onCreateCommand
FROM base AS base-devcontainer
# Install Stripe CLI, zsh, playwright
RUN curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | tee /usr/share/keyrings/stripe.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | tee -a /etc/apt/sources.list.d/stripe.list && \
    apt update && \
    apt install -y \
        git \
        stripe \
        zsh \
        procps \
        default-mysql-client && \
    npx -y playwright@1.46.1 install --with-deps

ENV NX_DAEMON=true
ENV YARN_CACHE_FOLDER=/workspaces/ghost/.yarncache

EXPOSE 2368
EXPOSE 4200
EXPOSE 4173
EXPOSE 41730
EXPOSE 4175
EXPOSE 4176
EXPOSE 4177
EXPOSE 4178
EXPOSE 6174
EXPOSE 7173
EXPOSE 7174


# Full Devcontainer Stage: Add the code and install dependencies
### This is a full devcontainer with all the code and dependencies installed
### Useful in an environment like Github Codespaces where you don't mount your local code into the container
FROM base-devcontainer AS full-devcontainer
WORKDIR $WORKDIR
COPY ../../ .
RUN pnpm install

# Development Stage: alternative entrypoint for development with some caching optimizations
FROM base-devcontainer AS development

WORKDIR $WORKDIR

COPY ../../ .


ENTRYPOINT ["./.devcontainer/.docker/development.entrypoint.sh"]
CMD ["yarn", "dev"]
