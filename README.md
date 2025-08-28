# AI Summarizer + LinkedIn Publisher

An intelligent n8n workflow that automatically scrapes news articles, summarizes them using AI, and publishes the summaries to LinkedIn with proper formatting and hashtags.

## 🚀 Features

- **Automated News Fetching**: RSS feed integration for multiple news sources
- **AI-Powered Summarization**: OpenAI GPT integration for intelligent content summarization
- **Smart Deduplication**: Prevents posting duplicate articles
- **LinkedIn Integration**: Automatic posting to personal or company LinkedIn profiles
- **Content Formatting**: Professional formatting with hashtags and source attribution
- **Error Handling**: Robust error handling and retry mechanisms
- **Optional Newsletter**: Email newsletter functionality for subscribers

## 📋 Prerequisites

### LinkedIn Setup
1. Create a LinkedIn App at [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Configure OAuth 2.0 with required scopes:
   - `w_member_social` (for personal posting)
   - `w_organization_social` (for company page posting)
3. Note your Client ID and Client Secret

### OpenAI Setup
1. Get an OpenAI API key from [OpenAI Platform](https://platform.openai.com/)
2. Ensure you have sufficient credits for API calls

### n8n Setup
1. Install n8n (self-hosted or cloud)
2. Install required nodes:
   - RSS Read
   - OpenAI
   - LinkedIn
   - HTTP Request
   - Item Lists
   - Data Store

## 🏗️ Architecture

```
Cron Trigger → RSS Feeds → Content Processing → AI Summarization → LinkedIn Publishing
     ↓              ↓              ↓                ↓                ↓
Daily Schedule → Multiple Sources → Deduplication → OpenAI GPT → Formatted Posts
```

## 📁 Project Structure

```
n8n-ai-news2linked/
├── workflows/
│   ├── ai-news-summarizer.json          # Main workflow
│   └── newsletter-generator.json        # Optional newsletter workflow
├── config/
│   ├── news-sources.json               # RSS feed configurations
│   ├── prompts.json                    # AI prompt templates
│   └── linkedin-templates.json         # LinkedIn post templates
├── scripts/
│   ├── setup.sh                        # Setup script
│   └── test-workflow.sh                # Testing utilities
├── docs/
│   ├── setup-guide.md                  # Detailed setup instructions
│   ├── troubleshooting.md              # Common issues and solutions
│   └── api-reference.md                # API documentation
└── README.md                           # This file
```

## 🚀 Quick Start

1. **Clone and Setup**:
   ```bash
   git clone <your-repo>
   cd n8n-ai-news2linked
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

2. **Configure Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys and settings
   ```

3. **Import Workflow**:
   - Open n8n
   - Import `workflows/ai-news-summarizer.json`
   - Configure your credentials

4. **Test and Deploy**:
   ```bash
   ./scripts/test-workflow.sh
   ```

## ⚙️ Configuration

### News Sources
Edit `config/news-sources.json` to add your preferred RSS feeds:

```json
{
  "sources": [
    {
      "name": "TechCrunch",
      "url": "https://techcrunch.com/feed/",
      "category": "technology"
    },
    {
      "name": "Vox",
      "url": "https://www.vox.com/rss/index.xml",
      "category": "general"
    }
  ]
}
```

### AI Prompts
Customize AI behavior in `config/prompts.json`:

```json
{
  "summarization": {
    "system": "You are a concise editor. Summarize the article in ≤120 words, neutral tone, plain text (no markdown). Add up to 3 relevant hashtags (letter/number only). Return JSON: {summary, hashtags}.",
    "max_words": 120,
    "max_hashtags": 3
  }
}
```

## 🔧 Workflow Components

### 1. Trigger Node
- **Type**: Cron
- **Schedule**: Daily at 08:00 AM
- **Alternative**: RSS Feed Trigger for real-time processing

### 2. RSS Reader
- Fetches articles from configured RSS feeds
- Extracts title, link, description, and publication date
- Handles multiple feeds in parallel

### 3. Content Processing
- **Deduplication**: Checks Data Store for previously posted URLs
- **Content Enhancement**: Optional HTML fetching for better summaries
- **Filtering**: Removes low-quality or irrelevant content

### 4. AI Summarization
- **Model**: OpenAI GPT-4 or GPT-3.5-turbo
- **Input**: Article title + content excerpt
- **Output**: Structured JSON with summary and hashtags
- **Error Handling**: Retry logic for API failures

### 5. LinkedIn Publishing
- **Format**: Professional post with emoji, summary, source link, and hashtags
- **Character Limit**: Enforces 3,000 character LinkedIn limit
- **Visibility**: Configurable (public, connections, etc.)
- **Error Handling**: Specific handling for LinkedIn API errors

## 📊 Monitoring and Analytics

- **Success Rate**: Track successful posts vs. failures
- **Content Quality**: Monitor AI summary quality
- **Engagement**: Track LinkedIn post performance
- **Cost Tracking**: Monitor OpenAI API usage

## 🛠️ Troubleshooting

### Common Issues

1. **LinkedIn API Errors**:
   - Check OAuth scopes
   - Verify X-Restli-Protocol-Version header
   - Ensure app is approved

2. **OpenAI Rate Limits**:
   - Implement exponential backoff
   - Check API key validity
   - Monitor usage limits

3. **RSS Feed Issues**:
   - Verify feed URLs
   - Check feed format compatibility
   - Handle malformed XML

See `docs/troubleshooting.md` for detailed solutions.

## 🔒 Security Considerations

- Store API keys securely in n8n credentials
- Use environment variables for sensitive data
- Implement rate limiting to prevent abuse
- Regular security audits of third-party integrations

## 📈 Future Enhancements

- [ ] Multi-language support
- [ ] Advanced content filtering
- [ ] A/B testing for post formats
- [ ] Analytics dashboard
- [ ] Slack/Discord notifications
- [ ] Content scheduling
- [ ] Image generation for posts

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Issues**: Create an issue on GitHub
- **Documentation**: Check the `docs/` folder
- **Community**: Join n8n community discussions

---

**Built with ❤️ using n8n, OpenAI, and LinkedIn APIs**
