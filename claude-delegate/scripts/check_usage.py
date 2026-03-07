#!/usr/bin/env python3
import argparse
import glob
import json
import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone


RATE_LIMIT_MARKERS = (
    "would exceed your account's rate limit",
    "rate_limit_error",
    "out of quota",
    "out of tokens",
    "usage limit",
)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Check whether Claude delegation should proceed."
    )
    parser.add_argument(
        "--telemetry-dir",
        default=os.path.expanduser("~/.claude/telemetry"),
        help="Claude telemetry directory",
    )
    parser.add_argument(
        "--claude-bin",
        default="claude",
        help="Claude CLI executable",
    )
    parser.add_argument(
        "--probe",
        dest="probe",
        action="store_true",
        help="Run a tiny Claude probe request",
    )
    parser.add_argument(
        "--no-probe",
        dest="probe",
        action="store_false",
        help="Do not run a Claude probe request",
    )
    parser.set_defaults(probe=True)
    parser.add_argument(
        "--probe-model",
        default="sonnet",
        help="Model alias for the probe request",
    )
    parser.add_argument(
        "--probe-timeout",
        type=int,
        default=30,
        help="Probe timeout in seconds",
    )
    parser.add_argument(
        "--stale-after-minutes",
        type=int,
        default=300,
        help="Treat telemetry state as stale after this many minutes",
    )
    return parser.parse_args()


def parse_timestamp(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def contains_rate_limit(text):
    lowered = text.lower()
    return any(marker in lowered for marker in RATE_LIMIT_MARKERS)


def load_json_lines(path):
    with open(path, "r", errors="ignore") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                value = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(value, dict):
                yield value


def parse_additional_metadata(value):
    if not value:
        return {}
    if isinstance(value, dict):
        return value
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return {}


def read_telemetry(telemetry_dir):
    latest_limits = None
    latest_rate_limit_error = None

    for path in glob.glob(os.path.join(telemetry_dir, "*.json")):
        for entry in load_json_lines(path):
            event_data = entry.get("event_data", {})
            event_name = event_data.get("event_name")
            timestamp = parse_timestamp(event_data.get("client_timestamp"))
            metadata = parse_additional_metadata(event_data.get("additional_metadata"))

            if event_name == "tengu_claudeai_limits_status_changed":
                row = {
                    "timestamp": event_data.get("client_timestamp"),
                    "parsed_timestamp": timestamp,
                    "status": metadata.get("status"),
                    "hours_till_reset": metadata.get("hoursTillReset"),
                    "fallback_available": metadata.get(
                        "unifiedRateLimitFallbackAvailable"
                    ),
                    "source": path,
                }
                latest_limits_timestamp = (
                    latest_limits["parsed_timestamp"] if latest_limits else None
                )
                if latest_limits is None or (
                    timestamp and (
                        latest_limits_timestamp is None
                        or timestamp > latest_limits_timestamp
                    )
                ):
                    latest_limits = row

            if event_name == "tengu_api_error":
                error_text = json.dumps(metadata, ensure_ascii=True)
                if contains_rate_limit(error_text):
                    row = {
                        "timestamp": event_data.get("client_timestamp"),
                        "parsed_timestamp": timestamp,
                        "source": path,
                        "error": metadata.get("error"),
                        "status_code": metadata.get("status"),
                    }
                    latest_error_timestamp = (
                        latest_rate_limit_error["parsed_timestamp"]
                        if latest_rate_limit_error
                        else None
                    )
                    if latest_rate_limit_error is None or (
                        timestamp
                        and (
                            latest_error_timestamp is None
                            or timestamp > latest_error_timestamp
                        )
                    ):
                        latest_rate_limit_error = row

    return latest_limits, latest_rate_limit_error


def run_probe(claude_bin, model, timeout_seconds):
    cmd = [
        claude_bin,
        "-p",
        "--no-session-persistence",
        "--model",
        model,
        "Reply with exactly: OK",
    ]
    try:
        completed = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
            check=False,
        )
    except FileNotFoundError:
        return {
            "state": "error",
            "reason": "claude_not_found",
            "stdout": "",
            "stderr": "",
            "returncode": 127,
        }
    except subprocess.TimeoutExpired:
        return {
            "state": "error",
            "reason": "timeout",
            "stdout": "",
            "stderr": "",
            "returncode": 124,
        }

    stdout = (completed.stdout or "").strip()
    stderr = (completed.stderr or "").strip()
    combined = "\n".join(part for part in (stdout, stderr) if part)

    if completed.returncode == 0 and stdout == "OK":
        return {
            "state": "ok",
            "reason": "probe_ok",
            "stdout": stdout,
            "stderr": stderr,
            "returncode": completed.returncode,
        }

    if contains_rate_limit(combined):
        return {
            "state": "rate_limited",
            "reason": "probe_rate_limited",
            "stdout": stdout,
            "stderr": stderr,
            "returncode": completed.returncode,
        }

    return {
        "state": "error",
        "reason": "probe_failed",
        "stdout": stdout,
        "stderr": stderr,
        "returncode": completed.returncode,
    }


def is_fresh(timestamp, stale_after_minutes):
    if timestamp is None:
        return False
    now = datetime.now(timezone.utc)
    return now - timestamp <= timedelta(minutes=stale_after_minutes)


def decide(probe_result, latest_limits, latest_rate_limit_error, stale_after_minutes):
    if probe_result and probe_result["state"] == "rate_limited":
        return "skip", "probe_rate_limited"

    if probe_result and probe_result["state"] == "ok":
        if latest_limits and latest_limits.get("status") == "allowed_warning":
            if is_fresh(latest_limits["parsed_timestamp"], stale_after_minutes):
                return "confirm", "fresh_allowed_warning"
        return "delegate", "probe_ok"

    if latest_rate_limit_error and is_fresh(
        latest_rate_limit_error["parsed_timestamp"], stale_after_minutes
    ):
        return "skip", "recent_rate_limit_error"

    if latest_limits and is_fresh(latest_limits["parsed_timestamp"], stale_after_minutes):
        status = latest_limits.get("status")
        if status == "allowed":
            return "delegate", "fresh_allowed"
        if status == "allowed_warning":
            return "confirm", "fresh_allowed_warning"
        if status == "rejected":
            return "skip", "fresh_rejected"

    return "confirm", "insufficient_signal"


def main():
    args = parse_args()
    latest_limits, latest_rate_limit_error = read_telemetry(args.telemetry_dir)
    probe_result = None
    if args.probe:
        probe_result = run_probe(args.claude_bin, args.probe_model, args.probe_timeout)

    decision, reason = decide(
        probe_result, latest_limits, latest_rate_limit_error, args.stale_after_minutes
    )

    payload = {
        "decision": decision,
        "reason": reason,
        "probe": probe_result,
        "telemetry": {
            "latest_limits": {
                "timestamp": latest_limits["timestamp"],
                "status": latest_limits["status"],
                "hours_till_reset": latest_limits["hours_till_reset"],
                "fallback_available": latest_limits["fallback_available"],
                "source": latest_limits["source"],
            }
            if latest_limits
            else None,
            "latest_rate_limit_error": {
                "timestamp": latest_rate_limit_error["timestamp"],
                "status_code": latest_rate_limit_error["status_code"],
                "error": latest_rate_limit_error["error"],
                "source": latest_rate_limit_error["source"],
            }
            if latest_rate_limit_error
            else None,
        },
    }

    print(json.dumps(payload, ensure_ascii=True, indent=2))

    if decision == "delegate":
        return 0
    if decision == "confirm":
        return 10
    if decision == "skip":
        return 20
    return 30


if __name__ == "__main__":
    sys.exit(main())
