# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Accept Vite env vars as build args — they are baked into the static bundle
ARG VITE_API_URL
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY

# Copy package files first to optimize Docker layer caching
COPY package*.json ./

# Install dependencies with npm cache mount
RUN --mount=type=cache,target=/root/.npm \
    npm ci --prefer-offline --no-audit

# Copy source code (clean context via .dockerignore)
COPY . .

# Build static production assets
RUN npm run build

# Production runtime stage with unprivileged Nginx (non-root)
FROM nginxinc/nginx-unprivileged:alpine AS runner

# Copy custom nginx configuration
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html

# Expose unprivileged port 8080
EXPOSE 8080

# Health check against unprivileged endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
