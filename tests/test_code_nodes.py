"""Run the workflow's Code-node JavaScript under Node.js with a tiny n8n stand-in.

Skipped when `node` is not installed. Exercises the logic that decides what gets
published: filtering, de-duplication, post formatting and the dry-run bookkeeping.
"""
from __future__ import annotations

import json
import shutil
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "workflows" / "ai-news-summarizer-production.json"
NOTIFIER = ROOT / "workflows" / "error-notifier.json"
HARNESS = Path(__file__).parent / "js" / "run_code_node.js"

pytestmark = pytest.mark.skipif(shutil.which("node") is None, reason="Node.js not installed")


def run_node(workflow: Path, node: str, items: list, env: dict | None = None,
             static: dict | None = None, outputs: dict | None = None) -> dict:
    request = {"workflow": str(workflow), "node": node, "items": items, "env": env or {},
               "staticData": static or {}, "nodeOutputs": outputs or {}}
    proc = subprocess.run(["node", str(HARNESS)], input=json.dumps(request), capture_output=True,
                          text=True, check=True, timeout=30)
    # Code nodes may console.log; the result is the last line.
    return json.loads(proc.stdout.strip().splitlines()[-1])


def hours_ago(hours: float) -> str:
    return (datetime.now(timezone.utc) - timedelta(hours=hours)).isoformat()


@pytest.fixture(scope="module")
def feeds() -> list:
    return run_node(MAIN, "Feed List", [])["output"]


def rss_items() -> list:
    return [
        {"json": {"title": "New AI startup raises a round", "link": "https://techcrunch.com/a?utm_source=rss",
                  "isoDate": hours_ago(3), "contentSnippet": "machine learning"}},
        {"json": {"title": "Duplicate of the first", "link": "https://techcrunch.com/a",
                  "isoDate": hours_ago(3), "contentSnippet": "AI"}},
        {"json": {"title": "He said hello", "link": "https://www.vox.com/b", "isoDate": hours_ago(3)}},
        {"json": {"title": "Sponsored AI tool", "link": "https://www.vox.com/c", "isoDate": hours_ago(3)}},
        {"json": {"title": "Old AI news", "link": "https://www.vox.com/d", "isoDate": hours_ago(200)}},
        {"json": {"error": {"message": "feed unreachable"}}},
        {"json": {"title": "Innovation at a lab", "link": "https://arstechnica.com/e",
                  "isoDate": hours_ago(5), "content": "<p>technology</p>"}},
    ]


def test_filter_dedup_selects_relevant_fresh_unique_articles(feeds: list) -> None:
    result = run_node(MAIN, "Filter and Dedup", rss_items(), env={"MAX_POSTS_PER_RUN": "5"},
                      outputs={"Feed List": feeds})
    links = [item["json"]["link"] for item in result["output"]]
    # tracking params stripped and duplicate merged; "said" is not "AI"; sponsored, old, error dropped
    assert links == ["https://techcrunch.com/a", "https://arstechnica.com/e"]
    assert result["output"][0]["json"]["source"] == "TechCrunch"


def test_filter_respects_post_limit_and_history(feeds: list) -> None:
    limited = run_node(MAIN, "Filter and Dedup", rss_items(), outputs={"Feed List": feeds})
    assert len(limited["output"]) == 1  # MAX_POSTS_PER_RUN defaults to 1
    seen = run_node(MAIN, "Filter and Dedup", rss_items(), env={"MAX_POSTS_PER_RUN": "5"},
                    static={"postedLinks": ["https://techcrunch.com/a"]}, outputs={"Feed List": feeds})
    assert [i["json"]["link"] for i in seen["output"]] == ["https://arstechnica.com/e"]


def article(**overrides) -> dict:
    base = {"title": "Title", "link": "https://example.com/x", "description": "d",
            "publishedAt": hours_ago(1), "source": "Example"}
    return {"json": {**base, **overrides}}


def llm(content: str) -> dict:
    return {"json": {"choices": [{"message": {"content": content}}]}}


def test_format_post_enforces_limit_and_skips_invalid_model_output() -> None:
    good = json.dumps({"summary": "S" * 5000, "hashtags": "#AI #Start-ups, #News #Extra"})
    result = run_node(MAIN, "Format LinkedIn Post", [llm(good), llm("not json")],
                      env={"LINKEDIN_CHAR_LIMIT": "1300"},
                      outputs={"Filter and Dedup": [article(), article(link="https://example.com/y")]})
    assert len(result["output"]) == 1
    post = result["output"][0]["json"]
    assert post["characterCount"] <= 1300
    assert post["postText"].endswith("#AI #Startups #News")
    assert "Source: https://example.com/x" in post["postText"]


def test_record_posted_updates_history_once_per_post() -> None:
    formatted = [{"json": {"title": "T", "link": "https://example.com/x", "characterCount": 10}}]
    result = run_node(MAIN, "Record Posted", [{"json": {"urn": "urn:li:share:1"}}],
                      static={"postedLinks": ["https://example.com/x"]},
                      outputs={"Format LinkedIn Post": formatted})
    assert result["staticData"]["postedLinks"] == ["https://example.com/x"]
    assert result["staticData"]["recentPosts"][0]["postId"] == "urn:li:share:1"


def test_dry_run_log_does_not_touch_history() -> None:
    result = run_node(MAIN, "Dry Run Log", [article(postText="p", characterCount=1)])
    assert result["output"][0]["json"]["dryRun"] is True
    assert result["staticData"] == {}


def test_error_alert_redacts_secrets_and_is_optional() -> None:
    fake_key = "sk-" + "a1" * 12  # built at runtime: no secret-shaped literal in the repo
    event = {"json": {"workflow": {"name": "Main"},
                      "execution": {"lastNodeExecuted": "Summarize with OpenAI",
                                    "error": {"message": f"401 Incorrect API key {fake_key}"}}}}
    sent = run_node(NOTIFIER, "Build Alert", [event], env={"ALERT_WEBHOOK_URL": "https://hooks.example.com/x"})
    text = sent["output"][0]["json"]["payload"]["text"]
    assert fake_key not in text and "sk-***" in text and "Summarize with OpenAI" in text
    assert run_node(NOTIFIER, "Build Alert", [event])["output"] == []
