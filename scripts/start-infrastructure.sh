#!/bin/bash

# Community Connect - Start Infrastructure Services
# This script starts only the infrastructure services (databases, cache, message queue)
# without starting the application services.

set -e  # Exit on any error

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_COMPOSE_DIR="$PROJECT_ROOT/infrastructure/docker"
ENV_FILE="$PROJECT_ROOT/infrastructure/.env"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        print_error "Neither 'docker-compose' nor 'docker compose' is available."
        print_error "Please install Docker Compose and try again."
        exit 1
    fi
    print_status "Using: $COMPOSE_CMD"
}

# Function to check environment file
check_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        print_warning ".env file not found at $ENV_FILE"
        print_status "You can copy from .env.example and customize:"
        print_status "cp $PROJECT_ROOT/infrastructure/.env.example $ENV_FILE"
        print_status "Continuing with default values..."
    else
        print_status "Using environment file: $ENV_FILE"
    fi
}

# Function to create necessary directories
create_directories() {
    local dirs=("logs" "data" "config" "init-scripts")
    
    for dir in "${dirs[@]}"; do
        local full_path="$DOCKER_COMPOSE_DIR/$dir"
        if [[ ! -d "$full_path" ]]; then
            print_status "Creating directory: $full_path"
            mkdir -p "$full_path"
        fi
    done
}

# Function to start infrastructure services
start_services() {
    print_status "Starting Community Connect infrastructure services..."
    print_status "Working directory: $DOCKER_COMPOSE_DIR"
    
    cd "$DOCKER_COMPOSE_DIR"
    
    # Pull the latest images
    print_status "Pulling latest Docker images..."
    $COMPOSE_CMD pull
    
    # Start services in detached mode
    print_status "Starting services in detached mode..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" up -d
    else
        $COMPOSE_CMD up -d
    fi
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    local services=("postgres-core" "postgres-transaction" "mongodb" "redis" "rabbitmq")
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        local ready_count=0
        
        for service in "${services[@]}"; do
            if $COMPOSE_CMD ps "$service" 2>/dev/null | grep -q "Up (healthy)"; then
                ((ready_count++))
            fi
        done
        
        if [[ $ready_count -eq ${#services[@]} ]]; then
            print_success "All services are ready!"
            break
        fi
        
        print_status "Waiting... ($attempt/$max_attempts) - $ready_count/${#services[@]} services ready"
        sleep 10
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        print_warning "Some services may still be starting. Check with: $COMPOSE_CMD ps"
    fi
}

# Function to display service status
show_status() {
    print_status "Service status:"
    cd "$DOCKER_COMPOSE_DIR"
    $COMPOSE_CMD ps
    
    echo
    print_status "Service URLs:"
    echo "  PostgreSQL Core:     localhost:5432"
    echo "  PostgreSQL Transaction: localhost:5433"
    echo "  MongoDB:             localhost:27017"
    echo "  Redis:               localhost:6379"
    echo "  RabbitMQ AMQP:       localhost:5672"
    echo "  RabbitMQ Management: http://localhost:15672"
    echo
    print_status "To view logs: $COMPOSE_CMD logs -f [service-name]"
    print_status "To stop services: ./scripts/stop-infrastructure.sh"
}

# Main execution
main() {
    echo "========================================"
    echo "Community Connect Infrastructure Startup"
    echo "========================================"
    echo
    
    print_status "Checking prerequisites..."
    check_docker
    check_docker_compose
    check_env_file
    
    print_status "Preparing environment..."
    create_directories
    
    print_status "Starting services..."
    start_services
    
    print_status "Waiting for services to be healthy..."
    wait_for_services
    
    echo
    print_success "Infrastructure startup completed!"
    echo
    
    show_status
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"