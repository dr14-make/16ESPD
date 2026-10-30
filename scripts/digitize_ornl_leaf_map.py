"""Digitize ORNL's measured combined (motor + inverter) efficiency map of the 2012 Nissan Leaf.

    pdftoppm -f 12 -l 12 -r 300 -png ape006_burress_2013_o.pdf slide
    python3 -I scripts/digitize_ornl_leaf_map.py slide-12.png data/ornl_leaf

Source: T. Burress (ORNL), "Benchmarking State-of-the-Art Technologies", DOE VTO Annual Merit
Review 2013, project APE006, slide 12, "LEAF motor & inverter efficiency contours". The page
must be rendered at exactly 300 dpi: the pixel calibration below is read from that rendering's
tick labels and color bar.

The map is a MATLAB `contourf` with 1 % bands on a jet color scale from 70 % to 99 %. Each grid
point takes the pixels in a small window around it, keeps only saturated ones (contour lines,
label boxes and the white background are not), maps each to the nearest color-bar entry and
takes the median. A band is one flat color, so a value is the band it falls in, read about half
a point below the contour labels on its edges; treat every value as within one point. Points with no saturated pixel lie outside the measured region and are written as NaN.
The "max test condition" boundary is the topmost yellow pixel of each column; the yellow line
itself would read as an 88 % band, so points within `MARGIN` of it are NaN too. The contour
labels are pale boxes over the bands; a point under one is filled from the nearest digitized
points on both sides of it, along speed or along torque, within `GAP` grid steps.

Needs Pillow only.
"""

import csv
import os
import sys

from PIL import Image

# Page pixels at 300 dpi, read from the tick labels: 2000 rpm at x = 1674.5, 9000 rpm at 2625;
# 0 N.m at y = 1167.5, 300 N.m at 361.
X0, X_PER_RPM = 1402.9, 0.135786
Y0, Y_PER_NM = 1167.5, 2.68833
# Color bar column, 70 % at its bottom (y = 1168) and 95 % at y = 472.
CBAR_X, CBAR_TOP, CBAR_BOTTOM = 2805, 363, 1168
CBAR_PX_PER_PCT = 27.84

RPM = [500 + 100 * k for k in range(96)]
TORQUE = [2.5 * k for k in range(113)]
HALF_WINDOW = 4
MARGIN = 4.0
GAP = 4


def page_xy(rpm, torque):
    return X0 + X_PER_RPM * rpm, Y0 - Y_PER_NM * torque


def saturated(c):
    return max(c) - min(c) > 100 and min(c) < 150


def color_bar(px):
    entries = []
    for y in range(CBAR_TOP, CBAR_BOTTOM + 1):
        c = px[CBAR_X, y]
        if saturated(c):
            entries.append((c, 70.0 + (CBAR_BOTTOM - y) / CBAR_PX_PER_PCT))
    return entries


_NEAREST = {}


def nearest(entries, c):
    if c not in _NEAREST:
        _NEAREST[c] = min(entries, key=lambda e: sum((a - b) ** 2 for a, b in zip(e[0], c)))[1]
    return _NEAREST[c]


def efficiency(px, entries, rpm, torque):
    x, y = page_xy(rpm, torque)
    vals = []
    for dx in range(-HALF_WINDOW, HALF_WINDOW + 1):
        for dy in range(-HALF_WINDOW, HALF_WINDOW + 1):
            c = px[round(x) + dx, round(y) + dy]
            if saturated(c):
                vals.append(nearest(entries, c))
    if len(vals) < (2 * HALF_WINDOW + 1) ** 2 // 2:
        return float("nan")
    vals.sort()
    return vals[len(vals) // 2]


def boundary(px):
    """Topmost yellow pixel per column, below the legend; columns where the gray 80 kW line
    hides the yellow one are interpolated from their neighbors."""
    found = {}
    y_top = round(page_xy(0, 284)[1])
    for rpm in RPM:
        x, _ = page_xy(rpm, 0)
        for y in range(y_top, round(page_xy(0, 60)[1])):
            c = px[round(x), y]
            if c[0] > 220 and c[1] > 220 and c[2] < 90:
                found[rpm] = round((Y0 - y) / Y_PER_NM, 1)
                break
    known = sorted(found)
    out = {}
    for rpm in RPM:
        if rpm in found:
            out[rpm] = found[rpm]
            continue
        lo = max(k for k in known if k < rpm)
        hi = min(k for k in known if k > rpm)
        out[rpm] = round(found[lo] + (found[hi] - found[lo]) * (rpm - lo) / (hi - lo), 1)
    return out


def fill_labels(grid):
    """Fill each NaN that has digitized points on both sides of it, along speed or torque."""
    filled = [row[:] for row in grid]
    for i, row in enumerate(grid):
        for j, v in enumerate(row):
            if v == v:
                continue
            for di, dj in ((1, 0), (0, 1)):
                a = b = None
                for k in range(1, GAP + 1):
                    ia, ja, ib, jb = i - k * di, j - k * dj, i + k * di, j + k * dj
                    if a is None and 0 <= ia and 0 <= ja and grid[ia][ja] == grid[ia][ja]:
                        a = (k, grid[ia][ja])
                    if (b is None and ib < len(grid) and jb < len(row)
                            and grid[ib][jb] == grid[ib][jb]):
                        b = (k, grid[ib][jb])
                if a and b:
                    filled[i][j] = round((a[1] * b[0] + b[1] * a[0]) / (a[0] + b[0]), 1)
                    break
    return filled


def main(png, out):
    px = Image.open(png).convert("RGB").load()
    entries = color_bar(px)
    top = boundary(px)
    grid = [[efficiency(px, entries, rpm, t) if t <= top[rpm] - MARGIN else float("nan")
             for t in TORQUE] for rpm in RPM]
    grid = fill_labels(grid)
    for i, rpm in enumerate(RPM):
        grid[i] = [v if t <= top[rpm] - MARGIN else float("nan") for t, v in zip(TORQUE, grid[i])]
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "combined_efficiency_pct.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["rpm \\ torque_Nm"] + [f"{t:.1f}" for t in TORQUE])
        for rpm, row in zip(RPM, grid):
            w.writerow([rpm] + ["NaN" if v != v else f"{v:.1f}" for v in row])
    with open(os.path.join(out, "max_test_condition.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["rpm", "torque_Nm"])
        w.writerows(sorted(top.items()))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
