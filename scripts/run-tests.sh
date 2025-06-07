#!/bin/bash
# Run all tests
# Usage: ./scripts/run-tests.sh [pytest_options]

# Ställ in arbetskatalog till projektets rot-mapp
cd "$(dirname "$0")"

# Färgkoder för utmatning
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}🧪 Kör alla HSQ Forms API tester${NC}"
echo -e "${BLUE}============================================${NC}"

# Kontrollera om pytest finns
if ! command -v pytest &> /dev/null; then
    echo -e "${RED}❌ pytest är inte installerat.${NC}"
    echo -e "Installera med: pip install -r requirements-dev.txt"
    exit 1
fi

# Kör tester
echo -e "${BLUE}Kör tester med pytest...${NC}\n"
if pytest "$@"; then
    echo -e "\n${GREEN}✅ Alla tester genomförda!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Något test misslyckades.${NC}"
    echo -e "Se felmeddelanden ovan för detaljer."
    exit 1
fi
