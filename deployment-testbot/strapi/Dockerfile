# Strapi build-from-source Dockerfile for TestBot
# Builds Strapi from the forked repository source code
# Supports Node.js 18.x/20.x/22.x (Strapi v5 requirements)

FROM node:20-alpine

# Install system dependencies
RUN apk add --no-cache \
    wget \
    curl \
    git \
    python3 \
    make \
    g++ \
    postgresql-client

# Enable Corepack for Yarn support (Strapi v5 uses Yarn 4.x)
RUN corepack enable

WORKDIR /opt/app

# Copy application source from the repository
COPY . .

# Install dependencies using Yarn (required for catalog: protocol support)
RUN yarn install

# Build the Strapi packages
RUN yarn build

# Change to the example app directory
WORKDIR /opt/app/examples/getstarted

# Expose Strapi port
EXPOSE 1337

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:1337/_health || exit 1

# Start Strapi in development mode from the example app
CMD ["yarn", "develop"]
