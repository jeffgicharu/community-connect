#!/bin/bash

# Community Connect Full Stack Startup Script
# This script starts both infrastructure and application services

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

# Function to setup environment files
setup_env_files() {
    local infrastructure_env="infrastructure/.env"
    local infrastructure_env_example="infrastructure/.env.example"
    local services_env="infrastructure/.env.services"
    local services_env_example="infrastructure/.env.services.example"
    
    # Setup infrastructure environment
    if [ ! -f "$infrastructure_env" ]; then
        if [ -f "$infrastructure_env_example" ]; then
            print_status "Creating $infrastructure_env from $infrastructure_env_example"
            cp "$infrastructure_env_example" "$infrastructure_env"
        else
            print_error "Infrastructure environment example file $infrastructure_env_example not found"
            exit 1
        fi
    fi
    
    # Setup services environment
    if [ ! -f "$services_env" ]; then
        if [ -f "$services_env_example" ]; then
            print_status "Creating $services_env from $services_env_example"
            cp "$services_env_example" "$services_env"
        else
            print_error "Services environment example file $services_env_example not found"
            exit 1
        fi
    fi
    
    print_success "Environment files ready"
}

# Function to build Spring Boot services
build_services() {
    print_status "Building Spring Boot services..."
    
    local services=("core-service" "transaction-service" "communication-service")
    
    for service in "${services[@]}"; do
        print_status "Building $service..."
        cd "backend/$service"
        
        if [ -f "./mvnw" ]; then
            ./mvnw clean package -DskipTests -q
            if [ $? -eq 0 ]; then
                print_success "$service built successfully"
            else
                print_error "Failed to build $service"
                cd ../..
                exit 1
            fi
        else
            print_error "Maven wrapper not found for $service"
            cd ../..
            exit 1
        fi
        
        cd ../..
    done
}

# Function to start infrastructure services
start_infrastructure() {
    print_status "Starting infrastructure services..."
    
    cd infrastructure
    
    # Start infrastructure first
    docker-compose up -d
    
    cd ..
    
    print_success "Infrastructure services started"
}

# Function to wait for infrastructure to be ready
wait_for_infrastructure() {
    print_status "Waiting for infrastructure services to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_status "Health check attempt $attempt/$max_attempts"
        
        # Check if all infrastructure services are healthy
        local healthy_count=0
        
        if docker exec community-connect-postgres-core pg_isready -U core_user > /dev/null 2>&1; then
            healthy_count=$((healthy_count + 1))
        fi
        
        if docker exec community-connect-postgres-transaction pg_isready -U transaction_user > /dev/null 2>&1; then
            healthy_count=$((healthy_count + 1))
        fi
        
        if docker exec community-connect-mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
            healthy_count=$((healthy_count + 1))
        fi
        
        if docker exec community-connect-redis redis-cli ping > /dev/null 2>&1; then
            healthy_count=$((healthy_count + 1))
        fi
        
        if docker exec community-connect-rabbitmq rabbitmq-diagnostics check_port_connectivity > /dev/null 2>&1; then
            healthy_count=$((healthy_count + 1))
        fi
        
        if [ $healthy_count -eq 5 ]; then
            print_success "All infrastructure services are ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Some infrastructure services may not be fully ready yet"
            break
        fi
        
        sleep 5
        attempt=$((attempt + 1))
    done
}

# Function to start application services
start_services() {
    print_status "Starting Community Connect application services..."
    
    cd infrastructure
    
    # Start both infrastructure and services
    docker-compose -f docker-compose.yml -f docker-compose.services.yml up -d
    
    cd ..
    
    print_success "Application services started"
}

# Function to display service status
show_service_status() {
    print_status "Checking service status..."
    echo
    
    cd infrastructure
    docker-compose -f docker-compose.yml -f docker-compose.services.yml ps
    cd ..
    
    echo
    print_status "Service URLs:"
    echo "  🌐 Core Service:        http://localhost:8081/api/v1"
    echo "  💳 Transaction Service: http://localhost:8082/api/v1"
    echo "  💬 Communication Service: http://localhost:8083/api/v1"
    echo
    echo "  📊 RabbitMQ Management: http://localhost:15672 (guest/guest)"
    echo "  🐘 PostgreSQL Core:     localhost:5432 (core_user/core_pass)"
    echo "  🐘 PostgreSQL Transaction: localhost:5433 (transaction_user/transaction_pass)"
    echo "  🍃 MongoDB:             localhost:27017 (mongo_user/mongo_pass)"
    echo "  🔴 Redis:               localhost:6379"
    echo
    echo "  📚 API Documentation:"
    echo "    - Core Service Swagger:        http://localhost:8081/api/v1/swagger-ui.html"
    echo "    - Transaction Service Swagger: http://localhost:8082/api/v1/swagger-ui.html"
    echo "    - Communication Service Swagger: http://localhost:8083/api/v1/swagger-ui.html"
}

# Function to show logs
show_logs() {
    if [ "$1" = "--logs" ] || [ "$1" = "-l" ]; then
        print_status "Showing service logs (press Ctrl+C to exit)..."
        cd infrastructure
        docker-compose -f docker-compose.yml -f docker-compose.services.yml logs -f
        cd ..
    fi
}

# Function to stop services
stop_services() {
    if [ "$1" = "--stop" ] || [ "$1" = "-s" ]; then
        print_status "Stopping Community Connect services..."
        cd infrastructure
        docker-compose -f docker-compose.yml -f docker-compose.services.yml down
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
            print_status "Cleaning up Community Connect services..."
            cd infrastructure
            docker-compose -f docker-compose.yml -f docker-compose.services.yml down -v --remove-orphans
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
        echo "Community Connect Full Stack Startup Script"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  -s, --stop     Stop all services"
        echo "  -c, --clean    Stop all services and remove data volumes"
        echo "  -l, --logs     Show service logs after starting"
        echo "  --build-only   Only build services without starting"
        echo "  --no-build     Skip building services (use existing Docker images)"
        echo
        echo "Without options, the script will:"
        echo "  1. Build all Spring Boot services"
        echo "  2. Start infrastructure services (databases, Redis, RabbitMQ)"
        echo "  3. Wait for infrastructure to be ready"
        echo "  4. Start application services"
        echo "  5. Display service status and URLs"
        echo
        echo "Services included:"
        echo "  - PostgreSQL (Core Service) on port 5432"
        echo "  - PostgreSQL (Transaction Service) on port 5433"
        echo "  - MongoDB (Communication Service) on port 27017"
        echo "  - Redis (Cache) on port 6379"
        echo "  - RabbitMQ (Message Queue) on ports 5672, 15672"
        echo "  - Core Service on port 8081"
        echo "  - Transaction Service on port 8082"
        echo "  - Communication Service on port 8083"
        echo
        exit 0
    fi
}

# Function to handle build-only option
build_only() {
    if [ "$1" = "--build-only" ]; then
        print_status "Building services only..."
        check_docker
        check_docker_compose
        build_services
        print_success "All services built successfully!"
        exit 0
    fi
}

# Function to handle no-build option
handle_no_build() {
    if [ "$1" = "--no-build" ]; then
        return 0  # Skip building
    else
        return 1  # Proceed with building
    fi
}

# Main execution
main() {
    echo "🚀 Community Connect Full Stack Setup"
    echo "======================================"
    echo
    
    # Check for help flag first
    show_help "$1"
    
    # Check for stop flag
    stop_services "$1"
    
    # Check for clean flag
    cleanup_services "$1"
    
    # Check for build-only flag
    build_only "$1"
    
    # Perform pre-flight checks
    check_docker
    check_docker_compose
    
    # Setup environment files
    setup_env_files
    
    # Build services (unless --no-build is specified)
    if ! handle_no_build "$1"; then
        build_services
    else
        print_status "Skipping service build (--no-build specified)"
    fi
    
    # Start infrastructure
    start_infrastructure
    
    # Wait for infrastructure to be ready
    wait_for_infrastructure
    
    # Start application services
    start_services
    
    # Wait a bit for services to start
    sleep 10
    
    # Show status
    show_service_status
    
    # Show logs if requested
    show_logs "$1"
    
    echo
    print_success "🎉 Community Connect full stack is ready!"
    print_status "Run '$0 --help' for more options"
    print_status "Run '$0 --stop' to stop all services"
    print_status "Run '$0 --logs' to view logs"
}

# Run main function with all arguments
main "$@"