#!/bin/bash

# Community Connect - Stop Development Environment
# This script stops all development services including dev tools

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
MAGENTA='\033[0;35m'
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

print_dev() {
    echo -e "${MAGENTA}[DEV]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Cannot stop services."
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
        exit 1
    fi
    print_status "Using: $COMPOSE_CMD"
}

# Function to stop development services
stop_dev_services() {
    print_dev "Stopping Community Connect development environment..."
    cd "$DOCKER_COMPOSE_DIR"
    
    local compose_files="-f docker-compose.yml -f docker-compose.dev.yml"
    
    # Check if any services are running
    if ! $COMPOSE_CMD $compose_files ps -q 2>/dev/null | grep -q .; then
        print_warning "No development services appear to be running."
        return 0
    fi
    
    # Stop development tools first
    print_dev "Stopping development tools..."
    local dev_tools=("mailhog" "redis-commander" "mongo-express" "adminer")
    
    for tool in "${dev_tools[@]}"; do
        if $COMPOSE_CMD $compose_files ps -q "$tool" 2>/dev/null | grep -q .; then
            print_dev "Stopping $tool..."
            if [[ -f "$ENV_FILE" ]]; then
                $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" stop "$tool"
            else
                $COMPOSE_CMD $compose_files stop "$tool"
            fi
        fi
    done
    
    # Stop application services
    print_dev "Stopping application services..."
    local app_services=("nginx" "frontend" "core-service" "transaction-service" "communication-service")
    
    for service in "${app_services[@]}"; do
        if $COMPOSE_CMD $compose_files ps -q "$service" 2>/dev/null | grep -q .; then
            print_dev "Stopping $service..."
            if [[ -f "$ENV_FILE" ]]; then
                $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" stop "$service"
            else
                $COMPOSE_CMD $compose_files stop "$service"
            fi
        fi
    done
    
    # Wait for graceful shutdown
    print_dev "Allowing graceful shutdown..."
    sleep 5
    
    # Stop infrastructure services
    print_dev "Stopping infrastructure services..."
    local infra_services=("rabbitmq" "redis" "mongodb" "postgres-transaction" "postgres-core")
    
    for service in "${infra_services[@]}"; do
        if $COMPOSE_CMD $compose_files ps -q "$service" 2>/dev/null | grep -q .; then
            print_dev "Stopping $service..."
            if [[ -f "$ENV_FILE" ]]; then
                $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" stop "$service"
            else
                $COMPOSE_CMD $compose_files stop "$service"
            fi
        fi
    done
    
    # Remove containers but keep volumes
    print_dev "Removing containers (keeping development volumes)..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" rm -f
    else
        $COMPOSE_CMD $compose_files rm -f
    fi
}

# Function to force stop development environment
force_stop_dev() {
    print_warning "Performing forced stop of development environment..."
    cd "$DOCKER_COMPOSE_DIR"
    
    local compose_files="-f docker-compose.yml -f docker-compose.dev.yml"
    
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" down --timeout 10
    else
        $COMPOSE_CMD $compose_files down --timeout 10
    fi
    
    print_success "Forced stop completed."
}

# Function to show status
show_dev_status() {
    cd "$DOCKER_COMPOSE_DIR"
    
    local compose_files="-f docker-compose.yml -f docker-compose.dev.yml"
    local running_containers
    running_containers=$($COMPOSE_CMD $compose_files ps -q 2>/dev/null || true)
    
    if [[ -z "$running_containers" ]]; then
        print_success "All development services have been stopped."
    else
        print_warning "Some development containers may still be running:"
        $COMPOSE_CMD $compose_files ps
    fi
    
    echo
    print_dev "Development data has been preserved:"
    echo "  🗄️  Development databases"
    echo "  📦 Maven cache"
    echo "  🔧 Node modules cache"
    echo
    print_status "To restart development environment:"
    print_status "  ./scripts/start-dev.sh"
    echo
    print_status "To clean development data:"
    print_status "  ./scripts/clean-volumes.sh"
}

# Function to clean up development artifacts
cleanup_dev_artifacts() {
    print_dev "Cleaning up development artifacts..."
    
    # Remove any dangling images from development builds
    local dangling_images
    dangling_images=$(docker images -f "dangling=true" -q 2>/dev/null || true)
    
    if [[ -n "$dangling_images" ]]; then
        print_dev "Removing dangling images..."
        echo "$dangling_images" | xargs -r docker rmi
    fi
    
    # Remove development build cache
    if [[ "$CLEAN_CACHE" == "true" ]]; then
        print_dev "Removing build cache..."
        docker builder prune -f || true
    fi
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -f, --force         Force stop development environment"
    echo "  -c, --clean-cache   Also clean Docker build cache"
    echo "  -h, --help          Show this help message"
    echo
    echo "This script stops the development environment:"
    echo "  • Development tools (Adminer, Mongo Express, etc.)"
    echo "  • Application services with hot reload"
    echo "  • Infrastructure services with development settings"
    echo "  • Preserves development data volumes"
    echo
    echo "Examples:"
    echo "  $0                    # Graceful stop"
    echo "  $0 --force            # Force stop all services"
    echo "  $0 --clean-cache      # Stop and clean build cache"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE_STOP=true
                shift
                ;;
            -c|--clean-cache)
                CLEAN_CACHE=true
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
    echo "=============================================="
    echo "Community Connect - Development Shutdown"
    echo "=============================================="
    echo
    
    print_dev "Shutting down development environment..."
    check_docker
    check_docker_compose
    
    if [[ "$FORCE_STOP" == "true" ]]; then
        force_stop_dev
    else
        stop_dev_services
    fi
    
    cleanup_dev_artifacts
    
    echo
    show_dev_status
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Initialize variables
FORCE_STOP=false
CLEAN_CACHE=false

# Parse arguments and run main function
parse_args "$@"
main