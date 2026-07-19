# ---- Build stage ----
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

# next.config.ts sets `output: "export"`, so `next build` alone produces
# a static site in ./out. We call `next build` directly (not `npm run build`)
# because package.json's build script also runs
# `npx tsx scripts/seo-validate.ts`, which is not present in the repo tree
# as of this writing and would fail the build. If you've added that
# script, swap the line below for: RUN npm run build
RUN npx next build

# ---- Runtime stage ----
FROM nginx:1.27-alpine AS runner

COPY --from=builder /app/out /usr/share/nginx/html
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Render injects PORT at runtime; nginx's official entrypoint auto-runs
# envsubst on files in /etc/nginx/templates/ before starting, writing the
# result to /etc/nginx/conf.d/default.conf.
ENV PORT=10000
EXPOSE 10000
