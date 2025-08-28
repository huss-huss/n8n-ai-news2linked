# API Reference

This document provides detailed information about the external APIs used in the AI News Summarizer workflow.

## OpenAI API

### Overview
OpenAI's GPT models are used for intelligent content summarization and generation.

### Configuration
```bash
# Environment variables
OPENAI_API_KEY=sk-your-api-key-here
OPENAI_MODEL=gpt-4
OPENAI_MAX_TOKENS=500
OPENAI_TEMPERATURE=0.7
```

### Endpoints Used

#### Chat Completions
- **URL**: `https://api.openai.com/v1/chat/completions`
- **Method**: POST
- **Purpose**: Generate article summaries and newsletter content

#### Request Format
```json
{
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "You are a professional content editor..."
    },
    {
      "role": "user",
      "content": "Please summarize this article..."
    }
  ],
  "max_tokens": 500,
  "temperature": 0.7
}
```

#### Response Format
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "{\"summary\": \"...\", \"hashtags\": \"#AI #Tech\"}"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 50,
    "total_tokens": 150
  }
}
```

### Rate Limits
- **Free tier**: 3 requests per minute
- **Paid tier**: 3,500 requests per minute
- **Token limits**: Varies by model

### Error Handling
```javascript
// Common error codes
400: Bad Request (invalid prompt)
401: Unauthorized (invalid API key)
429: Rate Limit Exceeded
500: Internal Server Error
```

## LinkedIn API

### Overview
LinkedIn's UGC (User Generated Content) API is used for posting content to LinkedIn profiles.

### Configuration
```bash
# Environment variables
LINKEDIN_CLIENT_ID=your-client-id
LINKEDIN_CLIENT_SECRET=your-client-secret
LINKEDIN_REDIRECT_URI=http://localhost:5678/callback
```

### OAuth 2.0 Flow

#### 1. Authorization Request
```
GET https://www.linkedin.com/oauth/v2/authorization
?response_type=code
&client_id=YOUR_CLIENT_ID
&redirect_uri=YOUR_REDIRECT_URI
&scope=w_member_social w_organization_social
&state=random_state_string
```

#### 2. Token Exchange
```json
POST https://www.linkedin.com/oauth/v2/accessToken
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=AUTHORIZATION_CODE
&client_id=YOUR_CLIENT_ID
&client_secret=YOUR_CLIENT_SECRET
&redirect_uri=YOUR_REDIRECT_URI
```

### Endpoints Used

#### Create Post
- **URL**: `https://api.linkedin.com/v2/ugcPosts`
- **Method**: POST
- **Headers**: 
  - `Authorization: Bearer {access_token}`
  - `Content-Type: application/json`
  - `X-Restli-Protocol-Version: 2.0.0`

#### Request Format
```json
{
  "author": "urn:li:person:{PERSON_ID}",
  "lifecycleState": "PUBLISHED",
  "specificContent": {
    "com.linkedin.ugc.ShareContent": {
      "shareMediaCategory": "NONE",
      "shareCommentary": {
        "text": "Your post content here..."
      }
    }
  },
  "visibility": {
    "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
  }
}
```

#### Response Format
```json
{
  "id": "urn:li:activity:123456789",
  "status": "PUBLISHED"
}
```

### Required Scopes
- `w_member_social`: Post to personal profile
- `w_organization_social`: Post to company pages

### Rate Limits
- **Personal posts**: 25 posts per day
- **Company posts**: 100 posts per day
- **API calls**: 100 requests per day per app

### Error Handling
```javascript
// Common error codes
400: Bad Request (invalid post content)
401: Unauthorized (invalid token)
403: Forbidden (insufficient permissions)
426: Upgrade Required (missing X-Restli-Protocol-Version header)
429: Rate Limit Exceeded
```

## RSS Feed APIs

### Overview
RSS feeds are used to fetch news articles from various sources.

### Supported Formats
- RSS 2.0
- RSS 1.0
- Atom

### Feed Structure
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Feed Title</title>
    <link>https://example.com</link>
    <description>Feed description</description>
    <item>
      <title>Article Title</title>
      <link>https://example.com/article</link>
      <description>Article description</description>
      <pubDate>Mon, 01 Jan 2024 12:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
```

### Parsed Data Structure
```json
{
  "title": "Article Title",
  "link": "https://example.com/article",
  "description": "Article description",
  "pubDate": "2024-01-01T12:00:00.000Z",
  "isoDate": "2024-01-01T12:00:00.000Z",
  "content": "Full article content (if available)"
}
```

### Error Handling
```javascript
// Common issues
- Feed not accessible (404, 403)
- Malformed XML
- Missing required fields
- Encoding issues
```

## Gmail API (Newsletter)

### Overview
Gmail API is used for sending newsletter emails.

### Configuration
```bash
# Environment variables
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
EMAIL_FROM=your-email@gmail.com
EMAIL_TO=subscribers@example.com
```

### OAuth 2.0 Setup
1. Create Google Cloud Project
2. Enable Gmail API
3. Create OAuth 2.0 credentials
4. Configure scopes: `https://www.googleapis.com/auth/gmail.send`

### Send Email Request
```json
POST https://gmail.googleapis.com/gmail/v1/users/me/messages/send
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "raw": "base64_encoded_email_message"
}
```

### Email Format
```json
{
  "to": "recipient@example.com",
  "from": "sender@example.com",
  "subject": "Newsletter Subject",
  "html": "<html>...</html>",
  "text": "Plain text version"
}
```

## Data Store API (n8n)

### Overview
n8n's Data Store is used for deduplication and tracking posted articles.

### Operations

#### Get Value
```javascript
// Check if article was already posted
const key = articleUrl;
const value = await dataStore.get(key);
```

#### Set Value
```javascript
// Mark article as posted
const key = articleUrl;
const value = {
  timestamp: new Date().toISOString(),
  postId: linkedinPostId,
  title: articleTitle
};
await dataStore.set(key, value);
```

#### Get All Values
```javascript
// Get all posted articles for newsletter
const allArticles = await dataStore.getAll();
```

### Data Structure
```json
{
  "key": "https://example.com/article",
  "value": {
    "timestamp": "2024-01-01T12:00:00.000Z",
    "postId": "urn:li:activity:123456789",
    "title": "Article Title"
  }
}
```

## HTTP Request Node

### Overview
Used for custom API calls and web scraping when needed.

### Common Headers
```javascript
{
  "User-Agent": "Mozilla/5.0 (compatible; AI-News-Bot/1.0)",
  "Accept": "application/json, text/html",
  "Accept-Language": "en-US,en;q=0.9",
  "Cache-Control": "no-cache"
}
```

### Error Handling
```javascript
// Retry logic for failed requests
const maxRetries = 3;
let attempt = 0;

while (attempt < maxRetries) {
  try {
    const response = await httpRequest(url, options);
    return response;
  } catch (error) {
    if (error.status === 429 || error.status >= 500) {
      attempt++;
      await sleep(1000 * attempt);
    } else {
      throw error;
    }
  }
}
```

## Rate Limiting Strategies

### Exponential Backoff
```javascript
const backoffDelay = Math.min(1000 * Math.pow(2, attempt), 30000);
await sleep(backoffDelay);
```

### Token Bucket
```javascript
// Implement token bucket for rate limiting
class TokenBucket {
  constructor(tokens, refillRate) {
    this.tokens = tokens;
    this.maxTokens = tokens;
    this.refillRate = refillRate;
    this.lastRefill = Date.now();
  }
  
  async consume() {
    this.refill();
    if (this.tokens > 0) {
      this.tokens--;
      return true;
    }
    return false;
  }
  
  refill() {
    const now = Date.now();
    const timePassed = now - this.lastRefill;
    const tokensToAdd = Math.floor(timePassed * this.refillRate / 1000);
    this.tokens = Math.min(this.maxTokens, this.tokens + tokensToAdd);
    this.lastRefill = now;
  }
}
```

## Monitoring and Analytics

### API Usage Tracking
```javascript
// Track API calls for monitoring
const apiMetrics = {
  openai: {
    calls: 0,
    tokens: 0,
    errors: 0
  },
  linkedin: {
    posts: 0,
    errors: 0
  },
  rss: {
    feeds: 0,
    articles: 0,
    errors: 0
  }
};
```

### Health Checks
```javascript
// Health check endpoints
const healthChecks = {
  openai: async () => {
    const response = await fetch('https://api.openai.com/v1/models');
    return response.status === 200;
  },
  linkedin: async () => {
    const response = await fetch('https://api.linkedin.com/v2/me');
    return response.status === 200;
  }
};
```

## Security Considerations

### API Key Management
- Store keys in environment variables
- Rotate keys regularly
- Use least privilege principle
- Monitor key usage

### Data Privacy
- Minimize data collection
- Encrypt sensitive data
- Follow GDPR guidelines
- Implement data retention policies

### Error Handling
- Don't expose sensitive data in errors
- Log errors securely
- Implement proper error codes
- Provide user-friendly error messages

---

**For more information:**
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [LinkedIn API Documentation](https://developer.linkedin.com/docs)
- [Gmail API Documentation](https://developers.google.com/gmail/api)
- [n8n Documentation](https://docs.n8n.io/)
