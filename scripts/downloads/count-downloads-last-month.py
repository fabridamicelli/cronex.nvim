import json
import pathlib

counts = {}
for o in pathlib.Path("downloads.jsonl").read_text().split():
    entry = json.loads(o)
    counts[entry["date"]] = entry["count"]
counts = dict(sorted(counts.items(), key=lambda i: i[1]))
print(sum(list(counts.values())[-30:]))
