# ORNL's measured efficiency map of the 2012 Nissan Leaf

The combined (motor + inverter) efficiency map that Lecture 4's efficiency-map notebook sets
beside the model's. Both files are written by

    pdftoppm -f 12 -l 12 -r 300 -png ape006_burress_2013_o.pdf slide
    python3 -I scripts/digitize_ornl_leaf_map.py slide-12.png data/ornl_leaf

Do not edit them by hand; change the script and rerun it.

## Source

T. Burress (ORNL), *Benchmarking State-of-the-Art Technologies*, DOE Vehicle Technologies
Program Annual Merit Review 2013, project APE006, slide 12, "LEAF motor & inverter efficiency
contours". Downloaded from
<https://www.energy.gov/sites/prod/files/2014/03/f13/ape006_burress_2013_o.pdf>; SHA-256
e8c74b0f2501c89686877628764fe169288f4765822e86345a41b48c1c297c1b. Measured at a 375 V DC link,
5 kHz switching and 65 °C coolant.

The motor is the 2012 (ZE0) car's first-generation 80 kW / 280 N·m machine, not the 110 kW /
320 N·m ZE1 machine the course's model is parameterized for: compare shape and level, never fit
to it. See `docs/research_notes/Electric and hybrid vehicles/teaching_materials.md` §2.

## Files

| File | Content |
|---|---|
| `combined_efficiency_pct.csv` | efficiency in percent; rows are rpm (500–10 000, 100 rpm step), columns N·m (0–280, 2.5 N·m step); NaN outside the measured region |
| `max_test_condition.csv` | ORNL's "max test condition" boundary, the top of the measured region |

Values are read from the figure's color, one 1 % band at a time, and are good to about one
point; points under a contour label are interpolated from their neighbors. The script's
docstring gives the method.
