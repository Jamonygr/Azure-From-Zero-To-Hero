"""Install pinned, checksum-verified offline check binaries into an ignored directory."""
import argparse
import hashlib
import io
import os
import platform
import tarfile
import urllib.request
import zipfile
from pathlib import Path

RELEASES = {
    'Windows': [
        ('gitleaks', 'https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_windows_x64.zip', 'd29144deff3a68aa93ced33dddf84b7fdc26070add4aa0f4513094c8332afc4e'),
        ('actionlint', 'https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_windows_amd64.zip', '6e7241b51e6817ea6a047693d8e6fed13b31819c9a0dd6c5a726e1592d22f6e9'),
    ],
    'Linux': [
        ('gitleaks', 'https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz', '551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb'),
        ('actionlint', 'https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz', '8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8'),
    ],
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--destination', type=Path, default=Path('.check-tools'))
    args = parser.parse_args()
    system = platform.system()
    if system not in RELEASES or platform.machine().lower() not in {'amd64','x86_64'}:
        raise SystemExit('This installer supports Windows/Linux x64; install check tools manually on other platforms.')
    args.destination.mkdir(parents=True,exist_ok=True)
    for name, url, expected in RELEASES[system]:
        request = urllib.request.Request(url,headers={'User-Agent':'zero-to-hero-repository-checks'})
        with urllib.request.urlopen(request,timeout=60) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != expected:
            raise SystemExit(f'Checksum mismatch for {name}; refusing installation')
        filename = name + ('.exe' if system=='Windows' else '')
        if system=='Windows':
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                content = archive.read(filename)
        else:
            with tarfile.open(fileobj=io.BytesIO(data),mode='r:gz') as archive:
                member = archive.extractfile(filename)
                if member is None:
                    raise SystemExit(f'Missing binary: {name}')
                content = member.read()
        target = args.destination / filename
        target.write_bytes(content)
        target.chmod(0o755)
        print(f'Installed checksum-verified {filename}')


if __name__ == '__main__':
    main()
