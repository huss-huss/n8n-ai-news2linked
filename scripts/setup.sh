#!/bin/bash

# AI News Summarizer + LinkedIn Publisher Setup Script
# This script helps you set up the n8n workflow project

set -e

echo "🚀 Setting up AI News Summarizer + LinkedIn Publisher"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if n8n is installed or running in Docker
check_n8n() {
    print_info "Checking n8n installation..."
    
    if command -v n8n &> /dev/null; then
        print_status "n8n is installed locally"
        n8n --version
    elif docker ps | grep -q n8n; then
        print_status "n8n is running in Docker"
        docker ps | grep n8n
    else
        print_warning "n8n is not detected"
        echo "Please ensure n8n is running:"
        echo "  - Local: npm install -g n8n && n8n start"
        echo "  - Docker: docker run -it --rm --name n8n -p 5678:5678 n8nio/n8n"
        echo "  - Or visit: https://n8n.io/installation/"
        echo ""
        print_info "Continuing with setup (you can configure n8n later)..."
    fi
}

# Create environment file
create_env_file() {
    print_info "Creating environment configuration..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# AI News Summarizer + LinkedIn Publisher Configuration

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4
OPENAI_MAX_TOKENS=500
OPENAI_TEMPERATURE=0.7

# LinkedIn Configuration
LINKEDIN_CLIENT_ID=your_linkedin_client_id_here
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret_here
LINKEDIN_REDIRECT_URI=http://localhost:5678/callback

# Workflow Configuration
MAX_ARTICLES_PER_RUN=10
MAX_POSTS_PER_DAY=3
POSTING_SCHEDULE="0 8 * * *"
CHARACTER_LIMIT=3000

# RSS Feed Configuration
RSS_FEEDS_FILE=config/news-sources.json
PROMPTS_FILE=config/prompts.json
LINKEDIN_TEMPLATES_FILE=config/linkedin-templates.json

# Logging Configuration
LOG_LEVEL=info
LOG_FILE=logs/workflow.log

# Optional: Email Configuration (for newsletter)
EMAIL_ENABLED=false
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_USERNAME=your_email@gmail.com
EMAIL_PASSWORD=your_app_password
EMAIL_FROM=your_email@gmail.com
EMAIL_TO=subscribers@example.com
EOF
        print_status "Created .env file"
        print_warning "Please edit .env file with your actual API keys and configuration"
    else
        print_status ".env file already exists"
    fi
}

# Create logs directory
create_logs_dir() {
    print_info "Creating logs directory..."
    mkdir -p logs
    print_status "Created logs directory"
}

# Check required files
check_config_files() {
    print_info "Checking configuration files..."
    
    required_files=(
        "config/news-sources.json"
        "config/prompts.json"
        "config/linkedin-templates.json"
        "workflows/ai-news-summarizer.json"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_status "✓ $file"
        else
            print_error "✗ $file (missing)"
            exit 1
        fi
    done
}

# Validate JSON files
validate_json() {
    print_info "Validating JSON configuration files..."
    
    json_files=(
        "config/news-sources.json"
        "config/prompts.json"
        "config/linkedin-templates.json"
        "workflows/ai-news-summarizer.json"
    )
    
    for file in "${json_files[@]}"; do
        if python3 -m json.tool "$file" > /dev/null 2>&1; then
            print_status "✓ $file (valid JSON)"
        else
            print_error "✗ $file (invalid JSON)"
            exit 1
        fi
    done
}

# Create test script
create_test_script() {
    print_info "Creating test script..."
    
    cat > scripts/test-workflow.sh << 'EOF'
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
EOF

    chmod +x scripts/test-workflow.sh
    print_status "Created test script"
}

# Main setup function
main() {
    echo ""
    check_n8n
    echo ""
    create_env_file
    echo ""
    create_logs_dir
    echo ""
    check_config_files
    echo ""
    validate_json
    echo ""
    create_test_script
    echo ""
    
    print_status "Setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Edit .env file with your API keys"
    echo "2. Run: ./scripts/test-workflow.sh"
    echo "3. Import workflows/ai-news-summarizer.json to n8n"
    echo "4. Configure LinkedIn OAuth credentials in n8n"
    echo "5. Test the workflow manually"
    echo ""
    echo "📚 Documentation:"
    echo "- README.md - Project overview and setup"
    echo "- docs/setup-guide.md - Detailed setup instructions"
    echo "- docs/troubleshooting.md - Common issues and solutions"
    echo ""
    print_warning "Don't forget to secure your .env file and never commit API keys to version control!"
}

# Run main function
main
