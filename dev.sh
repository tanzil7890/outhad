#!/bin/bash

# Outhad Development Environment Manager
set -e

COMPOSE_FILE="docker-compose.yml"
PROJECT_NAME="outhad"

help() {
    echo "Outhad Development Environment Manager"
    echo ""
    echo "Usage: ./dev.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start the development environment (hot-reload enabled)"
    echo "  stop      Stop all services"
    echo "  restart   Restart the development environment"
    echo "  logs      Show logs from all services"
    echo "  logs-api  Show logs from the API server only"
    echo "  shell     Open a shell in the API container"
    echo "  console   Open Rails console"
    echo "  test      Run the test suite"
    echo "  build     Rebuild containers (use when Gemfile changes)"
    echo "  clean     Remove containers and volumes (fresh start)"
    echo "  status    Show running services"
    echo ""
    echo "Examples:"
    echo "  ./dev.sh start    # Start development environment"
    echo "  ./dev.sh logs-api # Show API server logs"
    echo "  ./dev.sh console  # Open Rails console"
}

start() {
    echo "🚀 Starting Outhad development environment..."
    echo "📁 Source code will be hot-reloaded from ./server"
    echo ""
    
    docker-compose -p $PROJECT_NAME up -d
    
    echo ""
    echo "✅ Environment started!"
    echo ""
    echo "📍 Services available at:"
    echo "   • API Server: http://localhost:3000"
    echo "   • Temporal UI: http://localhost:8080"
    echo ""
    echo "📊 View logs: ./dev.sh logs"
    echo "🐚 Open shell: ./dev.sh shell"
    echo "🛠  Rails console: ./dev.sh console"
}

stop() {
    echo "⏹️  Stopping Outhad development environment..."
    docker-compose -p $PROJECT_NAME down
    echo "✅ Environment stopped!"
}

restart() {
    echo "🔄 Restarting Outhad development environment..."
    stop
    start
}

logs() {
    docker-compose -p $PROJECT_NAME logs -f
}

logs_api() {
    docker-compose -p $PROJECT_NAME logs -f outhad-server
}

shell() {
    echo "🐚 Opening shell in API container..."
    docker-compose -p $PROJECT_NAME exec outhad-server bash
}

console() {
    echo "🛠  Opening Rails console..."
    docker-compose -p $PROJECT_NAME exec outhad-server bundle exec rails console
}

test() {
    echo "🧪 Running test suite..."
    docker-compose -p $PROJECT_NAME exec outhad-server bundle exec rspec
}

build() {
    echo "🔨 Rebuilding containers..."
    docker-compose -p $PROJECT_NAME build --no-cache
    echo "✅ Rebuild complete!"
}

clean() {
    echo "🧹 Cleaning up containers and volumes..."
    read -p "This will remove all containers and volumes. Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose -p $PROJECT_NAME down -v
        docker-compose -p $PROJECT_NAME rm -f
        docker system prune -f
        echo "✅ Cleanup complete!"
    else
        echo "Cleanup cancelled."
    fi
}

status() {
    echo "📊 Service status:"
    docker-compose -p $PROJECT_NAME ps
}

# Main command handler
case "${1:-help}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs
        ;;
    logs-api)
        logs_api
        ;;
    shell)
        shell
        ;;
    console)
        console
        ;;
    test)
        test
        ;;
    build)
        build
        ;;
    clean)
        clean
        ;;
    status)
        status
        ;;
    help|--help|-h)
        help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        help
        exit 1
        ;;
esac