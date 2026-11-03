# Setup guide

Detailed version of the five steps in the README.

## 1. Local environment

```bash
./scripts/setup.sh          # creates .env (DRY_RUN=true, random N8N_ENCRYPTION_KEY), validates JSON
docker compose up -d        # n8n on http://localhost:5678
```

Open n8n and create the owner account. Keep `N8N_ENCRYPTION_KEY` unchanged afterwards: n8n uses it to
decrypt stored credentials.

## 2. OpenAI credential

1. Create an API key at <https://platform.openai.com/api-keys>.
2. In n8n: *Credentials, Add credential, OpenAI*. Name it `OpenAI account` and paste the key.
3. Optional pre-flight check (key is read from the environment and not stored):
   `OPENAI_API_KEY=... ./scripts/test-workflow.sh`

The model defaults to `gpt-4o-mini`; set `OPENAI_MODEL` in `.env` to change it.

## 3. LinkedIn credential (official API only)

Posting uses LinkedIn's official API through n8n's LinkedIn node and an OAuth app you own.

1. Create an app at <https://www.linkedin.com/developers/apps>.
2. Under *Products*, add **Share on LinkedIn** (scope `w_member_social`) and
   **Sign In with LinkedIn using OpenID Connect**.
3. In n8n: *Credentials, Add credential, LinkedIn OAuth2 API*. Name it `LinkedIn account`, copy the
   *OAuth Redirect URL* that n8n shows into the app's *Auth* tab, paste the app's Client ID and Client
   Secret, then click *Connect* and approve.
4. Read and follow LinkedIn's API Terms of Use and the Share on LinkedIn usage rules. Automated posting
   must stay within what your app is approved for, and you remain responsible for what gets published.

## 4. Import

```bash
docker compose exec n8n n8n import:workflow --separate --input=/workflows
```

Then, in the n8n editor:

- `AI News Summarizer + LinkedIn Publisher`: select `OpenAI account` on *Summarize with OpenAI* and
  `LinkedIn account` on *Post to LinkedIn*, and pick your profile in the node's *Person* field.
- Workflow *Settings, Error workflow*: choose `Error Notifier (Webhook)`.
- Optional: set `ALERT_WEBHOOK_URL` in `.env` to a Slack or Discord incoming webhook and run
  `docker compose up -d` again so n8n picks it up.

## 5. Dry run, then go live

1. With `DRY_RUN=true`, click *Execute workflow*. The *Dry Run Log* node shows the exact post text and
   character count. Nothing is published and nothing is marked as posted.
2. When the output looks right, set `DRY_RUN=false` in `.env`, run `docker compose up -d`, and
   activate the workflow. It runs daily at 08:00 (`GENERIC_TIMEZONE`) and publishes at most
   `MAX_POSTS_PER_RUN` posts.

## Changing feeds, keywords or the prompt

The workflow embeds the enabled feeds and keywords from `config/news-sources.json` and the system prompt
from `config/prompts.json`. After editing either config file, make the same change in the *Feed List*,
*Filter and Dedup* or *Summarize with OpenAI* node and re-export; `pytest` fails while they differ.
`config/linkedin-templates.json` is reference material for post formats; the workflow uses the
`standard` layout (title, summary, source link, hashtags).
