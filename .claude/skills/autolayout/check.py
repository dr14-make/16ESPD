"""Find layout defects in a rendered diagram: diagonal wire segments, crossings, overlapping wires,
wires through blocks or instance labels, and anything outside the outline.

Usage: check.py <file.dyad> <Component> <render.svg>

Wires come from the SVG (diagram coordinates, rounded to whole units); blocks from the component's
`_links` placements. Each default `$(instance)` label is estimated as a box from y2 + 0.07 h to
y2 + 0.2 h, 0.11 h wide per character. Custom `labels` and rotated blocks are estimated the same way,
so read the render for those.

A wire running exactly along a block's edge, as one leaving or reaching a bottom-center port
sideways does, is a graze, not a hit. A wire is not checked against the block of a port it ends at,
but is checked against that block's label. Wires leaving the same port may overlap. The component's
own ports may straddle the 0..1000 outline. A wire looping around its target, and labels drawn above
a block (Constant names, Gain `k=`), show only in the PNG. Exit status is the number of problems, so
a non-zero exit is a finding, not a crash.
"""
import itertools
import json
import re
import sys

dyad_path, component, svg_path = sys.argv[1:4]

src = open(dyad_path).read()
body = re.search(rf"^(?:\w+ )*component {component}\b.*?^end\b", src, re.S | re.M)
if not body:
    sys.exit(f"component {component} not found in {dyad_path}")
meta = re.search(r"^metadata (\{.*?^\})\s*$", body.group(0), re.S | re.M)
links = json.loads(meta.group(1)).get("_links", {}) if meta else {}

blocks, labels, ports = {}, {}, set()
for name, link in links.items():
    placement = link.get("Dyad", {}).get("placement", {})
    box = placement.get("diagram")
    if not box:
        continue
    x1, x2 = sorted((box["x1"], box["x2"]))
    y1, y2 = sorted((box["y1"], box["y2"]))
    blocks[name] = (x1, y1, x2, y2)
    if "icon" in placement:  # the component's own ports draw no label
        ports.add(name)
    else:
        h, cx = y2 - y1, (x1 + x2) / 2
        half = 0.055 * h * len(name)
        # glyphs start a little below the edge, leaving room for a bottom port's wire stub
        labels[name] = (cx - half, y2 + 0.07 * h, cx + half, y2 + 0.2 * h)

svg = open(svg_path).read()
paths = [[tuple(round(float(v)) for v in p) for p in re.findall(r"(-?[\d.]+) (-?[\d.]+)", d)]
         for d in re.findall(r'<path d="(M [^"]*)" stroke-stroke', svg)]
segs = [(i, a, b) for i, p in enumerate(paths) for a, b in zip(p, p[1:]) if a != b]
ends = [{p[0], p[-1]} for p in paths]


def span(u, v):
    return min(u, v), max(u, v)


problems = 0


def report(kind, *what):
    global problems
    if kind != "graze":
        problems += 1
    print(kind, *what)


for name, (x1, y1, x2, y2) in blocks.items():
    lo, hi = (-50, 1050) if name in ports else (0, 1000)  # own ports straddle the outline
    if x1 < lo or y1 < lo or x2 > hi or y2 > hi:
        report("outside", name, (x1, y1, x2, y2))
for i, p in enumerate(paths):
    if any(not -50 <= v <= 1050 for pt in p for v in pt):
        report("outside", f"wire {i}", p)

for i, a, b in segs:
    if a[0] != b[0] and a[1] != b[1]:
        report("diagonal", f"wire {i}", a, b)

for (i, a, b), (j, c, d) in itertools.combinations(segs, 2):
    if i == j:
        continue
    vert1, vert2 = a[0] == b[0], c[0] == d[0]
    if vert1 != vert2:
        (p, q), (r, s) = ((a, b), (c, d)) if vert1 else ((c, d), (a, b))
        lo, hi = span(r[0], s[0])
        ylo, yhi = span(p[1], q[1])
        if lo < p[0] < hi and ylo < r[1] < yhi:
            report("cross", f"wires {i} and {j}", (p[0], r[1]))
    elif vert1 and a[0] == c[0] or not vert1 and a[1] == c[1]:
        k = 1 if vert1 else 0
        lo1, hi1 = span(a[k], b[k])
        lo2, hi2 = span(c[k], d[k])
        if max(lo1, lo2) < min(hi1, hi2) and not ends[i] & ends[j]:
            report("overlap", f"wires {i} and {j}", a, b)


def inside(box, pt, margin=5):
    """A port's wire end sits a few units off its block's edge."""
    x1, y1, x2, y2 = box
    return x1 - margin <= pt[0] <= x2 + margin and y1 - margin <= pt[1] <= y2 + margin


def hits(box, a, b):
    """'hit' if the segment passes through the box's interior, 'graze' if it runs along its edge."""
    x1, y1, x2, y2 = box
    if a[0] == b[0]:
        fixed, lo, hi, (flo, fhi), (slo, shi) = a[0], *span(a[1], b[1]), (x1, x2), (y1, y2)
    else:
        fixed, lo, hi, (flo, fhi), (slo, shi) = a[1], *span(a[0], b[0]), (y1, y2), (x1, x2)
    if max(lo, slo) >= min(hi, shi) or not flo <= fixed <= fhi:
        return None
    return "hit" if flo < fixed < fhi else "graze"


for i, a, b in segs:
    if a[0] != b[0] and a[1] != b[1]:
        continue
    for kind, boxes in (("block", blocks), ("label", labels)):
        for name, box in boxes.items():
            if kind == "block" and any(inside(box, e) for e in ends[i]):
                continue  # the wire's own port sits in this block
            result = hits(box, a, b)
            if result == "hit":
                report(f"through-{kind}", name, f"wire {i}", a, b)
            elif result == "graze" and kind == "label":
                report("graze", name, f"wire {i}", a, b)

print(f"{problems} problem(s)")
sys.exit(min(problems, 255))
