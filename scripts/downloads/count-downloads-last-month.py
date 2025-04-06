import json
import pathlib

counts = {}
lines = (
    (pathlib.Path(".").resolve() / "scripts" / "downloads" / "downloads.jsonl")
    .read_text()
    .split()
)
assert lines, "No content found in downloads.jsonl"
for line in lines:
    entry = json.loads(line)
    counts[entry["date"]] = entry["count"]
counts = dict(sorted(counts.items(), key=lambda i: i[1]))
print(sum(list(counts.values())[-30:]))
