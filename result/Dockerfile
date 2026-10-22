FROM node:26-trixie-slim@sha256:d844f1e8928a5c77d26cb8ed37d7425e27014aff39d10f4194716c215fef7398

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

COPY package*.json ./

RUN npm ci && \
    npm cache clean --force && \
    mv /usr/local/app/node_modules /node_modules

COPY . .

ENV PORT=80 \
    PG_HOST=db \
    PG_PORT=5432 \
    PG_USER=postgres \
    PG_DATABASE=postgres

EXPOSE 80

# node, the unprivileged user the Node image ships
USER 1000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]