# Troubleshooting Guide

This guide covers common issues and their solutions for the AI News Summarizer workflow.

## Quick Diagnosis

### Check Workflow Status

1. **In n8n**:
   - Go to Workflows → Your workflow
   - Check execution history
   - Look for failed nodes (red indicators)

2. **Check Logs**:
   ```bash
   # View recent logs
   tail -f logs/workflow.log
   
   # Check n8n logs
   n8n logs
   ```

3. **Test Individual Components**:
   ```bash
   # Run test script
   ./scripts/test-workflow.sh
   ```

## Common Issues & Solutions

### 1. LinkedIn API Issues

#### Issue: "Invalid OAuth 2.0 credentials"

**Symptoms**:
- 401 Unauthorized errors
- "Invalid client_id" messages
- OAuth flow fails

**Solutions**:

1. **Check App Configuration**:
   ```bash
   # Verify in LinkedIn Developer Console
   - App is not in development mode
   - Redirect URL matches exactly: http://localhost:5678/callback
   - Required scopes are approved: w_member_social, w_organization_social
   ```

2. **Re-authenticate**:
   - In n8n, go to Credentials
   - Delete existing LinkedIn credential
   - Create new credential with correct Client ID/Secret
   - Complete OAuth flow again

3. **Check App Status**:
   - Ensure app is approved by LinkedIn
   - Verify app is not in development mode
   - Check if app has required permissions

#### Issue: "X-Restli-Protocol-Version header required"

**Symptoms**:
- 426 errors from LinkedIn API
- Posts fail to publish

**Solutions**:

1. **Update n8n**:
   ```bash
   # Update to latest n8n version
   npm update -g n8n
   ```

2. **Manual Header Fix**:
   - In LinkedIn node, add custom headers
   - Add: `X-Restli-Protocol-Version: 2.0.0`

3. **Use HTTP Request Node**:
   ```javascript
   // Alternative: Use HTTP Request node
   {
     "method": "POST",
     "url": "https://api.linkedin.com/v2/ugcPosts",
     "headers": {
       "Authorization": "Bearer {{ $credentials.linkedin.accessToken }}",
       "Content-Type": "application/json",
       "X-Restli-Protocol-Version": "2.0.0"
     },
     "body": {
       "author": "urn:li:person:YOUR_PERSON_URN",
       "lifecycleState": "PUBLISHED",
       "specificContent": {
         "com.linkedin.ugc.ShareContent": {
           "shareMediaCategory": "NONE",
           "shareCommentary": {
             "text": "{{ $json.postText }}"
           }
         }
       },
       "visibility": {
         "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
       }
     }
   }
   ```

#### Issue: "Character limit exceeded"

**Symptoms**:
- Posts fail with 400 errors
- "Text too long" messages

**Solutions**:

1. **Check Character Count**:
   ```javascript
   // Add validation in Code node
   const postText = $json.postText;
   if (postText.length > 3000) {
     // Truncate or re-summarize
     const truncated = postText.substring(0, 2997) + "...";
     return { json: { ...$json, postText: truncated } };
   }
   ```

2. **Adjust Summary Length**:
   - Reduce `max_words` in prompts.json
   - Use shorter hashtags
   - Remove unnecessary formatting

### 2. OpenAI API Issues

#### Issue: "Rate limit exceeded"

**Symptoms**:
- 429 errors from OpenAI
- "Too many requests" messages

**Solutions**:

1. **Implement Retry Logic**:
   ```javascript
   // Add retry mechanism in Code node
   const maxRetries = 3;
   let attempt = 0;
   
   while (attempt < maxRetries) {
     try {
       // OpenAI call here
       break;
     } catch (error) {
       if (error.status === 429) {
         attempt++;
         await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
       } else {
         throw error;
       }
     }
   }
   ```

2. **Check Usage Limits**:
   - Visit OpenAI dashboard
   - Check current usage vs. limits
   - Upgrade plan if needed

3. **Optimize Requests**:
   - Reduce `max_tokens` parameter
   - Use GPT-3.5-turbo instead of GPT-4
   - Batch requests when possible

#### Issue: "Invalid API key"

**Symptoms**:
- 401 errors from OpenAI
- "Invalid authentication" messages

**Solutions**:

1. **Verify API Key**:
   ```bash
   # Test API key
   curl -X POST "https://api.openai.com/v1/chat/completions" \
     -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"test"}]}'
   ```

2. **Check Environment Variables**:
   ```bash
   # Verify .env file
   cat .env | grep OPENAI_API_KEY
   
   # Check if loaded in n8n
   echo $OPENAI_API_KEY
   ```

3. **Regenerate API Key**:
   - Go to OpenAI Platform
   - Create new API key
   - Update in n8n credentials

#### Issue: "Malformed JSON response"

**Symptoms**:
- Parsing errors in Code nodes
- "Unexpected token" errors

**Solutions**:

1. **Improve Prompt Engineering**:
   ```javascript
   // More explicit prompt
   const prompt = `Return ONLY valid JSON in this exact format:
   {
     "summary": "Your summary here",
     "hashtags": "#Tag1 #Tag2 #Tag3"
   }
   
   Article: ${article}`;
   ```

2. **Add Error Handling**:
   ```javascript
   // Robust JSON parsing
   try {
     const parsed = JSON.parse(response);
     return parsed;
   } catch (error) {
     // Fallback parsing
     const summary = response.match(/summary["\s]*:["\s]*"([^"]+)"/i)?.[1] || response;
     const hashtags = response.match(/#\w+/g)?.join(' ') || '#News';
     return { summary, hashtags };
   }
   ```

### 3. RSS Feed Issues

#### Issue: "Feed not accessible"

**Symptoms**:
- RSS nodes fail
- "Connection refused" errors

**Solutions**:

1. **Test Feed URLs**:
   ```bash
   # Test individual feeds
   curl -I https://techcrunch.com/feed/
   curl -I https://www.vox.com/rss/index.xml
   ```

2. **Update Feed URLs**:
   - Some feeds change URLs
   - Check official websites for new RSS URLs
   - Update config/news-sources.json

3. **Add Error Handling**:
   ```javascript
   // In Code node, handle RSS failures
   const validFeeds = $input.all().filter(item => {
     return item.json && item.json.title; // Basic validation
   });
   ```

#### Issue: "Malformed RSS"

**Symptoms**:
- Parsing errors
- Missing article data

**Solutions**:

1. **Validate RSS Format**:
   ```bash
   # Check RSS structure
   curl -s https://feed-url.com | xmllint --format -
   ```

2. **Add Data Validation**:
   ```javascript
   // Validate required fields
   const validArticles = articles.filter(article => {
     return article.title && article.link && article.description;
   });
   ```

### 4. n8n Workflow Issues

#### Issue: "Workflow not triggering"

**Symptoms**:
- Cron trigger not firing
- Manual execution works

**Solutions**:

1. **Check Cron Expression**:
   ```bash
   # Verify cron syntax
   # Current: "0 8 * * *" (daily at 8 AM)
   # Test: https://crontab.guru/
   ```

2. **Check n8n Status**:
   ```bash
   # Verify n8n is running
   ps aux | grep n8n
   
   # Check logs
   n8n logs
   ```

3. **Activate Workflow**:
   - In n8n, ensure workflow is activated
   - Check execution settings
   - Verify trigger node is enabled

#### Issue: "Data Store errors"

**Symptoms**:
- Duplicate checking fails
- Storage errors

**Solutions**:

1. **Check Data Store**:
   ```bash
   # In n8n, go to Data Store
   # Verify entries are being created
   # Clear if corrupted
   ```

2. **Add Error Handling**:
   ```javascript
   // Wrap Data Store operations
   try {
     // Data Store operation
   } catch (error) {
     console.log('Data Store error:', error);
     // Continue without deduplication
   }
   ```

### 5. Performance Issues

#### Issue: "Workflow takes too long"

**Symptoms**:
- Timeouts
- Slow execution

**Solutions**:

1. **Optimize RSS Feeds**:
   - Reduce number of feeds
   - Filter articles earlier
   - Use priority-based selection

2. **Optimize OpenAI Calls**:
   - Use GPT-3.5-turbo for speed
   - Reduce max_tokens
   - Implement caching

3. **Parallel Processing**:
   ```javascript
   // Process feeds in parallel
   const promises = feeds.map(feed => processFeed(feed));
   const results = await Promise.all(promises);
   ```

#### Issue: "High API costs"

**Symptoms**:
- Expensive OpenAI bills
- Rate limit issues

**Solutions**:

1. **Optimize Prompts**:
   - Shorter, more focused prompts
   - Lower temperature settings
   - Use cheaper models when possible

2. **Implement Caching**:
   ```javascript
   // Cache similar articles
   const cacheKey = hash(article.title + article.content);
   const cached = await getFromCache(cacheKey);
   if (cached) return cached;
   ```

3. **Limit Processing**:
   - Reduce max_articles_per_run
   - Process only high-priority feeds
   - Skip older articles

## Debugging Tools

### 1. Enable Debug Logging

```bash
# Set debug level
export N8N_LOG_LEVEL=debug
n8n start
```

### 2. Test Individual Nodes

```javascript
// Add debug output in Code nodes
console.log('Input data:', JSON.stringify($input.all(), null, 2));
console.log('Node output:', JSON.stringify($json, null, 2));
```

### 3. Monitor API Usage

```bash
# Check OpenAI usage
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.openai.com/v1/usage

# Check LinkedIn app analytics
# Visit LinkedIn Developer Console
```

## Getting Help

### 1. Check Documentation

- [n8n Documentation](https://docs.n8n.io/)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [LinkedIn API Documentation](https://developer.linkedin.com/docs)

### 2. Community Resources

- [n8n Community](https://community.n8n.io/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/n8n)
- [GitHub Issues](https://github.com/n8n-io/n8n/issues)

### 3. Create Debug Report

```bash
# Generate debug info
echo "=== Debug Report ===" > debug-report.txt
echo "Date: $(date)" >> debug-report.txt
echo "n8n Version: $(n8n --version)" >> debug-report.txt
echo "Node Version: $(node --version)" >> debug-report.txt
echo "OS: $(uname -a)" >> debug-report.txt
echo "=== Environment ===" >> debug-report.txt
env | grep -E "(OPENAI|LINKEDIN|N8N)" >> debug-report.txt
echo "=== Logs ===" >> debug-report.txt
tail -n 50 logs/workflow.log >> debug-report.txt
```

## Prevention Tips

1. **Regular Monitoring**:
   - Check workflow execution daily
   - Monitor API usage weekly
   - Review error logs monthly

2. **Backup Configuration**:
   ```bash
   # Backup config files
   tar -czf config-backup-$(date +%Y%m%d).tar.gz config/
   ```

3. **Test Changes**:
   - Test in development environment first
   - Use staging feeds for testing
   - Validate changes before production

---

**Still having issues?** Create a detailed issue report with:
- Error messages
- Steps to reproduce
- Environment details
- Debug report output
