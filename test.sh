#!/bin/bash

# Test script for Caddy Docker proxy setup

set -e

IMAGE_NAME="myimage/caddy-proxy"
TEST_NETWORK="caddy"

echo "Testing Caddy Docker proxy setup..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Create network if it doesn't exist
if ! docker network ls | grep -q "$TEST_NETWORK"; then
    echo "Creating test network: $TEST_NETWORK"
    docker network create $TEST_NETWORK
fi

# Build the image if it doesn't exist
if ! docker images | grep -q "$IMAGE_NAME"; then
    echo "Building Caddy image..."
    docker build -t "$IMAGE_NAME" .
fi

# Start a test container
echo "Starting Caddy test container..."
CONTAINER_ID=$(docker run -d \
    --name caddy-test \
    --network $TEST_NETWORK \
    -p 8080:80 \
    -p 8443:443 \
    -p 2019:2019 \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    "$IMAGE_NAME")

echo "Container started: $CONTAINER_ID"

# Wait for Caddy to start
echo "Waiting for Caddy to start..."
sleep 5

# Test basic connectivity
echo "Testing basic connectivity..."
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    echo "✓ HTTP endpoint is responding"
else
    echo "✗ HTTP endpoint is not responding"
fi

# Test admin API
echo "Testing admin API..."
if curl -f http://localhost:2019/config/ > /dev/null 2>&1; then
    echo "✓ Admin API is responding"
else
    echo "✗ Admin API is not responding"
fi

# Start a test service with labels
echo "Starting test service with Caddy labels..."
TEST_SERVICE_ID=$(docker run -d \
    --name test-service \
    --network $TEST_NETWORK \
    --label "caddy=test.local" \
    --label "caddy.reverse_proxy={{upstreams 8000}}" \
    -p 8000:8000 \
    nginx:alpine)

echo "Test service started: $TEST_SERVICE_ID"

# Wait for configuration to update
echo "Waiting for Caddy to discover the new service..."
sleep 10

# Check if Caddy discovered the service
echo "Checking Caddy configuration..."
if curl -s http://localhost:2019/config/ | grep -q "test.local"; then
    echo "✓ Caddy discovered the test service"
else
    echo "✗ Caddy did not discover the test service"
fi

echo ""
echo "Test completed. Cleaning up..."

# Cleanup
docker stop caddy-test test-service > /dev/null 2>&1 || true
docker rm caddy-test test-service > /dev/null 2>&1 || true

echo "Cleanup completed."
echo ""
echo "To run the full setup, use:"
echo "  docker-compose up -d"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f caddy"