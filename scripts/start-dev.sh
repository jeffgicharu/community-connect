#!/bin/bash

# Community Connect - Start Development Environment
# This script starts the development stack with hot reload and development tools

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

print_highlight() {
    echo -e "${CYAN}[HIGHLIGHT]${NC} $1"
}

print_dev() {
    echo -e "${MAGENTA}[DEV]${NC} $1"
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

# Function to check environment file
check_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        print_warning ".env file not found at $ENV_FILE"
        print_status "Creating basic .env file for development..."
        create_dev_env_file
    else
        print_status "Using environment file: $ENV_FILE"
    fi
}

# Function to create a basic development .env file
create_dev_env_file() {
    cat > "$ENV_FILE" << 'EOF'
# Community Connect Development Environment Variables
# Generated automatically for development

# Infrastructure Ports (offset to avoid conflicts)
POSTGRES_CORE_PORT=5434
POSTGRES_TRANSACTION_PORT=5435
MONGODB_PORT=27018
REDIS_PORT=6380
RABBITMQ_AMQP_PORT=5673
RABBITMQ_MANAGEMENT_PORT=15673

# Service Ports
CORE_SERVICE_PORT=8081
TRANSACTION_SERVICE_PORT=8082
COMMUNICATION_SERVICE_PORT=8083
FRONTEND_PORT=3001
NGINX_HTTP_PORT=8080
NGINX_HTTPS_PORT=8443

# Database Credentials (Development)
POSTGRES_CORE_USER=dev_user
POSTGRES_CORE_PASSWORD=dev_password
POSTGRES_TRANSACTION_USER=dev_user
POSTGRES_TRANSACTION_PASSWORD=dev_password
MONGODB_ROOT_USER=admin
MONGODB_ROOT_PASSWORD=admin123
REDIS_PASSWORD=dev_redis_password

# RabbitMQ (Development)
RABBITMQ_USER=dev_admin
RABBITMQ_PASSWORD=dev_password

# JWT Configuration
JWT_SECRET=dev-jwt-secret-key-not-for-production

# Development Tools Ports
ADMINER_PORT=8081
MONGO_EXPRESS_PORT=8082
REDIS_COMMANDER_PORT=8083
MAILHOG_SMTP_PORT=1025
MAILHOG_WEB_PORT=8025
EOF
    print_success "Created development .env file at $ENV_FILE"
}

# Function to create directories
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

# Function to start development services
start_dev_services() {
    print_dev "Starting Community Connect development environment..."
    cd "$DOCKER_COMPOSE_DIR"
    
    # Use both docker-compose files
    local compose_files="-f docker-compose.yml -f docker-compose.dev.yml"
    
    if [[ -f "$ENV_FILE" ]]; then
        $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" pull
        $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" up -d
    else
        $COMPOSE_CMD $compose_files pull
        $COMPOSE_CMD $compose_files up -d
    fi
}

# Function to wait for services
wait_for_dev_services() {
    print_dev "Waiting for development services to be ready..."
    
    local infrastructure_services=("postgres-core" "postgres-transaction" "mongodb" "redis" "rabbitmq")
    local app_services=("core-service" "transaction-service" "communication-service" "frontend")
    local dev_tools=("adminer" "mongo-express" "redis-commander" "mailhog")
    
    # Wait for infrastructure first
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        local ready_count=0
        
        for service in "${infrastructure_services[@]}"; do
            if $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml ps "$service" 2>/dev/null | grep -q "Up"; then
                ((ready_count++))
            fi
        done
        
        if [[ $ready_count -eq ${#infrastructure_services[@]} ]]; then
            print_success "Infrastructure services are ready!"
            break
        fi
        
        print_dev "Infrastructure starting... ($attempt/$max_attempts) - $ready_count/${#infrastructure_services[@]} ready"
        sleep 5
        ((attempt++))
    done
    
    # Give a bit more time for app services to start
    print_dev "Allowing application services to start..."
    sleep 30
}

# Function to show development status
show_dev_status() {
    print_dev "Development environment status:"
    cd "$DOCKER_COMPOSE_DIR"
    $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml ps
    
    echo
    print_highlight "🚀 Community Connect Development Environment"
    echo
    print_dev "Frontend & API:"
    echo "  🏠 Frontend (Hot Reload):   http://localhost:3001"
    echo "  🌐 API Gateway:            http://localhost:8080"
    echo
    print_dev "Backend Services (Direct Access):"
    echo "  👤 Core Service:           http://localhost:8081"
    echo "  💳 Transaction Service:    http://localhost:8082"
    echo "  💬 Communication Service:  http://localhost:8083"
    echo
    print_dev "Development Databases:"
    echo "  🐘 PostgreSQL Core:       localhost:5434"
    echo "  🐘 PostgreSQL Transaction: localhost:5435"
    echo "  🍃 MongoDB:               localhost:27018"
    echo "  🔴 Redis:                 localhost:6380"
    echo "  🐰 RabbitMQ Management:   http://localhost:15673"
    echo
    print_dev "Development Tools:"
    echo "  🗄️  Database Admin (Adminer): http://localhost:8081"
    echo "  🍃 MongoDB Admin:            http://localhost:8082"
    echo "  🔴 Redis Commander:          http://localhost:8083"
    echo "  📧 MailHog (Email Testing):  http://localhost:8025"
    echo
    print_dev "Debug Ports (for IDE):"
    echo "  🔧 Core Service Debug:     localhost:5005"
    echo "  🔧 Transaction Debug:      localhost:5006"
    echo "  🔧 Communication Debug:    localhost:5007"
    echo
    print_status "Development commands:"
    echo "  📋 View logs:     $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml logs -f [service]"
    echo "  🔄 Restart:       $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml restart [service]"
    echo "  🛑 Stop:          ./scripts/stop-dev.sh"
    echo "  🧹 Clean:         ./scripts/clean-volumes.sh"
    echo
    print_dev "Hot reload is enabled for:"
    echo "  ⚡ Frontend: Save files in frontend/ directory"
    echo "  ⚡ Backend: Spring Boot DevTools enabled"
}

# Function to show useful development tips
show_dev_tips() {
    echo
    print_highlight "💡 Development Tips:"
    echo
    echo "1. 🔥 Hot Reload:"
    echo "   - Frontend changes auto-refresh in browser"
    echo "   - Backend changes trigger Spring Boot restart"
    echo
    echo "2. 🐛 Debugging:"
    echo "   - Attach debugger to ports 5005-5007"
    echo "   - Use 'docker logs' for container logs"
    echo
    echo "3. 📧 Email Testing:"
    echo "   - All emails are caught by MailHog"
    echo "   - View at http://localhost:8025"
    echo
    echo "4. 🗄️ Database Access:"
    echo "   - Use Adminer for SQL databases"
    echo "   - Use Mongo Express for MongoDB"
    echo
    echo "5. 📊 Monitoring:"
    echo "   - RabbitMQ Management UI available"
    echo "   - Redis Commander for cache inspection"
    echo
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --no-build      Skip building images"
    echo "  --rebuild       Force rebuild all images"
    echo "  --logs          Show logs after startup"
    echo "  --tips          Show development tips"
    echo "  -h, --help      Show this help message"
    echo
    echo "This script starts the development environment with:"
    echo "  • Hot reload for frontend and backend"
    echo "  • Development databases with sample data"
    echo "  • Development tools (Adminer, Mongo Express, etc.)"
    echo "  • Debug ports exposed for IDE integration"
    echo "  • Email testing with MailHog"
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
            --logs)
                SHOW_LOGS=true
                shift
                ;;
            --tips)
                SHOW_TIPS=true
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

# Function to build development images
build_dev_images() {
    print_dev "Building development images..."
    cd "$DOCKER_COMPOSE_DIR"
    
    local compose_files="-f docker-compose.yml -f docker-compose.dev.yml"
    
    if [[ "$FORCE_REBUILD" == "true" ]]; then
        if [[ -f "$ENV_FILE" ]]; then
            $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" build --no-cache --pull
        else
            $COMPOSE_CMD $compose_files build --no-cache --pull
        fi
    else
        if [[ -f "$ENV_FILE" ]]; then
            $COMPOSE_CMD $compose_files --env-file="$ENV_FILE" build
        else
            $COMPOSE_CMD $compose_files build
        fi
    fi
}

# Main execution
main() {
    echo "=================================================="
    echo "Community Connect - Development Environment"
    echo "=================================================="
    echo
    
    print_dev "Setting up development environment..."
    check_docker
    check_docker_compose
    check_env_file
    create_directories
    
    if [[ "$SKIP_BUILD" != "true" ]]; then
        build_dev_images
    fi
    
    start_dev_services
    wait_for_dev_services
    
    echo
    print_success "Development environment is ready!"
    echo
    
    show_dev_status
    
    if [[ "$SHOW_TIPS" == "true" ]]; then
        show_dev_tips
    fi
    
    if [[ "$SHOW_LOGS" == "true" ]]; then
        echo
        print_dev "Showing logs (Ctrl+C to exit):"
        $COMPOSE_CMD -f docker-compose.yml -f docker-compose.dev.yml logs -f
    fi
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Initialize variables
SKIP_BUILD=false
FORCE_REBUILD=false
SHOW_LOGS=false
SHOW_TIPS=false

# Parse arguments and run main function
parse_args "$@"
main