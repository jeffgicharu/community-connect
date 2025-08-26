#!/bin/bash

# Community Connect - Stop All Services (Full Stack)
# This script stops all application and infrastructure services

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

# Function to stop services gracefully
stop_all_services() {
    print_status "Stopping Community Connect full stack..."
    cd "$DOCKER_COMPOSE_DIR"
    
    # Check if any services are running
    if ! $COMPOSE_CMD ps -q 2>/dev/null | grep -q .; then
        print_warning "No services appear to be running."
        return 0
    fi
    
    # Stop application services first (graceful shutdown)
    print_status "Stopping application services..."
    local app_services=("nginx" "frontend" "core-service" "transaction-service" "communication-service")
    
    for service in "${app_services[@]}"; do
        if $COMPOSE_CMD ps -q "$service" 2>/dev/null | grep -q .; then
            print_status "Stopping $service..."
            if [[ -f "$ENV_FILE" ]]; then
                $COMPOSE_CMD --env-file="$ENV_FILE" stop "$service"
            else
                $COMPOSE_CMD stop "$service"
            fi
        fi
    done
    
    # Wait a moment for graceful shutdown
    print_status "Allowing graceful shutdown..."
    sleep 5
    
    # Stop infrastructure services
    print_status "Stopping infrastructure services..."
    local infra_services=("rabbitmq" "redis" "mongodb" "postgres-transaction" "postgres-core")
    
    for service in "${infra_services[@]}"; do
        if $COMPOSE_CMD ps -q "$service" 2>/dev/null | grep -q .; then
            print_status "Stopping $service..."
            if [[ -f "$ENV_FILE" ]]; then
                $COMPOSE_CMD --env-file="$ENV_FILE" stop "$service"
            else
                $COMPOSE_CMD stop "$service"
            fi
        fi
    done
    
    # Remove containers but keep volumes and networks
    print_status "Removing containers (keeping volumes and networks)..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" rm -f
    else
        $COMPOSE_CMD rm -f
    fi
}

# Function to force stop all services
force_stop_all() {
    print_warning "Performing forced stop of all services..."
    cd "$DOCKER_COMPOSE_DIR"
    
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" down --timeout 10
    else
        $COMPOSE_CMD down --timeout 10
    fi
    
    print_success "Forced stop completed."
}

# Function to show current status
show_status() {
    cd "$DOCKER_COMPOSE_DIR"
    
    # Check if any containers are still running
    local running_containers
    running_containers=$($COMPOSE_CMD ps -q 2>/dev/null || true)
    
    if [[ -z "$running_containers" ]]; then
        print_success "All Community Connect services have been stopped."
    else
        print_warning "Some containers may still be running:"
        $COMPOSE_CMD ps
    fi
    
    echo
    print_status "Data volumes have been preserved."
    print_status "Network configuration has been preserved."
    echo
    print_status "To restart services:"
    print_status "  • Full stack: ./scripts/start-all.sh"
    print_status "  • Development: ./scripts/start-dev.sh"
    print_status "  • Infrastructure only: ./scripts/start-infrastructure.sh"
    echo
    print_status "To clean up completely:"
    print_status "  • Remove volumes: ./scripts/clean-volumes.sh"
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -f, --force     Force stop services (equivalent to 'docker-compose down')"
    echo "  -h, --help      Show this help message"
    echo
    echo "This script stops all Community Connect services:"
    echo "  1. Application services (nginx, frontend, backends)"
    echo "  2. Infrastructure services (databases, cache, message queue)"
    echo "  3. Removes containers but preserves volumes and networks"
    echo
    echo "Examples:"
    echo "  $0              # Graceful stop (recommended)"
    echo "  $0 --force      # Force stop all services"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE_STOP=true
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
    echo "========================================"
    echo "Community Connect - Full Stack Shutdown"
    echo "========================================"
    echo
    
    print_status "Checking prerequisites..."
    check_docker
    check_docker_compose
    
    if [[ "$FORCE_STOP" == "true" ]]; then
        force_stop_all
    else
        stop_all_services
    fi
    
    echo
    show_status
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Initialize variables
FORCE_STOP=false

# Parse arguments and run main function
parse_args "$@"
main