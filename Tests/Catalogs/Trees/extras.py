"""Values of the TreesTests literals that are not catalog rows, through ref.py's model and cross-checks."""
import sys
import ref

CASES = [
    ("closure: [r,z,x,y,w] {z:r, y:r, x:y, w:r}", "RootedTree : children(r)"),
    ("closure: [r,z,x,y,w] {z:r, y:r, x:y, w:r}", "RootedTree : children(y)"),
    ("closure: [r,z,x,y,w] {z:r, y:r, x:y, w:r}", "RootedTree : preorder"),
]
if len(sys.argv) > 1:
    CASES = [tuple(a.split(" ;; ")) for a in sys.argv[1:]]
for src, op in CASES:
    got = ref.evaluate(src, op)
    s = ref.parse_source(src)
    ref.cross_check_source("x", s)
    o = op
    if o not in ("isTree", "isArborescence", "isAcyclic") and " == " not in o:
        steps = ref.parse_steps(o.split(" : ", 1)[0])
        for i in range(1, len(steps) + 1):
            try:
                ref.cross_check_built(f"x/{i}", ref.build(s, steps[:i]))
            except ref.Trap:
                pass
    print(f"{src} | {op} | {got}")
for f in ref.failures:
    print("CHECK FAILED", f)
