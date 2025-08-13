#!/bin/bash

# Build script for custom Caddy Docker image

set -e

IMAGE_NAME="myimage/caddy-proxy"
IMAGE_TAG="latest"

echo "Building Caddy Docker image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"

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