"""
Build script for the Zyzz desktop application.

Produces a self-contained folder in dist/Zyzz/ that can be distributed
without requiring Python or uv to be installed on the target machine.

Prerequisites
-------------
    pip install pyinstaller
    # or
    uv tool install pyinstaller

Usage
-----
    python scripts/build_installer.py
    # or
    uv run python scripts/build_installer.py
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRY_POINT = ROOT / "apps" / "desktop" / "app.py"
APP_NAME = "Zyzz"


def main() -> None:
    """Run PyInstaller with options suited for a PySide6 desktop application."""
    cmd = [
        sys.executable,
        "-m",
        "PyInstaller",
        f"--name={APP_NAME}",
        "--windowed",          # No console window on Windows/macOS
        "--onedir",            # One folder (faster startup than --onefile)
        "--clean",             # Remove cached build files first
        "--noconfirm",         # Overwrite existing dist without asking
        "--collect-all=PySide6",
        str(ENTRY_POINT),
    ]

    print(f"Building {APP_NAME}...")
    print(f"Entry point: {ENTRY_POINT}")
    print()

    result = subprocess.run(cmd, cwd=ROOT)

    if result.returncode == 0:
        dist_path = ROOT / "dist" / APP_NAME
        print()
        print(f"Build successful. Output: {dist_path}")
        print(f"Run the app: {dist_path / APP_NAME}.exe")
    else:
        print("Build failed.", file=sys.stderr)
        sys.exit(result.returncode)


if __name__ == "__main__":
    main()
