"""Original decorative markers; the adjacent text carries every meaning."""
from urllib.parse import quote

PATHS = {
    'prerequisites': '<path d="M8 5h10v15H8zM5 8H3v15h10v-3M11 9h4m-4 4h4"/>',
    'cost': '<circle cx="12" cy="12" r="9"/><path d="M15 8h-4a2 2 0 0 0 0 4h2a2 2 0 0 1 0 4H9m3-10v12"/>',
    'deploy': '<path d="M6 17H5a4 4 0 0 1-1-8 6 6 0 0 1 11-2 5 5 0 0 1 4 10h-1M12 22V11m-4 4 4-4 4 4"/>',
    'verify': '<path d="m12 3 8 4v6c0 4-4 7-8 9-4-2-8-5-8-9V7zM8 12l3 3 5-6"/>',
    'cleanup': '<path d="M4 6h16M9 6V3h6v3M6 6l1 15h10l1-15M10 10v7m4-7v7"/>',
    'quiz': '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6m-6 5h6m-6 4h3"/>',
    'progress': '<path d="M4 20V4m0 16h17M8 16l4-5 4 2 5-8"/>',
}


def marker(kind):
    return f'<svg class="zth-marker" viewBox="0 0 24 24" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{PATHS[kind]}</svg>'


def styles():
    declarations = []
    for kind, path in PATHS.items():
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{path}</svg>'
        declarations.append(f'  --zth-icon-{kind}: url("data:image/svg+xml,{quote(svg, safe="")}");')
    return ':root {\n'+'\n'.join(declarations)+'\n}\n'
