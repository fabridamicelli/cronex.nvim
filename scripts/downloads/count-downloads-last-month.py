import json
import pathlib

N_LAST_DAYS = 30

entries = {}
lines = (
    (pathlib.Path(".").resolve() / "scripts" / "downloads" / "downloads.jsonl")
    .read_text()
    .split()
)
assert lines, "No content found in downloads.jsonl"
for line in lines:
    entry = json.loads(line)
    entries[entry["date"]] = entry["count"]

counts = sorted(entries.items(), key=lambda i: i[0])
print(sum(count for _, count in counts[-N_LAST_DAYS:]))
