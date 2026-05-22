#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# ANSI escape codes for coloring output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Starting Local Validation Gates ===${NC}"

# Step 1: Format check
echo -e "\n${YELLOW}Step 1: Checking Code Formatting...${NC}"
if dart format --set-exit-if-changed . ; then
    echo -e "${GREEN}✓ Code is correctly formatted.${NC}"
else
    echo -e "${RED}✗ Formatting issues found. Please run 'dart format .' to fix them.${NC}"
    exit 1
fi

# Step 2: Static Analysis
echo -e "\n${YELLOW}Step 2: Running Static Analysis (dart analyze)...${NC}"
if dart analyze . ; then
    echo -e "${GREEN}✓ No analysis issues found.${NC}"
else
    echo -e "${RED}✗ Analysis failed. Please fix errors and warnings shown above.${NC}"
    exit 1
fi

# Step 3: Tests
echo -e "\n${YELLOW}Step 3: Running Tests (dart test)...${NC}"
if dart test ; then
    echo -e "${GREEN}✓ All tests passed.${NC}"
else
    echo -e "${RED}✗ Test suite failed.${NC}"
    exit 1
fi

echo -e "\n${GREEN}=======================================${NC}"
echo -e "${GREEN}✓ Success: All quality gates passed!${NC}"
echo -e "${GREEN}=======================================${NC}"
