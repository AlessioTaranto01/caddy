# Use golang image with newer Go version for building
FROM golang:1.24-alpine AS builder

# Install git and other build dependencies
RUN apk add --no-cache git

# Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build Caddy with required modules
RUN xcaddy build v2.8.4 \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2@v2.9.1 \
    --with github.com/mholt/caddy-l4@v0.0.0-20240606002807-9c79e6a80a96

# Use official Caddy image as base
FROM caddy:2.8-alpine

# Copy the custom Caddy binary
COPY --from=builder /go/caddy /usr/bin/caddy

# Create necessary directories
RUN mkdir -p /etc/caddy /var/lib/caddy

# Copy configuration
COPY Caddyfile /etc/caddy/Caddyfile

# Expose ports
EXPOSE 80 443 2019

# Set working directory
WORKDIR /srv

# Run Caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]