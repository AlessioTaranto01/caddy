#!/bin/bash

# Deployment script for Caddy proxy with Swarmpit integration

set -e

# Configuration
IMAGE_NAME="${DOCKER_IMAGE:-myimage/caddy-proxy:latest}"
STACK_NAME="${STACK_NAME:-caddy-stack}"
SWARMPIT_API_URL="${SWARMPIT_API_URL}"
SWARMPIT_TOKEN="${SWARMPIT_TOKEN}"
ENVIRONMENT="${ENVIRONMENT:-production}"

echo "🚀 Deploying Caddy Proxy"
echo "Image: $IMAGE_NAME"
echo "Stack: $STACK_NAME"
echo "Environment: $ENVIRONMENT"
echo ""

# Function to check if running in Docker Swarm mode
check_swarm_mode() {
    if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
        echo "❌ Docker Swarm mode is not active"
        echo "To initialize swarm mode, run: docker swarm init"
        exit 1
    fi
    echo "✅ Docker Swarm mode is active"
}

# Function to create networks if they don't exist
setup_networks() {
    echo "📡 Setting up networks..."
    
    if ! docker network ls --filter "name=caddy" --format "{{.Name}}" | grep -q "^caddy$"; then
        echo "Creating caddy network..."
        docker network create --driver overlay --attachable caddy
    else
        echo "✅ Caddy network already exists"
    fi
}

# Function to deploy using Docker Stack
deploy_stack() {
    echo "📦 Deploying stack: $STACK_NAME"
    
    # Update image in docker-compose.yml for deployment
    sed "s|image: myimage/caddy-proxy|image: $IMAGE_NAME|g" docker-compose.yml > docker-compose.deploy.yml
    
    # Deploy the stack
    docker stack deploy -c docker-compose.deploy.yml "$STACK_NAME"
    
    # Clean up temporary file
    rm -f docker-compose.deploy.yml
    
    echo "✅ Stack deployed successfully"
}

# Function to update service via Swarmpit API
update_via_swarmpit() {
    if [ -z "$SWARMPIT_API_URL" ] || [ -z "$SWARMPIT_TOKEN" ]; then
        echo "⚠️  Swarmpit API credentials not provided, skipping API update"
        return
    fi
    
    echo "🔄 Updating service via Swarmpit API..."
    
    # Get service ID (assuming service name is caddy-stack_caddy)
    SERVICE_NAME="${STACK_NAME}_caddy"
    
    # Update service image via Swarmpit API
    curl -X POST "$SWARMPIT_API_URL/services/$SERVICE_NAME/update" \
        -H "Authorization: Bearer $SWARMPIT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"image\": \"$IMAGE_NAME\",
            \"forceUpdate\": true
        }" \
        --fail --silent --show-error
    
    echo "✅ Service updated via Swarmpit API"
}

# Function to wait for deployment to complete
wait_for_deployment() {
    echo "⏳ Waiting for deployment to complete..."
    
    SERVICE_NAME="${STACK_NAME}_caddy"
    
    # Wait for service to be running
    for i in {1..30}; do
        if docker service ps "$SERVICE_NAME" --filter "desired-state=running" --format "{{.CurrentState}}" | grep -q "Running"; then
            echo "✅ Service is running"
            return 0
        fi
        echo "Waiting... ($i/30)"
        sleep 10
    done
    
    echo "❌ Deployment timeout"
    return 1
}

# Function to run health checks
health_check() {
    echo "🏥 Running health checks..."
    
    # Get service endpoint
    SERVICE_NAME="${STACK_NAME}_caddy"
    
    # Check if service is accessible (assuming it's exposed on port 80)
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        echo "✅ HTTP endpoint is healthy"
    else
        echo "⚠️  HTTP endpoint check failed"
    fi
    
    # Check admin API
    if curl -f http://localhost:2019/config/ > /dev/null 2>&1; then
        echo "✅ Admin API is healthy"
    else
        echo "⚠️  Admin API check failed"
    fi
}

# Main deployment flow
main() {
    echo "Starting deployment process..."
    
    check_swarm_mode
    setup_networks
    deploy_stack
    
    # Update via Swarmpit if credentials are provided
    update_via_swarmpit
    
    # Wait for deployment and run health checks
    if wait_for_deployment; then
        health_check
        echo ""
        echo "🎉 Deployment completed successfully!"
        echo "📊 View services: docker service ls"
        echo "📋 View logs: docker service logs ${STACK_NAME}_caddy"
        echo "🌐 Access admin: http://localhost:2019"
    else
        echo "❌ Deployment failed"
        exit 1
    fi
}

# Run main function
main "$@"