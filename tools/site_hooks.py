"""Populate lesson navigation directly from lessons.psd1."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from site_common import PHASES, catalog


def on_config(config):
    lesson_nav = [{"Catalog": "labs/index.md"}]
    lessons = catalog()
    for phase, slug in PHASES.items():
        group = [{"Overview": f"phases/{slug}.md"}]
        group.extend({f"{item['Id']} — {item['Title']}": f"labs/{item['Folder']}/index.md"}
                     for item in lessons if item["Phase"] == phase)
        lesson_nav.append({phase: group})
    for item in config["nav"]:
        if "Labs" in item:
            item["Labs"] = lesson_nav
    return config
