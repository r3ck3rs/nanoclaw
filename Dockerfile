# NanoClaw Orchestrator
# Runs the main Node.js process that spawns agent containers via Docker socket

FROM node:22-slim

# Install Docker CLI (needed to spawn agent containers)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install production dependencies only (skip husky prepare script)
RUN npm ci --omit=dev --ignore-scripts

# Copy source and build
COPY tsconfig.json ./
COPY src/ ./src/
COPY container/ ./container/

# Build TypeScript
RUN npx tsc

# Create persistent directories
RUN mkdir -p store data groups logs

ENTRYPOINT ["node", "dist/index.js"]
