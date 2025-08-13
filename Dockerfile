FROM caddy:2.7-builder AS builder

# Build Caddy with required modules
RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
    --with github.com/mholt/caddy-l4

FROM caddy:2.7

# Copy the custom Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

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