# Setup Guide - AI News Summarizer + LinkedIn Publisher

This guide will walk you through setting up the AI News Summarizer workflow step by step.

## Prerequisites

Before you begin, ensure you have:

- [ ] n8n installed (self-hosted or cloud)
- [ ] OpenAI API key
- [ ] LinkedIn Developer account
- [ ] Basic understanding of RSS feeds and APIs

## Step 1: Project Setup

### 1.1 Clone and Initialize

```bash
# Clone the repository (if using git)
git clone <your-repo-url>
cd n8n-ai-news2linked

# Run the setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 1.2 Verify Installation

The setup script will:
- ✅ Check n8n installation
- ✅ Create configuration files
- ✅ Validate JSON syntax
- ✅ Create test scripts

## Step 2: API Configuration

### 2.1 OpenAI Setup

1. **Get API Key**:
   - Visit [OpenAI Platform](https://platform.openai.com/)
   - Sign up or log in
   - Go to API Keys section
   - Create a new API key
   - Copy the key (starts with `sk-`)

2. **Configure in .env**:
   ```bash
   # Edit .env file
   nano .env
   
   # Update these values:
   OPENAI_API_KEY=sk-your-actual-api-key-here
   OPENAI_MODEL=gpt-4
   OPENAI_MAX_TOKENS=500
   OPENAI_TEMPERATURE=0.7
   ```

### 2.2 LinkedIn Setup

1. **Create LinkedIn App**:
   - Visit [LinkedIn Developers](https://www.linkedin.com/developers/)
   - Click "Create App"
   - Fill in app details:
     - App name: "AI News Summarizer"
     - LinkedIn Page: Your company page (optional)
     - App Logo: Upload a logo
   - Submit for review

2. **Configure OAuth 2.0**:
   - In your app dashboard, go to "Auth" tab
   - Add redirect URL: `http://localhost:5678/callback`
   - Note your Client ID and Client Secret

3. **Request Permissions**:
   - Go to "Products" tab
   - Add "Share on LinkedIn" product
   - Request these scopes:
     - `w_member_social` (for personal posting)
     - `w_organization_social` (for company page posting)

4. **Update .env**:
   ```bash
   LINKEDIN_CLIENT_ID=your_client_id_here
   LINKEDIN_CLIENT_SECRET=your_client_secret_here
   LINKEDIN_REDIRECT_URI=http://localhost:5678/callback
   ```

## Step 3: n8n Configuration

### 3.1 Import Workflow

1. **Start n8n**:
   ```bash
   n8n start
   ```

2. **Import Workflow**:
   - Open n8n in your browser (usually `http://localhost:5678`)
   - Click "Import from file"
   - Select `workflows/ai-news-summarizer.json`
   - Click "Import"

### 3.2 Configure Credentials

1. **OpenAI Credential**:
   - In n8n, go to Settings → Credentials
   - Click "Add Credential"
   - Select "OpenAI API"
   - Name: "OpenAI News Summarizer"
   - API Key: Your OpenAI API key
   - Save

2. **LinkedIn Credential**:
   - Click "Add Credential"
   - Select "LinkedIn OAuth2 API"
   - Name: "LinkedIn Publisher"
   - Client ID: Your LinkedIn Client ID
   - Client Secret: Your LinkedIn Client Secret
   - Authorization URL: `https://www.linkedin.com/oauth/v2/authorization`
   - Token URL: `https://www.linkedin.com/oauth/v2/accessToken`
   - Scope: `w_member_social w_organization_social`
   - Save

### 3.3 Update Workflow Nodes

1. **OpenAI Node**:
   - Click on "Summarize with OpenAI" node
   - Select your OpenAI credential
   - Verify model settings (GPT-4 recommended)

2. **LinkedIn Node**:
   - Click on "Post to LinkedIn" node
   - Select your LinkedIn credential
   - Test the connection

## Step 4: Customize Configuration

### 4.1 RSS Feeds

Edit `config/news-sources.json` to add your preferred news sources:

```json
{
  "sources": [
    {
      "name": "Your Favorite Tech Blog",
      "url": "https://yourblog.com/feed/",
      "category": "technology",
      "enabled": true,
      "priority": 1
    }
  ]
}
```

### 4.2 AI Prompts

Customize AI behavior in `config/prompts.json`:

```json
{
  "summarization": {
    "system": "Your custom system prompt here...",
    "max_words": 120,
    "temperature": 0.7
  }
}
```

### 4.3 LinkedIn Templates

Modify post formats in `config/linkedin-templates.json`:

```json
{
  "post_templates": {
    "custom": {
      "format": "Your custom format here...",
      "max_length": 3000
    }
  }
}
```

## Step 5: Testing

### 5.1 Run Test Script

```bash
./scripts/test-workflow.sh
```

This will test:
- ✅ RSS feed connectivity
- ✅ OpenAI API connection
- ✅ Configuration file syntax

### 5.2 Manual Testing

1. **Test RSS Feeds**:
   - In n8n, click on any RSS node
   - Click "Execute Node"
   - Verify articles are fetched

2. **Test OpenAI**:
   - Execute "Summarize with OpenAI" node
   - Check if summaries are generated
   - Verify JSON format

3. **Test LinkedIn**:
   - Execute "Post to LinkedIn" node
   - Check if post is created
   - Verify on your LinkedIn profile

## Step 6: Deployment

### 6.1 Production Setup

1. **Environment Variables**:
   ```bash
   # Use environment variables in production
   export OPENAI_API_KEY="your-key"
   export LINKEDIN_CLIENT_ID="your-id"
   export LINKEDIN_CLIENT_SECRET="your-secret"
   ```

2. **n8n Production**:
   ```bash
   # Start n8n in production mode
   n8n start --tunnel
   ```

3. **Schedule Workflow**:
   - In n8n, activate the workflow
   - It will run daily at 8:00 AM
   - Monitor execution logs

### 6.2 Monitoring

1. **Check Logs**:
   ```bash
   tail -f logs/workflow.log
   ```

2. **Monitor API Usage**:
   - OpenAI: Check usage in OpenAI dashboard
   - LinkedIn: Monitor API calls in LinkedIn app

## Troubleshooting

### Common Issues

1. **LinkedIn OAuth Errors**:
   - Verify redirect URL matches exactly
   - Check app scopes are approved
   - Ensure app is not in development mode

2. **OpenAI Rate Limits**:
   - Check API key validity
   - Monitor usage limits
   - Implement retry logic

3. **RSS Feed Issues**:
   - Verify feed URLs are accessible
   - Check feed format compatibility
   - Test with curl: `curl -I feed-url`

### Getting Help

- Check `docs/troubleshooting.md` for detailed solutions
- Review n8n community forums
- Check API documentation for each service

## Security Best Practices

1. **API Keys**:
   - Never commit API keys to version control
   - Use environment variables
   - Rotate keys regularly

2. **Access Control**:
   - Limit n8n access to authorized users
   - Use HTTPS in production
   - Monitor access logs

3. **Data Privacy**:
   - Review data retention policies
   - Ensure GDPR compliance if applicable
   - Secure stored data

## Next Steps

After setup:

1. **Monitor Performance**:
   - Track post engagement
   - Monitor API costs
   - Analyze content quality

2. **Optimize**:
   - Adjust RSS feeds based on quality
   - Fine-tune AI prompts
   - Optimize posting schedule

3. **Scale**:
   - Add more news sources
   - Implement A/B testing
   - Add analytics dashboard

---

**Need help?** Check the troubleshooting guide or create an issue in the repository.
