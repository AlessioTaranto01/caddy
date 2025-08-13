# Custom Caddy Docker Image with TCP and HTTP/HTTPS Proxy Support

This repository contains a custom Caddy Docker image that supports both TCP and HTTP/HTTPS proxying with Docker Swarm label-based configuration.

## Features

- **Docker Label Discovery**: Automatically configures routes based on Docker service labels
- **TCP Proxying**: Support for Layer 4 TCP connections using caddy-l4 module
- **HTTP/HTTPS Proxying**: Standard reverse proxy functionality
- **Automatic HTTPS**: Built-in TLS certificate management
- **Docker Swarm Integration**: Works seamlessly with Docker Swarm deployments

## Building the Image

```bash
docker build -t myimage/caddy-proxy .
```

## Usage with Docker Compose

The image supports the label syntax shown in your example:

```yaml
dev-authcache:
  image: myimage/test
  networks:
    - caddy
    - default
  logging:
    driver: json-file
  deploy:
    labels:
      caddy_0: test.mydomain.com
      caddy_0.reverse_proxy: tcp://:7102
      caddy_0.tls_internal_ask: 'true'
      caddy_1: admin.test.mydomain.com
      caddy_1.reverse_proxy: '{{upstreams 9102}}'
    placement:
      constraints:
        - node.hostname == sd-165633
```

## Label Configuration

### Basic HTTP/HTTPS Proxy
```yaml
labels:
  caddy: example.com
  caddy.reverse_proxy: '{{upstreams 8080}}'
```

### TCP Proxy
```yaml
labels:
  caddy: tcp.example.com
  caddy.reverse_proxy: tcp://:3306
```

### HTTPS with Internal TLS
```yaml
labels:
  caddy: secure.example.com
  caddy.reverse_proxy: '{{upstreams 8080}}'
  caddy.tls_internal_ask: 'true'
```

### Multiple Routes
```yaml
labels:
  caddy_0: api.example.com
  caddy_0.reverse_proxy: '{{upstreams 8080}}'
  caddy_1: admin.example.com
  caddy_1.reverse_proxy: '{{upstreams 9090}}'
  caddy_1.tls_internal_ask: 'true'
```

## Required Docker Networks

Make sure to create the `caddy` network:

```bash
docker network create caddy
```

## Deployment

### Local Development

1. Build the image:
   ```bash
   ./build.sh
   ```

2. Deploy with Docker Compose:
   ```bash
   docker-compose up -d
   ```

3. Test the setup:
   ```bash
   ./test.sh
   ```

### Production Deployment

#### Manual Deployment

For Docker Swarm:
```bash
# Initialize swarm if not already done
docker swarm init

# Deploy using the deployment script
./deploy.sh
```

#### CI/CD Pipeline

The repository includes a GitHub Actions workflow that:

1. **Tests**: Validates Caddy configuration and runs container tests
2. **Builds**: Creates and pushes Docker images to Docker Hub
3. **Deploys**: Automatically deploys to Swarmpit-managed environments

**Required Secrets:**
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub password
- `SWARMPIT_API_URL`: Swarmpit API endpoint (optional)
- `SWARMPIT_TOKEN`: Swarmpit authentication token (optional)

**Deployment Triggers:**
- `main` branch: Deploys to production
- `development` branch: Deploys to development environment
- Feature branches: Runs tests only

#### Environment Variables for Deployment

```bash
export DOCKER_IMAGE="myimage/caddy-proxy:latest"
export STACK_NAME="caddy-stack"
export ENVIRONMENT="production"
export SWARMPIT_API_URL="https://your-swarmpit.com/api"
export SWARMPIT_TOKEN="your-token"

./deploy.sh
```

## Modules Included

- **caddy-docker-proxy**: Enables Docker label-based configuration
- **caddy-l4**: Provides Layer 4 (TCP/UDP) proxy capabilities

## Ports

- `80`: HTTP traffic
- `443`: HTTPS traffic
- `2019`: Caddy admin API
- `7102`: Example TCP proxy port

## Configuration Files

- `Dockerfile`: Multi-stage build with required Caddy modules
- `Caddyfile`: Base configuration with Docker proxy enabled
- `docker-compose.yml`: Example deployment configuration

## Notes

- The Docker socket must be mounted for label discovery to work
- Services must be on the same network as Caddy for proxying
- TCP proxying requires the caddy-l4 module
- Internal TLS certificates are automatically generated when `tls_internal_ask` is used