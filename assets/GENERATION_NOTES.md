# Illustrated asset provenance

The cloud-and-Terraform cover at `illustrations/zero-to-hero-cover.png` is original
artwork generated with OpenAI imagegen on October 13, 2026. The prompt requested a
black/navy Azure learning cover, cyan/blue cloud infrastructure, a purple Terraform
symbol, Windows servers, and the title “Azure From Zero To Hero”. A second edit
replaced decorative terminal text with `az login`, `terraform plan`, and
`terraform show tfplan`. The cover is conceptual, not a deployment topology.

The original 55 SVG outputs are generated deterministically by
`tools/render_site_visuals.py`: six symbolic phase illustrations, 31 distinct
lesson learning sequences, three shared workflow guides, and 15 restyled
architecture diagrams. Original architecture layouts live in `diagram-sources/`.
Restyling preserves their labels, coordinates, shapes, and connections. New icons
use original path geometry written for this repository.

## Additional illustrated phase scenes

Six new original PNG scenes were generated with the built-in OpenAI imagegen tool
on October 13, 2026. The existing cover was supplied as a style reference, without
changing that cover. The exact prompts are recorded in `phase-art-prompts.json`.
These images show a workstation, Terraform workbench, network fabric, Windows
server fleet, platform services, and operations console. They contain no lesson
titles; accessible titles and captions are provided by the website. The scenes
are conceptual artwork and do not assert a deployed service topology.

The final project assets are stored in `illustrations/` as
`workstation-scene.png`, `foundations-scene.png`, `networking-scene.png`,
`windows-compute-scene.png`, `platform-services-scene.png`, and
`operations-scene.png`. Original generated files remain in the local Codex
generated-images directory; the website uses the repository copies.

## Lesson teaching diagrams and curriculum journey

The additional 31 landscape teaching diagrams and six-phase journey map are
original code-native SVGs, produced by the same deterministic renderer. This
brings the total to 87 SVGs. Each lesson diagram is placed in its Architecture
section and reused as its curriculum-card preview. The original workflow
sequences and shared guides remain available in lessons and the visual gallery.

New diagram fingerprints include the lesson README, Terraform source, and local
modules used by the lesson. Reviewed resource inventories and per-figure arrow
legends distinguish provisioned services, conceptual steps, and inspection or
DNS relationships. CLZ-360's workflow wording was corrected to describe its
workspace and empty action group; it does not provision telemetry collection.

Lesson metadata is imported from `curriculum/lessons.psd1` through PowerShell.
Each lesson figure embeds its source README SHA-256 with LF-normalized line endings. Architecture outputs embed
their original source SHA-256. Learning arrows indicate exercise order, not
network traffic. The accompanying text defines actual deployment settings.

Regenerate after changing a lesson or diagram source:

```powershell
python tools/render_site_visuals.py
python tools/render_site_visuals.py --check
```

The original roadmap, book cover, PDF, and their existing rights notices remain
unchanged. These generation notes do not alter repository or book licensing.
