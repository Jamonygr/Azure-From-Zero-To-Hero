"""Read the authoritative PowerShell curriculum; never maintain a second catalog."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PHASES = {
    "Workstation": "workstation",
    "Foundations": "foundations",
    "Networking": "networking",
    "Windows compute": "windows-compute",
    "Platform services": "platform-services",
    "Operations": "operations",
}


def catalog():
    result = subprocess.run(
        ["pwsh", "-NoLogo", "-NoProfile", "-File", str(ROOT / "scripts/Export-LearningCatalog.ps1")],
        cwd=ROOT, check=True, capture_output=True, encoding="utf-8-sig",
    )
    lessons = json.loads(result.stdout)["Lessons"]
    assert len(lessons) == 31 and len({item["Id"] for item in lessons}) == 31
    return sorted(lessons, key=lambda item: item["Id"])


def lesson_path(lesson):
    return f"labs/{lesson['Folder']}/"
