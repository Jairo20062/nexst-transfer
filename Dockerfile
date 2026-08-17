# Stage 1: Frontend dependencies
FROM node:24-alpine AS frontend-dependencies
WORKDIR /opt/app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

# Stage 2: Build frontend
FROM node:24-alpine AS frontend-builder
WORKDIR /opt/app
COPY ./frontend .
COPY --from=frontend-dependencies /opt/app/node_modules ./node_modules
RUN npm run build

# Stage 3: Backend dependencies
FROM node:24-alpine AS backend-dependencies
RUN apk add --no-cache python3
WORKDIR /opt/app
COPY backend/package.json backend/package-lock.json ./
RUN npm ci

# Stage 4: Build backend
FROM node:24-alpine AS backend-builder
RUN apk add openssl

WORKDIR /opt/app
COPY ./backend .
COPY --from=backend-dependencies /opt/app/node_modules ./node_modules
RUN npx prisma generate
RUN npm run build && npx tsc prisma/seed/config.seed.ts --outDir dist/prisma/seed --rootDir prisma/seed && npm prune --production

# Stage 5: Common Alpine runtime base shared by every final image below
FROM node:24-alpine AS base-runner
ENV NODE_ENV=docker

# Delete default node user
RUN deluser --remove-home node

RUN apk update --no-cache \
    && apk upgrade --no-cache \
    && apk add --no-cache curl su-exec openssl \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

# Stage 6: Frontend-only runtime image (Next.js standalone server, no backend/Caddy).
# Used for split frontend/backend deployments, e.g. two separate Coolify services.
FROM base-runner AS frontend-runner

WORKDIR /opt/app/frontend
COPY --from=frontend-builder /opt/app/public ./public
COPY --from=frontend-builder /opt/app/.next/standalone ./
COPY --from=frontend-builder /opt/app/.next/static ./.next/static
COPY --from=frontend-builder /opt/app/public/img /tmp/img

WORKDIR /opt/app
COPY ./scripts/docker ./scripts/docker

EXPOSE 3000
ENV PORT=3000
ENV DATA_DIRS="/opt/app/frontend/public"

HEALTHCHECK --interval=10s --timeout=3s --start-period=30s CMD curl -fs http://localhost:${PORT:-3000}/ || exit 1

ENTRYPOINT ["sh", "./scripts/docker/create-user.sh"]
CMD ["sh", "./scripts/docker/entrypoint-frontend.sh"]

# Stage 7: Backend-only runtime image (NestJS API, no frontend/Caddy).
# Used for split frontend/backend deployments, e.g. two separate Coolify services.
FROM base-runner AS backend-runner

WORKDIR /opt/app/backend
COPY --from=backend-builder /opt/app/node_modules ./node_modules
RUN rm -rf ./node_modules/typescript \
           ./node_modules/esbuild \
           ./node_modules/@esbuild \
           ./node_modules/.bin/tsc \
           ./node_modules/.bin/esbuild
COPY --from=backend-builder /opt/app/dist ./dist
COPY --from=backend-builder /opt/app/prisma ./prisma
COPY --from=backend-builder /opt/app/package.json ./
COPY --from=backend-builder /opt/app/tsconfig.json ./

WORKDIR /opt/app
COPY ./scripts/docker ./scripts/docker

EXPOSE 8080
ENV BACKEND_PORT=8080
# The backend writes admin-uploaded logo/favicon/PWA icons into the frontend's
# public/img folder (see backend/src/config/logo.service.ts), so that path
# needs to exist here too and share a volume with the frontend container.
ENV DATA_DIRS="/opt/app/backend/data /opt/app/frontend/public/img"

HEALTHCHECK --interval=10s --timeout=3s --start-period=90s CMD curl -fs http://localhost:${BACKEND_PORT:-8080}/api/health || exit 1

ENTRYPOINT ["sh", "./scripts/docker/create-user.sh"]
CMD ["sh", "./scripts/docker/entrypoint-backend.sh"]

# Stage 8: Combined image (frontend + backend + built-in Caddy in one container).
# This is the default target (`docker build .` with no --target) for simple,
# single-container deployments. Kept last so it stays the default.
FROM base-runner AS runner

RUN apk add --no-cache caddy

WORKDIR /opt/app/frontend
COPY --from=frontend-builder /opt/app/public ./public
COPY --from=frontend-builder /opt/app/.next/standalone ./
COPY --from=frontend-builder /opt/app/.next/static ./.next/static
COPY --from=frontend-builder /opt/app/public/img /tmp/img

WORKDIR /opt/app/backend
COPY --from=backend-builder /opt/app/node_modules ./node_modules
RUN rm -rf ./node_modules/typescript \
           ./node_modules/esbuild \
           ./node_modules/@esbuild \
           ./node_modules/.bin/tsc \
           ./node_modules/.bin/esbuild
COPY --from=backend-builder /opt/app/dist ./dist
COPY --from=backend-builder /opt/app/prisma ./prisma
COPY --from=backend-builder /opt/app/package.json ./
COPY --from=backend-builder /opt/app/tsconfig.json ./

WORKDIR /opt/app

COPY ./reverse-proxy  /opt/app/reverse-proxy
COPY ./scripts/docker ./scripts/docker

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=90s CMD /bin/sh -c '(if [[ "$CADDY_DISABLED" = "true" ]]; then curl -fs http://localhost:${BACKEND_PORT:-8080}/api/health; else curl -fs http://localhost:3000/api/health; fi) || exit 1'

ENTRYPOINT ["sh", "./scripts/docker/create-user.sh"]
CMD ["sh", "./scripts/docker/entrypoint.sh"]
