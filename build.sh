#!/bin/bash

# Build script for custom Caddy Docker image

set -e

IMAGE_NAME="myimage/caddy-proxy"
IMAGE_TAG="latest"

echo "Building Caddy Docker image..."

# Try building with the main Dockerfile first
if docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" . 2>/dev/null; then
    echo "✅ Image built successfully with latest versions: ${IMAGE_NAME}:${IMAGE_TAG}"
else
    echo "⚠️  Build failed with main Dockerfile, trying compatible version..."
    
    # Fallback to simple Dockerfile
    if docker build -f Dockerfile.simple -t "${IMAGE_NAME}:${IMAGE_TAG}" .; then
        echo "✅ Image built successfully with compatible versions: ${IMAGE_NAME}:${IMAGE_TAG}"
        echo "📝 Note: Using older module versions for compatibility"
        
        # Copy the simple Caddyfile for compatibility
        if [ -f "Caddyfile.simple" ]; then
            cp Caddyfile.simple Caddyfile
            echo "📄 Updated Caddyfile for compatibility"
        fi
    else
        echo "❌ Build failed with both Dockerfiles"
        exit 1
    fi
fi

# Optional: Create the caddy network if it doesn't exist
if ! docker network ls | grep -q "caddy"; then
    echo "Creating caddy network..."
    docker network create caddy
else
    echo "Caddy network already exists"
fi

echo "Build complete! You can now use the image with:"
echo "  docker-compose up -d"
echo "  or"
echo "  docker stack deploy -c docker-compose.yml caddy-stack"

echo ""
echo "To test the image:"
echo "  docker run -d -p 80:80 -p 443:443 -p 2019:2019 \\"
echo "    -v /var/run/docker.sock:/var/run/docker.sock:ro \\"
echo "    --network caddy \\"
echo "    ${IMAGE_NAME}:${IMAGE_TAG}"