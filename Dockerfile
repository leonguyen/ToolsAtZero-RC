# ---- Build stage ----
# Using the Debian-based image (not alpine) because this project pulls in
# @huggingface/transformers -> onnxruntime-node, which ships prebuilt
# binaries for glibc and can fail to install on musl-based Alpine.
FROM node:20-bookworm-slim AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
# Using `npm install` instead of `npm ci`: the repo's package-lock.json
# is currently out of sync with package.json (missing @emnapi/* entries
# pulled in by @huggingface/transformers), which npm ci refuses to
# tolerate. If you regenerate the lockfile in the repo (see chat), you
# can switch this back to `npm ci` for reproducible installs.
RUN npm install

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
