"""Keep the workflow JSON consistent with config/ and with its safety settings."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = json.loads((ROOT / "workflows" / "ai-news-summarizer-production.json").read_text())
NODES = {node["name"]: node for node in WORKFLOW["nodes"]}
SOURCES = json.loads((ROOT / "config" / "news-sources.json").read_text())
PROMPTS = json.loads((ROOT / "config" / "prompts.json").read_text())


def test_feed_list_matches_enabled_sources() -> None:
    code = NODES["Feed List"]["parameters"]["jsCode"]
    in_workflow = set(re.findall(r'"url": "([^"]+)"', code))
    enabled = {s["url"] for s in SOURCES["sources"] if s["enabled"]}
    assert in_workflow == enabled


def test_keywords_match_config() -> None:
    code = NODES["Filter and Dedup"]["parameters"]["jsCode"]
    assert json.dumps(SOURCES["settings"]["keywords_filter"]) in code
    assert json.dumps(SOURCES["settings"]["exclude_keywords"]) in code


def test_system_prompt_matches_config() -> None:
    body = NODES["Summarize with OpenAI"]["parameters"]["jsonBody"]
    assert json.dumps(PROMPTS["summarization"]["system"]) in body


def test_llm_call_has_retry_and_timeout() -> None:
    node = NODES["Summarize with OpenAI"]
    assert node["retryOnFail"] is True and node["maxTries"] >= 2
    assert node["parameters"]["options"]["timeout"] <= 120_000


def test_linkedin_post_is_not_retried() -> None:
    # A retry after a timed-out but successful request would publish a duplicate post.
    assert not NODES["Post to LinkedIn"].get("retryOnFail", False)


def test_dry_run_is_the_default() -> None:
    env = (ROOT / ".env.example").read_text()
    assert re.search(r"^DRY_RUN=true$", env, re.MULTILINE)
    condition = NODES["Dry Run?"]["parameters"]["conditions"]["conditions"][0]
    assert "?? 'true'" in condition["leftValue"]  # unset DRY_RUN also means dry run
    # output 0 (dry run) -> log, output 1 -> LinkedIn
    branches = WORKFLOW["connections"]["Dry Run?"]["main"]
    assert branches[0][0]["node"] == "Dry Run Log"
    assert branches[1][0]["node"] == "Post to LinkedIn"
