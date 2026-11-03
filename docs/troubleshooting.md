# Troubleshooting

Start with the n8n *Executions* list: the failed node is highlighted and its error is shown. If the error
workflow is linked, the same summary goes to `ALERT_WEBHOOK_URL`.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `access to env vars denied` | n8n 2.x blocks `$env` by default | Set `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` in `.env`, then `docker compose up -d` |
| Workflow runs but posts nothing | No article passed the filters, or all were already posted | Check *Filter and Dedup* output; widen `MAX_ARTICLE_AGE_HOURS` or the keywords |
| Posts only appear in *Dry Run Log* | `DRY_RUN` is not exactly `false` | Set `DRY_RUN=false` and restart the container |
| Same article posted again after a manual run | Static data is saved only for production (active, trigger-started) executions | Let the active schedule do the posting; manual runs are for testing |
| One feed fails | Feed down, blocked or rate limited | It is retried 3 times and then skipped; run `./scripts/test-workflow.sh`, disable it in config and in *Feed List* |
| 401 from *Summarize with OpenAI* | Wrong or revoked API key | Update the `OpenAI account` credential |
| 429 from *Summarize with OpenAI* | Rate limit or quota | The node retries 3 times, 5 s apart; check usage and limits in the OpenAI dashboard |
| Article skipped with "model did not return a valid summary" | The model answered with invalid JSON | It is skipped on purpose and tried again next run |
| 401/403 from *Post to LinkedIn* | Token expired or the app lacks `w_member_social` | Reconnect the `LinkedIn account` credential; check the app's products |
| Duplicate LinkedIn posts | Should not happen: the node is not retried and links are recorded after success | Check whether the workflow was imported twice and both copies are active |
| Credentials unreadable after a restart | `N8N_ENCRYPTION_KEY` changed | Restore the original key |

Debugging tips:

- `docker compose logs -f n8n` shows `console.log` output from Code nodes.
- Never paste `.env`, credential exports or full error payloads into public issues; they can contain
  tokens. The error workflow redacts common token formats, but review before sharing.
