# --- Stage 1: Build the Next.js app ---
FROM node:18-alpine AS builder
WORKDIR /app

# Copy package management definitions
COPY package*.json ./

# Install all dependencies (including devDeps needed for building)
RUN npm ci

# Copy the rest of the source files
COPY . .

# Disable Next.js telemetry during build (optional)
ENV NEXT_TELEMETRY_DISABLED=1

# Run the next build export
RUN npm run build

# --- Stage 2: Serve using Nginx ---
FROM nginx:alpine AS runner
WORKDIR /usr/share/nginx/html

# Clean the default Nginx public files
RUN rm -rf ./*

# Copy the statically exported build from Stage 1 
# Note: Next.js outputs standard static builds to the "out" directory
COPY --from=builder /app/out ./

# Expose port 80 for Render routing
EXPOSE 80

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
