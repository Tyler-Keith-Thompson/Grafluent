"""Assemble CycleRepresentationTests.swift: rep_head.swift (written by hand), the representation
variants from gen_rep.py, the generated tests for CY-704 - CY-706, then rep_tail.swift (written by
hand; its literals were computed with rep.py). Called by gen.py."""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gen  # noqa: E402
import gen_rep  # noqa: E402


def write(out_dir):
    head = (HERE / "rep_head.swift").read_text()
    gen_text = gen_rep.text() + "\n"
    rows = {r[0]: r for r in gen.rows()}
    extra = "\n\n".join(gen.test_for(*rows[c]) for c in ["CY-704", "CY-705", "CY-706"])
    tail = (HERE / "rep_tail.swift").read_text()
    out = head + '\n@Suite("Cycles on every representation")\nstruct CycleRepresentationTests {\n' + gen_text + "\n\n" + extra + "\n\n" + tail
    (Path(out_dir) / "CycleRepresentationTests.swift").write_text(out)
    print(out.count("@Test"))


if __name__ == "__main__":
    write(sys.argv[1] if len(sys.argv) > 1 else HERE.parent.parent / "CyclesTests")
