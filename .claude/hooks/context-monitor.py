#!/usr/bin/env python3
"""
Context Usage Monitor Hook

Monitors context usage and provides progressive warnings:
- At 40%, 55%, 65%: Suggest /learn for skill extraction
- At 80%: Info-level warning (auto-compact approaching)
- At 90%: Caution-level warning (complete current task with full quality)

Hook Event: PostToolUse (on common tools)
Throttles to 60-second intervals when below warning threshold.

Note: Since direct context % isn't available, this uses a heuristic based on
conversation file size and tool call count.
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime

# Colors for terminal output
CYAN = "\033[0;36m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
RED = "\033[0;31m"
MAGENTA = "\033[0;35m"
NC = "\033[0m"  # No color

# Thresholds (effective percentage, where 100% = auto-compact)
LEARN_THRESHOLDS = [40, 55, 65]
THRESHOLD_WARN = 80
THRESHOLD_CRITICAL = 90

# Throttle interval in seconds (skip checks if below threshold and recent check)
THROTTLE_INTERVAL = 60


def get_cache_file(session_id: str = "") -> Path:
    """Get the per-session cache file path."""
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    import hashlib
    if project_dir:
        project_hash = hashlib.md5(project_dir.encode()).hexdigest()[:8]
    else:
        project_hash = "default"
    session_dir = Path.home() / ".claude" / "sessions" / project_hash
    session_dir.mkdir(parents=True, exist_ok=True)
    # Use session_id suffix so each session has its own counter.
    # Falls back to the shared file only when no session_id is available.
    suffix = f"-{session_id[:16]}" if session_id else ""
    return session_dir / f"context-monitor-cache{suffix}.json"


def read_cache(session_id: str = "") -> dict:
    """Read the context monitor cache."""
    cache_file = get_cache_file(session_id)
    if not cache_file.exists():
        return {}
    try:
        return json.loads(cache_file.read_text())
    except (json.JSONDecodeError, IOError):
        return {}


def save_cache(data: dict, session_id: str = "") -> None:
    """Save the context monitor cache."""
    cache_file = get_cache_file(session_id)
    try:
        cache_file.write_text(json.dumps(data, indent=2))
    except IOError:
        pass


def estimate_context_percentage(session_id: str = "") -> float:
    """
    Estimate context usage as a percentage.

    Uses per-session tool call count as a proxy. Resets automatically
    for each new session_id, preventing cross-session contamination.

    Returns a value from 0-100 representing estimated context usage.
    """
    cache = read_cache(session_id)

    # Increment tool call counter
    tool_calls = cache.get("tool_calls", 0) + 1
    cache["tool_calls"] = tool_calls
    save_cache(cache, session_id)

    # Heuristic: assume ~200 tool calls fills context (very rough estimate)
    MAX_TOOL_CALLS = 200

    percentage = min((tool_calls / MAX_TOOL_CALLS) * 100, 100)
    return percentage


def is_throttled(percentage: float, session_id: str = "") -> bool:
    """Check if we should skip this check due to throttling."""
    cache = read_cache(session_id)
    last_check = cache.get("last_check_time", 0)
    now = time.time()

    # If below warning threshold and checked recently, skip
    if percentage < THRESHOLD_WARN and (now - last_check) < THROTTLE_INTERVAL:
        return True

    # Update last check time
    cache["last_check_time"] = now
    save_cache(cache, session_id)
    return False


def get_shown_thresholds(session_id: str = "") -> dict:
    """Get which thresholds have already been shown in this session."""
    cache = read_cache(session_id)
    return {
        "learn": cache.get("shown_learn", []),
        "warn_80": cache.get("shown_warn_80", False),
        "warn_90": cache.get("shown_warn_90", False)
    }


def mark_threshold_shown(threshold_type: str, value: int | bool = True, session_id: str = "") -> None:
    """Mark a threshold as shown."""
    cache = read_cache(session_id)
    if threshold_type == "learn":
        shown = cache.get("shown_learn", [])
        if value not in shown:
            shown.append(value)
        cache["shown_learn"] = shown
    else:
        cache[f"shown_{threshold_type}"] = value
    save_cache(cache, session_id)


def format_learn_reminder(percentage: float, threshold: int) -> str:
    """Format a /learn skill reminder."""
    return f"""
{CYAN}💡 Context at {percentage:.0f}%{NC}

Non-obvious discovery or reusable workflow?
→ Consider using {GREEN}/learn{NC} to capture it as a skill before context compacts.

Skills are saved to {MAGENTA}.claude/skills/{NC} and persist across sessions.
"""


def format_warn_80(percentage: float) -> str:
    """Format the 80% warning message."""
    return f"""
{YELLOW}💡 Context at {percentage:.0f}%{NC}

Auto-compact will handle context management automatically.
No rush — just be aware that context will be summarized soon.
"""


def format_warn_90(percentage: float) -> str:
    """Format the 90% critical warning message."""
    return f"""
{RED}⚠️  Context at {percentage:.0f}% — auto-compact approaching{NC}

Complete current task with full quality. Do NOT cut corners or skip verification.
No context is lost — auto-compact preserves important information.

{YELLOW}Actions to consider:{NC}
  • Save key decisions to the session log
  • Ensure current plan status is updated
  • Mark completed todos as done
"""


def run_context_monitor() -> int:
    """Main monitoring logic."""
    # Read hook input
    try:
        hook_input = json.load(sys.stdin)
    except (json.JSONDecodeError, IOError):
        hook_input = {}

    session_id = hook_input.get("session_id", "")

    # Estimate current context usage
    percentage = estimate_context_percentage(session_id)

    # Check throttling
    if is_throttled(percentage, session_id):
        return 0

    shown = get_shown_thresholds(session_id)

    # Check /learn thresholds (40%, 55%, 65%)
    for threshold in LEARN_THRESHOLDS:
        if percentage >= threshold and threshold not in shown["learn"]:
            print(format_learn_reminder(percentage, threshold))
            mark_threshold_shown("learn", threshold, session_id)
            return 0  # Only show one message at a time

    # Check 90% threshold (critical)
    if percentage >= THRESHOLD_CRITICAL and not shown["warn_90"]:
        print(format_warn_90(percentage))
        mark_threshold_shown("warn_90", True, session_id)
        return 0  # Non-blocking warning (exit 2 would block Claude)

    # Check 80% threshold (info)
    if percentage >= THRESHOLD_WARN and not shown["warn_80"]:
        print(format_warn_80(percentage))
        mark_threshold_shown("warn_80", True, session_id)
        return 0

    return 0


def main() -> int:
    """Main entry point."""
    return run_context_monitor()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        # Fail open — never block Claude due to a hook bug
        sys.exit(0)
