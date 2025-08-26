#!/bin/bash

# Community Connect - Start All Services (Full Stack)
# This script builds and starts the complete application stack including infrastructure and application services

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
CYAN='\033[0;36m'
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

print_highlight() {
    echo -e "${CYAN}[HIGHLIGHT]${NC} $1"
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

# Function to build application images
build_applications() {
    print_status "Building application Docker images..."
    cd "$DOCKER_COMPOSE_DIR"
    
    # Build with parallel processing and no cache for fresh builds
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" build --parallel --pull
    else
        $COMPOSE_CMD build --parallel --pull
    fi
}

# Function to start all services
start_all_services() {
    print_status "Starting Community Connect full stack..."
    print_status "Working directory: $DOCKER_COMPOSE_DIR"
    
    cd "$DOCKER_COMPOSE_DIR"
    
    # Pull infrastructure images first
    print_status "Pulling infrastructure images..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" pull postgres-core postgres-transaction mongodb redis rabbitmq nginx
    else
        $COMPOSE_CMD pull postgres-core postgres-transaction mongodb redis rabbitmq nginx
    fi
    
    # Start infrastructure services first
    print_status "Starting infrastructure services..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" up -d postgres-core postgres-transaction mongodb redis rabbitmq
    else
        $COMPOSE_CMD up -d postgres-core postgres-transaction mongodb redis rabbitmq
    fi
    
    # Wait for infrastructure to be healthy
    print_status "Waiting for infrastructure services to be healthy..."
    wait_for_infrastructure
    
    # Start application services
    print_status "Starting application services..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" up -d core-service transaction-service communication-service
    else
        $COMPOSE_CMD up -d core-service transaction-service communication-service
    fi
    
    # Wait for backend services to be healthy
    print_status "Waiting for backend services to be healthy..."
    wait_for_backends
    
    # Start frontend and nginx
    print_status "Starting frontend and API gateway..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" up -d frontend nginx
    else
        $COMPOSE_CMD up -d frontend nginx
    fi
}

# Function to wait for infrastructure services to be ready
wait_for_infrastructure() {
    local services=("postgres-core" "postgres-transaction" "mongodb" "redis" "rabbitmq")
    local max_attempts=60
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        local ready_count=0
        
        for service in "${services[@]}"; do
            if $COMPOSE_CMD ps "$service" 2>/dev/null | grep -q "Up (healthy)"; then
                ((ready_count++))
            fi
        done
        
        if [[ $ready_count -eq ${#services[@]} ]]; then
            print_success "All infrastructure services are ready!"
            break
        fi
        
        print_status "Waiting for infrastructure... ($attempt/$max_attempts) - $ready_count/${#services[@]} services ready"
        sleep 10
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        print_error "Infrastructure services failed to start within expected time!"
        print_status "Current status:"
        $COMPOSE_CMD ps
        exit 1
    fi
}

# Function to wait for backend services to be ready
wait_for_backends() {
    local services=("core-service" "transaction-service" "communication-service")
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
            print_success "All backend services are ready!"
            break
        fi
        
        print_status "Waiting for backends... ($attempt/$max_attempts) - $ready_count/${#services[@]} services ready"
        sleep 10
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        print_warning "Some backend services may still be starting. Check logs with: $COMPOSE_CMD logs -f"
    fi
}

# Function to display service status and URLs
show_status() {
    print_status "Service status:"
    cd "$DOCKER_COMPOSE_DIR"
    $COMPOSE_CMD ps
    
    echo
    print_highlight "🌍 Community Connect is now running!"
    echo
    print_status "Application URLs:"
    echo "  🏠 Frontend:             http://localhost"
    echo "  🔧 API Gateway:          http://localhost/api"
    echo
    print_status "Service APIs (via Gateway):"
    echo "  👤 Core Service:         http://localhost/api/core"
    echo "  💳 Transaction Service:  http://localhost/api/transaction"
    echo "  💬 Communication:        http://localhost/api/communication"
    echo "  🔗 GraphQL:             http://localhost/api/graphql"
    echo "  🌐 WebSocket:            ws://localhost/ws"
    echo
    print_status "Direct Service Access:"
    echo "  👤 Core Service:         http://localhost:8081"
    echo "  💳 Transaction Service:  http://localhost:8082"
    echo "  💬 Communication:        http://localhost:8083"
    echo "  🖥️  Frontend:            http://localhost:3000"
    echo
    print_status "Infrastructure Services:"
    echo "  🐘 PostgreSQL Core:     localhost:5432"
    echo "  🐘 PostgreSQL Transaction: localhost:5433"
    echo "  🍃 MongoDB:             localhost:27017"
    echo "  🔴 Redis:               localhost:6379"
    echo "  🐰 RabbitMQ AMQP:       localhost:5672"
    echo "  🐰 RabbitMQ Management: http://localhost:15672"
    echo
    print_status "Useful commands:"
    echo "  📋 View logs: $COMPOSE_CMD logs -f [service-name]"
    echo "  🛑 Stop all:  ./scripts/stop-all.sh"
    echo "  🔄 Restart:   $COMPOSE_CMD restart [service-name]"
    echo "  📊 Status:    $COMPOSE_CMD ps"
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --no-build      Skip building application images"
    echo "  --rebuild       Force rebuild of all images (no cache)"
    echo "  -h, --help      Show this help message"
    echo
    echo "This script starts the complete Community Connect stack:"
    echo "  1. Infrastructure services (databases, cache, message queue)"
    echo "  2. Backend services (core, transaction, communication)"
    echo "  3. Frontend application"
    echo "  4. API Gateway (Nginx)"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-build)
                SKIP_BUILD=true
                shift
                ;;
            --rebuild)
                FORCE_REBUILD=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    echo "=================================================="
    echo "Community Connect - Full Stack Startup"
    echo "=================================================="
    echo
    
    print_status "Checking prerequisites..."
    check_docker
    check_docker_compose
    check_env_file
    
    print_status "Preparing environment..."
    create_directories
    
    if [[ "$SKIP_BUILD" != "true" ]]; then
        if [[ "$FORCE_REBUILD" == "true" ]]; then
            print_status "Force rebuilding application images..."
            cd "$DOCKER_COMPOSE_DIR"
            if [[ -f "$ENV_FILE" ]]; then
                $COMPOSE_CMD --env-file="$ENV_FILE" build --parallel --no-cache --pull
            else
                $COMPOSE_CMD build --parallel --no-cache --pull
            fi
        else
            build_applications
        fi
    else
        print_status "Skipping build phase..."
    fi
    
    start_all_services
    
    # Wait a moment for all services to fully settle
    print_status "Allowing services to fully initialize..."
    sleep 15
    
    echo
    print_success "Full stack startup completed!"
    echo
    
    show_status
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Initialize variables
SKIP_BUILD=false
FORCE_REBUILD=false

# Parse arguments and run main function
parse_args "$@"
main