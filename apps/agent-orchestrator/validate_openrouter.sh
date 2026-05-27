#!/bin/bash
# OPENROUTER_BACKEND_VALIDATION.sh
# Comprehensive validation script for OpenRouter integration

echo "=========================================="
echo "OpenRouter Backend Integration Validation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test 1: Check if backend directory exists
echo -n "Test 1: Backend directory exists... "
if [ -d "apps/backend" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi
echo ""

# Test 2: Check .env file exists
echo -n "Test 2: .env file exists... "
if [ -f "apps/backend/.env" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Create .env from .env.example"
    ((FAILED++))
fi
echo ""

# Test 3: Check OPENROUTER_API_KEY in .env
echo -n "Test 3: OPENROUTER_API_KEY configured... "
if grep -q "OPENROUTER_API_KEY" apps/backend/.env 2>/dev/null; then
    KEY=$(grep "OPENROUTER_API_KEY" apps/backend/.env | grep -v "^#" | head -1)
    if [[ $KEY == *"sk-or-v1"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
    elif [[ $KEY == *"="* ]]; then
        echo -e "${YELLOW}⚠ WARNING${NC} - Key not set or invalid format"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - OPENROUTER_API_KEY not found"
    ((FAILED++))
fi
echo ""

# Test 4: Check Python files exist
echo -n "Test 4: Python source files... "
PYTHON_FILES=(
    "apps/backend/app/main.py"
    "apps/backend/app/agent/factory.py"
    "apps/backend/app/agent/agents.py"
    "apps/backend/app/agent/workflow.py"
    "apps/backend/app/config/settings.py"
)

ALL_EXIST=true
for file in "${PYTHON_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        ALL_EXIST=false
        echo -e "${RED}Missing: $file${NC}"
    fi
done

if [ "$ALL_EXIST" = true ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi
echo ""

# Test 5: Check for LLMService imports (should not exist)
echo -n "Test 5: No LLMService imports... "
LLMSERVICE_COUNT=$(grep -r "from app.services.llm import LLMService" apps/backend/app/ 2>/dev/null | wc -l)
if [ "$LLMSERVICE_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Found $LLMSERVICE_COUNT LLMService imports"
    ((FAILED++))
fi
echo ""

# Test 6: Check create_agent imports
echo -n "Test 6: create_agent properly imported... "
CREATE_AGENT_COUNT=$(grep -r "from app.agent.factory import create_agent" apps/backend/app/ 2>/dev/null | wc -l)
if [ "$CREATE_AGENT_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} (found in $CREATE_AGENT_COUNT files)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - create_agent not imported"
    ((FAILED++))
fi
echo ""

# Test 7: Check OpenRouter configuration
echo -n "Test 7: OpenRouter config in settings... "
if grep -q "OPENROUTER_API_KEY" apps/backend/app/config/settings.py && \
   grep -q "openrouter_api_key" apps/backend/app/config/settings.py; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi
echo ""

# Test 8: Check documentation
echo -n "Test 8: Documentation files... "
DOCS=(
    "OPENROUTER_GUIDE.md"
    "apps/backend/.env.example"
    "INTEGRATION_STATUS.md"
)

DOCS_OK=true
for doc in "${DOCS[@]}"; do
    if [ ! -f "$doc" ]; then
        echo -e "${RED}Missing: $doc${NC}"
        DOCS_OK=false
    fi
done

if [ "$DOCS_OK" = true ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAILED++))
fi
echo ""

# Test 9: Python syntax check (if python available)
echo -n "Test 9: Python syntax validation... "
if command -v python3 &> /dev/null; then
    SYNTAX_ERROR=false
    for file in "${PYTHON_FILES[@]}"; do
        if ! python3 -m py_compile "$file" 2>/dev/null; then
            echo -e "${RED}Syntax error in $file${NC}"
            SYNTAX_ERROR=true
        fi
    done
    
    if [ "$SYNTAX_ERROR" = false ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}⚠ SKIP${NC} - Python not available"
fi
echo ""

# Summary
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Start the backend:"
    echo "   cd apps/backend"
    echo "   python -m uvicorn app.main:app --port 8100"
    echo ""
    echo "2. Test the agents:"
    echo "   python scripts/test_agent.py"
    echo ""
    echo "3. Check OPENROUTER_GUIDE.md for detailed setup"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Issues found:"
    echo "- Review the failed tests above"
    echo "- Check INTEGRATION_STATUS.md for setup instructions"
    echo "- Read OPENROUTER_GUIDE.md for detailed configuration"
    exit 1
fi
