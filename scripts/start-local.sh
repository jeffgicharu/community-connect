#!/bin/bash

# Community Connect Local Development Startup Script
# This script sets up and starts all required infrastructure services for local development

set -e  # Exit on any error

# Colors for output
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
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to setup environment file
setup_env_file() {
    local env_file="infrastructure/.env"
    local env_example="infrastructure/.env.example"
    
    if [ ! -f "$env_file" ]; then
        if [ -f "$env_example" ]; then
            print_status "Creating $env_file from $env_example"
            cp "$env_example" "$env_file"
            print_success "Environment file created successfully"
            print_warning "Please review $env_file and update values as needed"
        else
            print_error "Environment example file $env_example not found"
            exit 1
        fi
    else
        print_status "Environment file $env_file already exists"
    fi
}

# Function to start infrastructure services
start_services() {
    print_status "Starting Community Connect infrastructure services..."
    
    # Change to infrastructure directory
    cd infrastructure
    
    # Pull latest images
    print_status "Pulling latest Docker images..."
    docker-compose pull
    
    # Start services in detached mode
    print_status "Starting services..."
    docker-compose up -d
    
    # Return to original directory
    cd ..
    
    print_success "All services started successfully!"
}

# Function to wait for services to be healthy
wait_for_services() {
    print_status "Waiting for services to become healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_status "Health check attempt $attempt/$max_attempts"
        
        # Check PostgreSQL Core
        if docker exec community-connect-postgres-core pg_isready -U core_user > /dev/null 2>&1; then
            print_success "PostgreSQL Core is ready"
        else
            print_warning "PostgreSQL Core is not ready yet"
        fi
        
        # Check PostgreSQL Transaction
        if docker exec community-connect-postgres-transaction pg_isready -U transaction_user > /dev/null 2>&1; then
            print_success "PostgreSQL Transaction is ready"
        else
            print_warning "PostgreSQL Transaction is not ready yet"
        fi
        
        # Check MongoDB
        if docker exec community-connect-mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
            print_success "MongoDB is ready"
        else
            print_warning "MongoDB is not ready yet"
        fi
        
        # Check Redis
        if docker exec community-connect-redis redis-cli ping > /dev/null 2>&1; then
            print_success "Redis is ready"
        else
            print_warning "Redis is not ready yet"
        fi
        
        # Check RabbitMQ
        if docker exec community-connect-rabbitmq rabbitmq-diagnostics check_port_connectivity > /dev/null 2>&1; then
            print_success "RabbitMQ is ready"
            break
        else
            print_warning "RabbitMQ is not ready yet"
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Some services may not be fully ready yet. Check service status manually."
            break
        fi
        
        sleep 5
        attempt=$((attempt + 1))
    done
}

# Function to display service status
show_service_status() {
    print_status "Checking service status..."
    echo
    
    cd infrastructure
    docker-compose ps
    cd ..
    
    echo
    print_status "Service URLs:"
    echo "  📊 RabbitMQ Management: http://localhost:15672 (guest/guest)"
    echo "  🐘 PostgreSQL Core:     localhost:5432 (core_user/core_pass)"
    echo "  🐘 PostgreSQL Transaction: localhost:5433 (transaction_user/transaction_pass)"
    echo "  🍃 MongoDB:             localhost:27017 (mongo_user/mongo_pass)"
    echo "  🔴 Redis:               localhost:6379"
    echo
    print_status "To connect to databases, use the credentials from infrastructure/.env"
}

# Function to show logs
show_logs() {
    if [ "$1" = "--logs" ] || [ "$1" = "-l" ]; then
        print_status "Showing service logs (press Ctrl+C to exit)..."
        cd infrastructure
        docker-compose logs -f
        cd ..
    fi
}

# Function to stop services
stop_services() {
    if [ "$1" = "--stop" ] || [ "$1" = "-s" ]; then
        print_status "Stopping Community Connect infrastructure services..."
        cd infrastructure
        docker-compose down
        cd ..
        print_success "All services stopped"
        exit 0
    fi
}

# Function to clean up (stop and remove volumes)
cleanup_services() {
    if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
        print_warning "This will stop all services and remove all data volumes!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Cleaning up Community Connect infrastructure..."
            cd infrastructure
            docker-compose down -v --remove-orphans
            docker volume prune -f
            cd ..
            print_success "Cleanup completed"
        else
            print_status "Cleanup cancelled"
        fi
        exit 0
    fi
}

# Function to show help
show_help() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Community Connect Local Development Startup Script"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  -s, --stop     Stop all services"
        echo "  -c, --clean    Stop all services and remove data volumes"
        echo "  -l, --logs     Show service logs after starting"
        echo
        echo "Without options, the script will start all infrastructure services."
        echo
        echo "Services started:"
        echo "  - PostgreSQL (Core Service) on port 5432"
        echo "  - PostgreSQL (Transaction Service) on port 5433"
        echo "  - MongoDB (Communication Service) on port 27017"
        echo "  - Redis (Cache) on port 6379"
        echo "  - RabbitMQ (Message Queue) on ports 5672, 15672"
        echo
        exit 0
    fi
}

# Main execution
main() {
    echo "🚀 Community Connect Local Development Setup"
    echo "============================================="
    echo
    
    # Check for help flag first
    show_help "$1"
    
    # Check for stop flag
    stop_services "$1"
    
    # Check for clean flag
    cleanup_services "$1"
    
    # Perform pre-flight checks
    check_docker
    check_docker_compose
    
    # Setup environment
    setup_env_file
    
    # Start services
    start_services
    
    # Wait for services to be ready
    wait_for_services
    
    # Show status
    show_service_status
    
    # Show logs if requested
    show_logs "$1"
    
    echo
    print_success "🎉 Community Connect infrastructure is ready for development!"
    print_status "Run '$0 --help' for more options"
}

# Run main function with all arguments
main "$@"