import json
import pathlib
from collections import defaultdict

N_LAST_DAYS = 30

entries = {}
lines = (
    (pathlib.Path(".").resolve() / "scripts" / "downloads" / "downloads.jsonl")
    .read_text()
    .split()
)
assert lines, "No content found in downloads.jsonl"
entries = defaultdict(list)
for line in lines:
    entry = json.loads(line)
    entries[entry["date"]].append(entry["count"])

entries = sorted(entries.items(), key=lambda entry: entry[0])
counts = [(date, max(vals)) for date, vals in entries]
print(sum(count for _, count in counts[-N_LAST_DAYS:]))
