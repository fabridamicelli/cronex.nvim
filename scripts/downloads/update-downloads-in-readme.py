import pathlib

CURR_DIR = pathlib.Path(".").resolve()

start = "![Git Clone Count](https://img.shields.io/badge/Downloads/Month-"
n = int((CURR_DIR / "scripts/downloads/last_month.txt").read_text())
new = (
    f"![Git Clone Count](https://img.shields.io/badge/Downloads/Month-{n}-brightgreen)"
)

readme = CURR_DIR / "README.md"
new_lines = []
for line in readme.read_text().splitlines():
    if line.startswith(start):
        new_lines.append(new)
    else:
        new_lines.append(line)
new_readme = "\n".join(new_lines)
readme.write_text(new_readme)
