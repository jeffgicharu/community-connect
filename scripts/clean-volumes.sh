#!/bin/bash

# Community Connect - Clean Docker Volumes
# This script removes all Docker volumes used by the infrastructure services
# WARNING: This will permanently delete all data!

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

print_danger() {
    echo -e "${RED}[DANGER]${NC} $1"
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
        exit 1
    fi
    print_status "Using: $COMPOSE_CMD"
}

# Function to list volumes
list_volumes() {
    print_status "Current Community Connect volumes:"
    echo
    
    local volumes
    volumes=$(docker volume ls --filter name=community-connect --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" 2>/dev/null || true)
    
    if [[ -z "$volumes" ]] || [[ "$volumes" == "NAME	DRIVER	SCOPE" ]]; then
        print_status "No Community Connect volumes found."
        return 1
    else
        echo "$volumes"
        echo
        
        # Show volume sizes if possible
        print_status "Volume usage information:"
        docker volume ls --filter name=community-connect --format "{{.Name}}" | while read -r volume; do
            local size
            size=$(docker system df -v 2>/dev/null | grep "$volume" | awk '{print $3}' || echo "Unknown")
            echo "  $volume: $size"
        done
        echo
        return 0
    fi
}

# Function to stop running services
stop_services_if_running() {
    cd "$DOCKER_COMPOSE_DIR"
    
    local running_services
    running_services=$($COMPOSE_CMD ps -q 2>/dev/null || true)
    
    if [[ -n "$running_services" ]]; then
        print_warning "Services are currently running. Stopping them first..."
        
        if [[ -f "$ENV_FILE" ]]; then
            $COMPOSE_CMD --env-file="$ENV_FILE" down
        else
            $COMPOSE_CMD down
        fi
        
        print_success "Services stopped."
        echo
    fi
}

# Function to show confirmation prompt
confirm_deletion() {
    echo
    print_danger "⚠️  WARNING: This action will permanently delete ALL data!"
    print_danger "   This includes:"
    print_danger "   - All database data (PostgreSQL databases)"
    print_danger "   - All cached data (Redis cache)"
    print_danger "   - All message queues (RabbitMQ queues and exchanges)"
    print_danger "   - All MongoDB collections and documents"
    echo
    print_highlight "   This action cannot be undone!"
    echo
    
    # Different confirmation levels based on force flag
    if [[ "$FORCE_CLEAN" != "true" ]]; then
        # Interactive confirmation
        read -p "Are you absolutely sure you want to continue? (yes/no): " -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_status "Operation cancelled by user."
            exit 0
        fi
        
        # Second confirmation
        read -p "Type 'DELETE' to confirm permanent data deletion: " -r
        echo
        
        if [[ $REPLY != "DELETE" ]]; then
            print_status "Operation cancelled. Exact text 'DELETE' not entered."
            exit 0
        fi
    else
        print_warning "Force mode enabled - skipping confirmation prompts."
    fi
}

# Function to clean volumes
clean_volumes() {
    print_status "Cleaning Community Connect Docker volumes..."
    
    cd "$DOCKER_COMPOSE_DIR"
    
    # Method 1: Use docker-compose down with volumes flag
    print_status "Removing volumes using docker-compose..."
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD --env-file="$ENV_FILE" down -v
    else
        $COMPOSE_CMD down -v
    fi
    
    # Method 2: Remove any remaining volumes by name pattern
    print_status "Removing any remaining Community Connect volumes..."
    local remaining_volumes
    remaining_volumes=$(docker volume ls --filter name=community-connect -q 2>/dev/null || true)
    
    if [[ -n "$remaining_volumes" ]]; then
        echo "$remaining_volumes" | while read -r volume; do
            if [[ -n "$volume" ]]; then
                print_status "Removing volume: $volume"
                docker volume rm "$volume" 2>/dev/null || print_warning "Could not remove volume: $volume"
            fi
        done
    fi
    
    # Method 3: Clean up any orphaned volumes (optional)
    if [[ "$CLEAN_ORPHANED" == "true" ]]; then
        print_status "Cleaning up orphaned volumes..."
        docker volume prune -f
    fi
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    local remaining_volumes
    remaining_volumes=$(docker volume ls --filter name=community-connect -q 2>/dev/null || true)
    
    if [[ -z "$remaining_volumes" ]]; then
        print_success "All Community Connect volumes have been successfully removed."
    else
        print_warning "Some volumes may still exist:"
        docker volume ls --filter name=community-connect
        echo
        print_status "You may need to manually remove them with:"
        print_status "docker volume rm <volume-name>"
    fi
    
    echo
    print_status "Next steps:"
    print_status "  - To start fresh: ./scripts/start-infrastructure.sh"
    print_status "  - All services will recreate their data from scratch"
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -f, --force            Skip confirmation prompts (dangerous!)"
    echo "  -o, --clean-orphaned   Also clean orphaned Docker volumes"
    echo "  -l, --list-only        List volumes without deleting"
    echo "  -h, --help             Show this help message"
    echo
    echo "Examples:"
    echo "  $0                     # Interactive cleanup with confirmations"
    echo "  $0 --list-only         # Just list current volumes"
    echo "  $0 --force             # Skip all confirmations (use with caution!)"
    echo "  $0 --clean-orphaned    # Also clean other orphaned volumes"
    echo
    echo "WARNING: This script permanently deletes all infrastructure data!"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                FORCE_CLEAN=true
                shift
                ;;
            -o|--clean-orphaned)
                CLEAN_ORPHANED=true
                shift
                ;;
            -l|--list-only)
                LIST_ONLY=true
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
    echo "Community Connect Volume Cleanup"
    echo "========================================"
    echo
    
    print_status "Checking prerequisites..."
    check_docker
    check_docker_compose
    
    # List volumes
    if ! list_volumes; then
        print_success "No volumes to clean. Exiting."
        exit 0
    fi
    
    # If list-only mode, exit here
    if [[ "$LIST_ONLY" == "true" ]]; then
        print_status "List-only mode. No volumes were deleted."
        exit 0
    fi
    
    # Confirm deletion
    confirm_deletion
    
    # Stop running services
    stop_services_if_running
    
    # Clean volumes
    clean_volumes
    
    # Verify cleanup
    verify_cleanup
    
    echo
    print_success "Volume cleanup completed!"
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Initialize variables
FORCE_CLEAN=false
CLEAN_ORPHANED=false
LIST_ONLY=false

# Parse arguments and run main function
parse_args "$@"
main