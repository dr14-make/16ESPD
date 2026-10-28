"""Set `_links` entries of one component in a .dyad file from a JSON spec, keeping every other byte.

Usage: apply.py <file.dyad> <Component> <spec.json>

The spec maps a tag to its new value, e.g.
  {"engine": {"Dyad": {"placement": {"diagram": {"x1": 105, "y1": 35, "x2": 185, "y2": 115}}}},
   "id7": {"Dyad": {"edges": [{"S": 1, "M": [{"x": 100, "y": 115}], "E": 2}]}}}
An existing entry must be written on one line; a tag with no entry yet is added at the top of
`_links`. Tags are looked up only inside <Component>, since test components reuse wire tags.
"""
import json
import re
import sys

path, component, spec_path = sys.argv[1:4]
src = open(path).read()
body = re.search(rf"^(?:\w+ )*component {component}\b.*?^end\b", src, re.S | re.M)
if not body:
    sys.exit(f"component {component} not found in {path}")
text = body.group(0)

for tag, value in json.load(open(spec_path)).items():
    pattern = rf'^(\s*"{re.escape(tag)}": )\{{.*\}}(,?)$'
    text, n = re.subn(pattern, lambda m: m.group(1) + json.dumps(value) + m.group(2), text, flags=re.M)
    if n == 1:
        continue
    if n > 1 or re.search(rf'^\s*"{re.escape(tag)}":', text, re.M):
        sys.exit(f"{tag}: entry is not a single line; edit it by hand")
    text, n = re.subn(r'^(\s*)"_links": \{\n',
                      lambda m: f'{m.group(0)}{m.group(1)}  "{tag}": {json.dumps(value)},\n',
                      text, count=1, flags=re.M)
    if n != 1:
        sys.exit(f'{tag}: no multi-line "_links" block in {component} to add to')

open(path, "w").write(src[:body.start()] + text + src[body.end():])
