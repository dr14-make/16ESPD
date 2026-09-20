#!/usr/bin/env python3
"""Assemble index.html from the per-section sources in src/.

    python3 build.py             rebuild index.html
    python3 build.py --check     exit non-zero if index.html is stale
    python3 build.py --figures   report which figure slots are filled, and by what

index.html is committed, not generated at serve time: the deck has to open from a memory
stick in a lecture hall, so the build is a convenience for editing and never a dependency of
presenting. Run this after editing anything under src/, and commit both.

Order is the filename order, and the filename order is the horizontal slide order, which the
deck's deep links depend on — #/3 is 03-proportional.html. Renaming a file moves a section.
"""

import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / "src"
OUT = HERE / "index.html"
FIGURES = HERE / "assets" / "figures"
NOTEBOOKS = HERE.parent.parent.parent / "notebooks" / "lecture01"


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


VOID = {"br", "hr", "img", "input", "meta", "link", "source", "path", "circle", "rect",
        "polyline", "line", "use", "marker", "text", "g", "defs", "svg", "polygon", "ellipse"}


class _Structure(HTMLParser):
    """Walks the built deck, checking nesting and counting slides.

    A mis-edited section file that drops or doubles a `</div>` does not fail loudly: the
    browser silently re-parents everything after it, and the deck quietly loses most of its
    slides. This turns that into a build error.
    """

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack = []
        self.errors = []
        self.horizontals = 0
        self.verticals = 0
        self.notes = 0
        self._in_svg = 0

    def handle_starttag(self, tag, attrs):
        if tag == "svg":
            self._in_svg += 1
        if self._in_svg or tag in VOID:
            return
        if tag == "section":
            depth = sum(1 for t, _ in self.stack if t == "section")
            if depth == 0:
                self.horizontals += 1
            elif depth == 1:
                self.verticals += 1
        if tag == "aside":
            self.notes += 1
        self.stack.append((tag, self.getpos()[0]))

    def handle_endtag(self, tag):
        if tag == "svg":
            self._in_svg = max(0, self._in_svg - 1)
            return
        if self._in_svg or tag in VOID:
            return
        if not self.stack:
            self.errors.append(f"line {self.getpos()[0]}: stray </{tag}>")
            return
        open_tag, line = self.stack[-1]
        if open_tag != tag:
            self.errors.append(
                f"line {self.getpos()[0]}: </{tag}> closes <{open_tag}> opened on line {line}")
            return
        self.stack.pop()


def validate(built):
    """Fail the build on broken nesting or a slide that lost its notes."""
    parser = _Structure()
    parser.feed(built)
    problems = list(parser.errors)
    problems += [f"line {line}: <{tag}> never closed" for tag, line in parser.stack]
    if parser.horizontals != len(sections()):
        problems.append(f"{parser.horizontals} horizontal sections parsed, "
                        f"{len(sections())} source files")
    if parser.notes != parser.verticals:
        problems.append(f"{parser.verticals} slides but {parser.notes} <aside> blocks — "
                        "every slide carries speaker notes")
    if problems:
        sys.exit("index.html is structurally broken:\n  " + "\n  ".join(problems))
    return parser.horizontals, parser.verticals


def figures():
    """Reconcile the deck's figure slots against the files and the notebooks.

    `save_figure` in notebooks/lecture01/support.jl treats this deck's index.html as the
    authoritative list of slot names, so the three sets have to agree: a slot with no producer
    renders a placeholder forever, and a `save_figure` name that is not a slot throws.
    """
    slots = sorted(set(re.findall(r"assets/figures/([\w\-.]+)", OUT.read_text())))
    on_disk = {p.name for p in FIGURES.glob("*") if p.suffix in (".svg", ".png")}

    produced = {}
    for nb in sorted(NOTEBOOKS.glob("*.ipynb")):
        cells = json.loads(nb.read_text())["cells"]
        source = "".join("".join(c["source"]) for c in cells if c["cell_type"] == "code")
        for name in re.findall(r'save_figure\([^,]+,\s*"([^"]+)"', source):
            produced.setdefault(name if "." in name else name + ".svg", []).append(nb.name)

    print(f"{'slot':<32} {'file':<6} {'produced by'}")
    for slot in slots:
        by = ", ".join(produced.get(slot, [])) or "— nothing writes it"
        print(f"{slot:<32} {'yes' if slot in on_disk else '—':<6} {by}")

    orphans = sorted(on_disk - set(slots))
    stray = sorted(set(produced) - set(slots))
    print(f"\n{sum(s in on_disk for s in slots)} of {len(slots)} slots filled")
    if orphans:
        print("files with no slot, nothing loads them:", ", ".join(orphans))
    if stray:
        print("save_figure names that are not slots, these throw:", ", ".join(stray))
    return 1 if (orphans or stray) else 0


def main():
    if "--figures" in sys.argv:
        sys.exit(figures())
    built = assemble()
    horizontals, verticals = validate(built)
    if "--check" in sys.argv:
        current = OUT.read_text() if OUT.exists() else ""
        if current != built:
            sys.exit("index.html is stale — run: python3 build.py")
        print(f"index.html is up to date — {horizontals} sections, {verticals} slides")
        return
    OUT.write_text(built)
    print(f"wrote {OUT.relative_to(HERE.parent.parent.parent)} — {horizontals} sections, "
          f"{verticals} slides, {len(built):,} bytes")


if __name__ == "__main__":
    main()
