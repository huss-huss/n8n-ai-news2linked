#!/bin/bash

# Test script for AI News Summarizer workflow

set -e

echo "🧪 Testing AI News Summarizer Workflow"
echo "====================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please run setup.sh first."
    exit 1
fi

# Load environment variables
source .env

# Test RSS feeds
test_rss_feeds() {
    print_status "Testing RSS feeds..."
    
    # Test a few RSS feeds
    feeds=(
        "https://techcrunch.com/feed/"
        "https://www.vox.com/rss/index.xml"
        "https://www.cnbc.com/id/19854910/device/rss/rss.html"
    )
    
    for feed in "${feeds[@]}"; do
        if curl -s --head "$feed" | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
            print_status "✓ $feed"
        else
            print_warning "⚠ $feed (may be down)"
        fi
    done
}

# Test OpenAI API
test_openai() {
    print_status "Testing OpenAI API..."
    
    if [ "$OPENAI_API_KEY" = "your_openai_api_key_here" ]; then
        print_warning "OpenAI API key not configured"
        return
    fi
    
    # Simple test request
    response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hello"}],
            "max_tokens": 10
        }' || echo "error")
    
    if echo "$response" | grep -q "choices"; then
        print_status "✓ OpenAI API connection successful"
    else
        print_error "✗ OpenAI API connection failed"
    fi
}

# Test configuration files
test_config() {
    print_status "Testing configuration files..."
    
    # Test JSON syntax
    if python3 -c "import json; json.load(open('config/news-sources.json'))" 2>/dev/null; then
        print_status "✓ news-sources.json"
    else
        print_error "✗ news-sources.json"
    fi
    
    if python3 -c "import json; json.load(open('config/prompts.json'))" 2>/dev/null; then
        print_status "✓ prompts.json"
    else
        print_error "✗ prompts.json"
    fi
}

# Run tests
test_rss_feeds
test_openai
test_config

echo ""
print_status "Test completed! Check the results above."
echo ""
echo "Next steps:"
echo "1. Configure your API keys in .env"
echo "2. Import the workflow to n8n"
echo "3. Set up LinkedIn OAuth credentials"
echo "4. Test the workflow manually"
