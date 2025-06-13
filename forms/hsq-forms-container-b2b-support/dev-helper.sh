#!/bin/bash
# HSQ Forms B2B Support - Development Helper Script

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}HSQ Forms B2B Support - Development Helper${NC}"
echo "========================================"

# Function to show current status
show_status() {
    echo -e "\n${BLUE}Current Docker Status:${NC}"
    docker-compose ps
}

# Function for quick rebuild
quick_rebuild() {
    echo -e "\n${GREEN}Quick rebuild and restart...${NC}"
    docker-compose down
    docker-compose up --build -d
    echo -e "${GREEN}✅ Container rebuilt and running!${NC}"
    echo -e "Access at: http://localhost:3003"
}

# Function for development mode
dev_mode() {
    echo -e "\n${GREEN}Starting development mode...${NC}"
    docker-compose -f docker-compose.dev.yml up --build
}

# Function to stop all
stop_all() {
    echo -e "\n${RED}Stopping all containers...${NC}"
    docker-compose down
    docker-compose -f docker-compose.dev.yml down 2>/dev/null
}

# Function to clean rebuild
clean_rebuild() {
    echo -e "\n${GREEN}Clean rebuild (removes cache)...${NC}"
    docker-compose down
    docker-compose build --no-cache
    docker-compose up -d
    echo -e "${GREEN}✅ Clean rebuild complete!${NC}"
    echo -e "Access at: http://localhost:3003"
}

# Menu
case "$1" in
    status)
        show_status
        ;;
    quick)
        quick_rebuild
        ;;
    dev)
        dev_mode
        ;;
    clean)
        clean_rebuild
        ;;
    stop)
        stop_all
        ;;
    *)
        echo "Usage: $0 {status|quick|dev|clean|stop}"
        echo ""
        echo "Commands:"
        echo "  status  - Show current container status"
        echo "  quick   - Quick rebuild and restart (same container name)"
        echo "  dev     - Start development mode with live reload"
        echo "  clean   - Clean rebuild (removes Docker cache)"
        echo "  stop    - Stop all containers"
        echo ""
        echo "Examples:"
        echo "  ./dev-helper.sh quick   # För snabba uppdateringar"
        echo "  ./dev-helper.sh dev     # För aktiv utveckling"
        echo "  ./dev-helper.sh clean   # När något är trasigt"
        ;;
esac
