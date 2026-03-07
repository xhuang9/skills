#!/usr/bin/env python3
import argparse
import glob
import json
import os
import statistics
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone


DEFAULT_WINDOWS = (1, 3, 5, 24)
WEIGHTS = {
    "input": 1.0,
    "output": 1.0,
    "cache_create": 0.25,
    "cache_read": 0.01,
}


def parse_args():
    parser = argparse.ArgumentParser(
        description="Estimate Claude usage pressure from local session history."
    )
    parser.add_argument(
        "--projects-dir",
        default=os.path.expanduser("~/.claude/projects"),
        help="Claude projects directory",
    )
    parser.add_argument(
        "--telemetry-dir",
        default=os.path.expanduser("~/.claude/telemetry"),
        help="Claude telemetry directory",
    )
    parser.add_argument(
        "--windows",
        default="1,3,5,24",
        help="Comma-separated hour windows",
    )
    parser.add_argument(
        "--fresh-status-hours",
        type=int,
        default=5,
        help="Treat a telemetry limit status as fresh for this many hours",
    )
    return parser.parse_args()


def parse_timestamp(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


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


def parse_windows(raw):
    values = []
    for chunk in raw.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        values.append(int(chunk))
    unique = sorted(set(values))
    if not unique:
        raise ValueError("No windows provided")
    return unique


def parse_additional_metadata(value):
    if not value:
        return {}
    if isinstance(value, dict):
        return value
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return {}


def choose_latest(prev, candidate):
    if prev is None:
        return candidate
    prev_ts = prev["ts"]
    cand_ts = candidate["ts"]
    if cand_ts and prev_ts:
        if cand_ts > prev_ts:
            return candidate
        if cand_ts < prev_ts:
            return prev
    elif cand_ts and not prev_ts:
        return candidate
    elif prev_ts and not cand_ts:
        return prev

    prev_tuple = (prev["output"], prev["cache_create"], prev["cache_read"])
    cand_tuple = (
        candidate["output"],
        candidate["cache_create"],
        candidate["cache_read"],
    )
    return candidate if cand_tuple >= prev_tuple else prev


def load_messages(projects_dir):
    deduped = {}
    for path in glob.glob(os.path.join(projects_dir, "*", "*.jsonl")):
        for entry in load_json_lines(path):
            message = entry.get("message")
            if not isinstance(message, dict):
                continue
            usage = message.get("usage")
            message_id = message.get("id")
            if not (isinstance(usage, dict) and message_id):
                continue
            row = {
                "ts": parse_timestamp(entry.get("timestamp")),
                "path": path,
                "session_id": entry.get("sessionId"),
                "message_id": message_id,
                "input": usage.get("input_tokens") or 0,
                "output": usage.get("output_tokens") or 0,
                "cache_create": usage.get("cache_creation_input_tokens") or 0,
                "cache_read": usage.get("cache_read_input_tokens") or 0,
                "service_tier": usage.get("service_tier"),
            }
            key = (path, message_id)
            deduped[key] = choose_latest(deduped.get(key), row)
    return list(deduped.values())


def load_limit_events(telemetry_dir):
    rows = []
    for path in glob.glob(os.path.join(telemetry_dir, "*.json")):
        for entry in load_json_lines(path):
            event_data = entry.get("event_data", {})
            if event_data.get("event_name") != "tengu_claudeai_limits_status_changed":
                continue
            metadata = parse_additional_metadata(event_data.get("additional_metadata"))
            status = metadata.get("status")
            timestamp = parse_timestamp(event_data.get("client_timestamp"))
            if status not in {"allowed", "allowed_warning", "rejected"} or not timestamp:
                continue
            rows.append(
                {
                    "status": status,
                    "ts": timestamp,
                    "timestamp": event_data.get("client_timestamp"),
                    "hours_till_reset": metadata.get("hoursTillReset"),
                    "source": path,
                }
            )
    rows.sort(key=lambda row: row["ts"])
    return rows


def aggregate_rows(rows, start, end):
    totals = {
        "input": 0,
        "output": 0,
        "cache_create": 0,
        "cache_read": 0,
    }
    count = 0
    for row in rows:
        ts = row["ts"]
        if ts is None or ts < start or ts > end:
            continue
        count += 1
        for key in totals:
            totals[key] += row[key]
    weighted = sum(totals[key] * WEIGHTS[key] for key in totals)
    totals["weighted_total"] = round(weighted, 2)
    totals["message_count"] = count
    return totals


def build_current_windows(rows, now, windows):
    result = {}
    for hours in windows:
        start = now - timedelta(hours=hours)
        result[f"{hours}h"] = aggregate_rows(rows, start, now)
    return result


def build_historical_windows(rows, events, windows):
    result = {"allowed_warning": {}, "rejected": {}}
    for status in result:
        subset = [event for event in events if event["status"] == status]
        for hours in windows:
            values = []
            for event in subset:
                start = event["ts"] - timedelta(hours=hours)
                values.append(aggregate_rows(rows, start, event["ts"]))
            weighted_values = [item["weighted_total"] for item in values]
            result[status][f"{hours}h"] = {
                "count": len(values),
                "median_weighted_total": round(statistics.median(weighted_values), 2)
                if weighted_values
                else None,
                "min_weighted_total": round(min(weighted_values), 2)
                if weighted_values
                else None,
                "max_weighted_total": round(max(weighted_values), 2)
                if weighted_values
                else None,
            }
    return result


def build_ratios(current, historical, windows):
    ratios = {}
    for hours in windows:
        key = f"{hours}h"
        current_weighted = current[key]["weighted_total"]
        warning_median = historical["allowed_warning"][key]["median_weighted_total"]
        rejected_median = historical["rejected"][key]["median_weighted_total"]
        ratios[key] = {
            "vs_warning_median": round(current_weighted / warning_median, 3)
            if warning_median
            else None,
            "vs_rejected_median": round(current_weighted / rejected_median, 3)
            if rejected_median
            else None,
        }
    return ratios


def is_fresh(event, fresh_hours):
    if not event:
        return False
    now = datetime.now(timezone.utc)
    return now - event["ts"] <= timedelta(hours=fresh_hours)


def classify_band(current, historical, ratios, latest_event, fresh_hours):
    if latest_event and is_fresh(latest_event, fresh_hours):
        if latest_event["status"] == "rejected":
            return "critical", "fresh_rejected_status"
        if latest_event["status"] == "allowed_warning":
            return "high", "fresh_allowed_warning_status"

    ratio_5h = ratios.get("5h", {}).get("vs_rejected_median")
    ratio_1h = ratios.get("1h", {}).get("vs_rejected_median")
    warning_ratio_5h = ratios.get("5h", {}).get("vs_warning_median")

    if ratio_5h is None and ratio_1h is None:
        return "unknown", "no_rejected_baseline"
    if ratio_5h is not None and ratio_5h >= 0.8:
        return "high", "near_rejected_5h_baseline"
    if ratio_1h is not None and ratio_1h >= 0.95:
        return "high", "near_rejected_1h_baseline"
    if warning_ratio_5h is not None and warning_ratio_5h >= 0.5:
        return "medium", "above_warning_5h_baseline"
    if ratio_5h is not None and ratio_5h >= 0.25:
        return "medium", "elevated_5h_baseline"
    if ratio_1h is not None and ratio_1h >= 0.8:
        return "medium", "elevated_1h_baseline"
    return "low", "below_warning_baselines"


def classify_confidence(historical):
    warning_count = historical["allowed_warning"]["5h"]["count"]
    rejected_count = historical["rejected"]["5h"]["count"]
    if rejected_count >= 3 and warning_count >= 5:
        return "high"
    if rejected_count >= 2 and warning_count >= 3:
        return "medium"
    return "low"


def main():
    args = parse_args()
    windows = parse_windows(args.windows)
    messages = load_messages(args.projects_dir)
    events = load_limit_events(args.telemetry_dir)

    timestamps = [row["ts"] for row in messages if row["ts"]]
    now = max(timestamps) if timestamps else datetime.now(timezone.utc)

    current = build_current_windows(messages, now, windows)
    historical = build_historical_windows(messages, events, windows)
    ratios = build_ratios(current, historical, windows)
    latest_event = events[-1] if events else None
    band, reason = classify_band(
        current, historical, ratios, latest_event, args.fresh_status_hours
    )
    confidence = classify_confidence(historical)

    output = {
        "band": band,
        "reason": reason,
        "confidence": confidence,
        "as_of": now.isoformat(),
        "weights": WEIGHTS,
        "current": current,
        "historical": historical,
        "ratios": ratios,
        "latest_limit_event": {
            "status": latest_event["status"],
            "timestamp": latest_event["timestamp"],
            "hours_till_reset": latest_event["hours_till_reset"],
            "source": latest_event["source"],
        }
        if latest_event
        else None,
        "samples": {
            "deduped_messages": len(messages),
            "limit_events": Counter(event["status"] for event in events),
        },
        "notes": [
            "This is a heuristic relative to local history, not the Claude /usage percentage.",
            "Assistant message usage rows are deduplicated by project file plus message id.",
            "Weighted totals use input=1.0, output=1.0, cache_create=0.25, cache_read=0.01.",
        ],
    }

    print(json.dumps(output, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
