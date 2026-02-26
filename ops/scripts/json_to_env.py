#!/usr/bin/env python3
"""Convert a JSON object (from AWS Secrets Manager) to KEY=VALUE lines."""
import argparse
import json
import sys

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("json_file", help="Path to JSON file")
    args = parser.parse_args()

    try:
        with open(args.json_file, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"Failed to load JSON: {exc}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(data, dict):
        print("Expected JSON object at top level", file=sys.stderr)
        sys.exit(1)

    for key, value in data.items():
        print(f"{key}={value}")

if __name__ == "__main__":
    main()
