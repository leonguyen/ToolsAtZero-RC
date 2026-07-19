# --- Stage 1: Build the Next.js app ---
FROM node:18-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

# Compile and statically export the application to the /app/out folder
RUN npm run build

# --- Stage 2: Serve using Nginx ---
FROM nginx:alpine AS runner

# Create a custom Nginx configuration to support client-side routing
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html
RUN rm -rf ./*

# Copy the exported static build from Stage 1
COPY --from=builder /app/out ./

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

