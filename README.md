# AI News Summarizer + LinkedIn Publisher

An automated n8n workflow that scrapes daily news articles, summarizes them using AI, and publishes the summaries to LinkedIn with optimized formatting and hashtags.

## 🚀 Features

- **Automated News Collection**: Fetches articles from multiple RSS feeds (TechCrunch, Vox, CNBC, etc.)
- **AI-Powered Summarization**: Uses OpenAI GPT-4o-mini to create engaging summaries
- **Content Quality Filtering**: Filters out low-quality or irrelevant content
- **LinkedIn Optimization**: Formats posts with proper hashtags, character limits, and engagement patterns
- **Deduplication**: Prevents posting the same article multiple times
- **Scheduling**: Runs daily via cron trigger
- **Error Handling**: Robust error handling and logging
- **Newsletter Generation**: Optional weekly email newsletter compilation

## 📋 Prerequisites

- **n8n** (running via Docker or local installation)
- **OpenAI API Key** (for content summarization)
- **LinkedIn Developer Account** (for posting to LinkedIn)
- **Docker** (recommended for easy setup)

## 🏗️ Architecture

```
Daily Trigger → RSS Feeds → Content Filtering → AI Summarization → LinkedIn Publishing
     ↓              ↓              ↓                ↓                ↓
  Schedule    Multiple Sources  Quality Check   GPT-4o-mini    Optimized Posts
```

## 📁 Project Structure

```
n8n-ai-news2linked/
├── workflows/
│   ├── ai-news-summarizer-production.json    # Main production workflow
│   └── newsletter-generator.json             # Optional newsletter workflow
├── config/
│   ├── news-sources.json                     # RSS feed configurations
│   ├── prompts.json                          # AI prompt templates
│   └── linkedin-templates.json               # LinkedIn post templates
├── docs/
│   ├── setup-guide.md                        # Detailed setup instructions
│   ├── troubleshooting.md                    # Common issues and solutions
│   └── api-reference.md                      # API documentation
├── scripts/
│   ├── setup.sh                              # Automated setup script
│   └── test-workflow.sh                      # Workflow testing script
├── .env                                      # Environment variables (create this)
├── .gitignore                                # Git ignore rules
└── README.md                                 # This file
```

## ⚡ Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/huss-huss/n8n-ai-news2linked.git
cd n8n-ai-news2linked
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Configure Environment

Create a `.env` file with your API keys:

```bash
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=500
OPENAI_TEMPERATURE=0.7

# LinkedIn Configuration
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
LINKEDIN_REDIRECT_URI=http://localhost:5678/callback

# Workflow Settings
MAX_ARTICLES_PER_SOURCE=5
MAX_TOTAL_ARTICLES=10
MIN_ARTICLE_AGE_HOURS=1
MAX_ARTICLE_AGE_HOURS=24
```

### 3. Start n8n

```bash
# Using Docker (recommended)
docker run -d --name n8n -p 5678:5678 n8nio/n8n

# Or using local installation
n8n start
```

### 4. Import Workflow

1. Open n8n at `http://localhost:5678`
2. Go to Workflows → Import from File
3. Select `workflows/ai-news-summarizer-production.json`
4. Configure your credentials (OpenAI and LinkedIn)

### 5. Test and Deploy

1. Test with a single article first
2. Monitor the workflow execution
3. Schedule for daily runs

## 🔧 Configuration

### News Sources (`config/news-sources.json`)

Configure RSS feeds, filtering criteria, and content preferences:

```json
{
  "sources": [
    {
      "name": "TechCrunch",
      "url": "https://techcrunch.com/feed/",
      "category": "technology",
      "enabled": true,
      "priority": 1
    }
  ],
  "settings": {
    "max_articles_per_source": 5,
    "max_total_articles": 10,
    "keywords_filter": ["AI", "technology", "innovation"],
    "exclude_keywords": ["sponsored", "advertisement"]
  }
}
```

### AI Prompts (`config/prompts.json`)

Customize AI behavior for summarization and content optimization:

```json
{
  "summarization": {
    "system": "You are an expert content summarizer...",
    "user_template": "Summarize this article in {max_words} words...",
    "max_words": 150,
    "temperature": 0.7
  }
}
```

### LinkedIn Templates (`config/linkedin-templates.json`)

Define post formats and hashtag strategies:

```json
{
  "post_templates": {
    "standard": {
      "format": "{title}\n\n{summary}\n\nRead more: {link}\n\n{hashtags}",
      "max_length": 1300
    }
  },
  "hashtag_sets": {
    "technology": ["#Tech", "#Innovation", "#AI", "#Technology"]
  }
}
```

## 🔄 Workflow Components

### Main Workflow (`ai-news-summarizer-production.json`)

1. **Daily Trigger**: Cron-based scheduling
2. **RSS Fetching**: HTTP requests to multiple RSS feeds
3. **Content Parsing**: Custom JavaScript for XML parsing
4. **Content Filtering**: Quality and relevance checks
5. **AI Summarization**: OpenAI-powered content summarization
6. **Post Formatting**: LinkedIn-optimized formatting
7. **LinkedIn Publishing**: Automated posting with error handling
8. **Success Logging**: Comprehensive execution logging

### Newsletter Workflow (`newsletter-generator.json`)

Optional workflow for generating weekly email newsletters by compiling summaries of posted articles.

## 📊 Monitoring and Logging

- **Execution Logs**: Detailed logs in n8n interface
- **Success Tracking**: Post IDs and URLs logged
- **Error Handling**: Graceful failure handling
- **Performance Metrics**: Character counts, processing times

## 🛠️ Troubleshooting

Common issues and solutions:

### LinkedIn API Issues
- **OAuth Scope Errors**: Ensure all required scopes are added in LinkedIn Developer Console
- **Posting Failures**: Check credential authentication and permissions

### OpenAI API Issues
- **Connection Errors**: Verify API key and network connectivity
- **Rate Limits**: Monitor usage and implement backoff strategies

### RSS Feed Issues
- **Parsing Errors**: Check feed availability and XML structure
- **No Content**: Verify feed URLs and content filtering settings

See `docs/troubleshooting.md` for detailed solutions.

## 🔒 Security

- **API Keys**: Stored in `.env` file (not committed to git)
- **OAuth2**: Secure LinkedIn authentication
- **Data Privacy**: No personal data stored or transmitted
- **Rate Limiting**: Respects API rate limits

## 🚀 Future Enhancements

- [ ] **Multi-platform Publishing**: Twitter, Facebook, Medium
- [ ] **Advanced Analytics**: Engagement tracking and optimization
- [ ] **Content Scheduling**: Intelligent posting times
- [ ] **Image Generation**: AI-generated post images
- [ ] **Sentiment Analysis**: Content sentiment optimization
- [ ] **A/B Testing**: Post format optimization
- [ ] **Webhook Integration**: Real-time content triggers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation**: Check `docs/` folder
- **Issues**: Create GitHub issues for bugs
- **Discussions**: Use GitHub Discussions for questions

## 🎯 Success Metrics

- **Automated Daily Posts**: Consistent LinkedIn content
- **Engagement Rates**: Optimized for LinkedIn algorithm
- **Content Quality**: AI-filtered high-quality summaries
- **Time Savings**: Automated workflow reduces manual effort

---

**Built with ❤️ using n8n, OpenAI, and LinkedIn APIs**
