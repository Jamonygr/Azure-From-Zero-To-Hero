# Illustrated asset provenance

The cloud-and-Terraform cover at `illustrations/zero-to-hero-cover.png` is original
artwork generated with OpenAI imagegen on October 13, 2026. The prompt requested a
black/navy Azure learning cover, cyan/blue cloud infrastructure, a purple Terraform
symbol, Windows servers, and the title “Azure From Zero To Hero”. A second edit
replaced decorative terminal text with `az login`, `terraform plan`, and
`terraform show tfplan`. The cover is conceptual, not a deployment topology.

The 55 SVG outputs are generated deterministically by
`tools/render_site_visuals.py`: six symbolic phase illustrations, 31 distinct
lesson learning sequences, three shared workflow guides, and 15 restyled
architecture diagrams. Original architecture layouts live in `diagram-sources/`.
Restyling preserves their labels, coordinates, shapes, and connections. New icons
use original path geometry written for this repository.

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
