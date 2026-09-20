#!/usr/bin/env python3
"""Assemble index.html from the per-section sources in src/.

    python3 build.py           rebuild index.html
    python3 build.py --check   exit non-zero if index.html is stale

index.html is committed, not generated at serve time: the deck has to open from a memory
stick in a lecture hall, so the build is a convenience for editing and never a dependency of
presenting. Run this after editing anything under src/, and commit both.

Order is the filename order, and the filename order is the horizontal slide order, which the
deck's deep links depend on — #/3 is 03-proportional.html. Renaming a file moves a section.
"""

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / "src"
OUT = HERE / "index.html"


def sections():
    found = sorted(p for p in SRC.glob("*.html") if not p.name.startswith("_"))
    if not found:
        sys.exit(f"no section sources found in {SRC}")
    return found


def assemble():
    parts = [(SRC / "_head.html").read_text()]
    parts += [p.read_text() for p in sections()]
    parts.append((SRC / "_foot.html").read_text())
    return "".join(parts)


def main():
    built = assemble()
    if "--check" in sys.argv:
        current = OUT.read_text() if OUT.exists() else ""
        if current != built:
            sys.exit("index.html is stale — run: python3 build.py")
        print(f"index.html is up to date ({len(sections())} sections)")
        return
    OUT.write_text(built)
    print(f"wrote {OUT.relative_to(HERE.parent.parent.parent)} "
          f"from {len(sections())} sections, {len(built):,} bytes")


if __name__ == "__main__":
    main()
