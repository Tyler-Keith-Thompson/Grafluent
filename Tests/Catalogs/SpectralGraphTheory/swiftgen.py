"""Writes the catalog-row test files of Tests/SpectralGraphTheoryTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.5.4 \
        python3 Tests/Catalogs/SpectralGraphTheory/swiftgen.py [--phase2] [OUT_DIR]
    # default OUT_DIR: Tests/SpectralGraphTheoryTests

First checks that ref.py's model reproduces cases.md byte for byte. Then it re-evaluates every
phase 1 row on the model at full precision, asserts that the model's value renders to the catalog
cell, and writes one @Test per row with the full-precision values as literals:

- a matrix: its exact CSR arrays (`offsets`, `columns`), its stored values (relative 1e-12), every
  entry through the subscript when n ≤ 8 and the catalog's invariants otherwise, and `pattern`;
- a spectrum: every value, ascending (1e-9 · max(1, |λ_max|));
- λ₂ and the spectral radius: 1e-6 · max(1, scale), scale the largest |eigenvalue| of the matrix;
- a Fiedler vector with simple λ₂: every entry (1e-5), unit length, `value(of:)` and
  `value(ofIndex:)`; with degenerate λ₂ only λ₂, its multiplicity in the spectrum, unit length,
  orthogonality to the null vector, the residual ‖Mx − λ₂x‖ and the Rayleigh quotient;
- a spectral ordering: the exact list, or for `(ties: …)` rows a permutation sorted by the
  returned Fiedler vector that keeps every catalog pair whose model entries differ by more than 1e-4;
- counts: relative 1e-9 and integer-valued when unweighted below 2⁵³; resistances 1e-6 · max(1, R);
  effective graph resistance and the Kemeny constant 1e-9 · max(1, |value|); exact 0 and nil.

Trap rows become exit tests followed by the same setup without the fault. The hand-written exit
tests in extra_traps.swift are spliced into the precondition file. Phase 2 rows (SGT-205 onward) are
written to SpectralPhase2Tests.swift only with --phase2.
"""
import os
import re
import sys
from fractions import Fraction

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
PHASE2 = "--phase2" in sys.argv
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.join(HERE, "..", "..", "SpectralGraphTheoryTests")

# ---------------------------------------------------------------------------------------------
# Catalog check
# ---------------------------------------------------------------------------------------------
ref.define()
ref.number_rows()
ref.compute()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
ROWS = {int(r[0][4:]): r for r in ref.ROWS}
N = len(ROWS)
assert N == 217
PHASE2_FIRST = min(n for n, r in ROWS.items() if r[1] == "Phase 2")
assert PHASE2_FIRST == 205


def is_trap(n): return ROWS[n][5] == "**trap**"


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def num(x):
    """A Double literal that parses to the same Double."""
    x = float(x)
    if x != x:
        return ".nan"
    if x in (float("inf"), float("-inf")):
        return ".infinity" if x > 0 else "-.infinity"
    if x == 0:
        return "0"
    # The shortest decimal within 1e-14 · max(1, |x|): 3.9999999999999964 is written 4. Every
    # tolerance below is at least 1e-12 relative, so the literal stays exact enough.
    for digits in range(1, 18):
        t = float("%.*g" % (digits, x))
        if abs(t - x) <= 1e-14 * max(1.0, abs(x)):
            x = t
            break
    if x == int(x) and abs(x) < 1e15:
        return str(int(x))
    return repr(x)


def nums(xs, per_line=8, ind="            "):
    xs = [num(x) for x in xs]
    if not xs:
        return "[]"
    if len(xs) <= per_line:
        return "[" + ", ".join(xs) + "]"
    lines = [", ".join(xs[i:i + per_line]) for i in range(0, len(xs), per_line)]
    return "[\n" + ",\n".join(ind + l for l in lines) + ",\n" + ind[:-4] + "]"


def ints(xs, per_line=24, ind="            "):
    xs = [str(x) for x in xs]
    if not xs:
        return "[] as [Int]"
    if len(xs) <= per_line:
        return "[" + ", ".join(xs) + "]"
    lines = [", ".join(xs[i:i + per_line]) for i in range(0, len(xs), per_line)]
    return "[\n" + ",\n".join(ind + l for l in lines) + ",\n" + ind[:-4] + "]"


def pairs(ps, per_line=12, ind="            "):
    xs = ["(%s, %s)" % p for p in ps]
    if not xs:
        return "[]"
    if len(xs) <= per_line:
        return "[" + ", ".join(xs) + "]"
    lines = [", ".join(xs[i:i + per_line]) for i in range(0, len(xs), per_line)]
    return "[\n" + ",\n".join(ind + l for l in lines) + ",\n" + ind[:-4] + "]"


def weights_literal(ws):
    """[Int] when every weight is an integer (the BinaryInteger overload), else [Double]."""
    if all(isinstance(w, int) for w in ws):
        return "[Int]", "[" + ", ".join(str(w) for w in ws) + "]"
    return "[Double]", "[" + ", ".join(num(w) for w in ws) + "]"


def graph_lines(g, ind="        ", var="graph"):
    """The catalog graph on the reference conformer: every vertex listed in `vertices` order, the
    edges in position order."""
    named = [(g.vertices[u], g.vertices[v]) for u, v in g.edges]
    vs = g.vertices
    vlit = "Array(0 ..< %d)" % len(vs) if vs == list(range(len(vs))) and vs else ints(vs, ind=ind + "    ")
    if not vs:
        vlit = "[] as [Int]"
    out = [ind + "let edges: [(Int, Int)] = %s" % pairs(named, ind=ind + "    ")]
    if g.directed:
        out.append(ind + "let %s = ReferenceDirectedMultigraph(vertices: %s, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })" % (var, vlit))
    else:
        out.append(ind + "let %s = ReferencePseudograph(vertices: %s, edges: edges.map { UndirectedEdge($0.0, $0.1) })" % (var, vlit))
    return out


# ---------------------------------------------------------------------------------------------
# Full-precision evaluation (ref.evaluate's branches, returning the raw values)
# ---------------------------------------------------------------------------------------------

def raw(n):
    _, group, case, cell, op, expected = ROWS[n]
    g = ref.parse_graph(cell)
    wr = ref.parse_weights(op)
    call = op.split(" [")[0].strip()
    name = call.split("(")[0]
    w = ref.check_weights(g, wr, allow_negative=(name == "adjacencyMatrix"))
    if name == "adjacencyMatrix":
        v = ref.adjacency(g, w)
    elif name == "laplacianMatrix":
        if g.directed:
            A = ref.adjacency(g, w)
            d = ref.degrees(A)
            v = [[(d[i] if i == j else 0) - A[i][j] for j in range(g.n)] for i in range(g.n)]
        else:
            v = ref.laplacian(g, w)
    elif name == "normalizedLaplacianMatrix":
        v = ref.normalized(g, w)
    elif name == "randomWalkLaplacianMatrix":
        v = ref.random_walk(g, w)
    elif name == "signlessLaplacianMatrix":
        v = ref.signless(g, w)
    elif name == "laplacianSpectrum":
        v = ref.eigvalsh(ref.laplacian(g, w))
    elif name == "adjacencySpectrum":
        v = ref.eigvalsh(ref.adjacency(g, w))
    elif name == "normalizedLaplacianSpectrum":
        v = ref.eigvalsh(ref.normalized(g, w))
    elif name == "signlessLaplacianSpectrum":
        v = ref.eigvalsh(ref.signless(g, w))
    elif name == "algebraicConnectivity":
        v = ref.lam2(g, w, "normalized" in call)
    elif name == "fiedlerVector":
        v = ref.fiedler(g, w, "normalized" in call)
    elif name == "spectralOrdering":
        v = ref.spectral_ordering(g, w, "normalized" in call)
    elif name == "spectralRadius":
        v = ref.spectral_radius(g, w)
    elif name == "numberOfSpanningTrees":
        if "root" in call:
            r = int(re.search(r"root: (-?\d+)", call).group(1))
            v = ref.arborescences(g, w, g.vertices.index(r))
        else:
            v = ref.spanning_trees(g, w)
    elif name == "resistanceDistance":
        a, b = map(int, re.findall(r"-?\d+", call)[:2])
        v = ref.resistance(g, w, g.vertices.index(a), g.vertices.index(b))
    elif name == "effectiveGraphResistance":
        v = ref.effective_graph_resistance(g, w) if g.n > 0 else Fraction(0)
    elif name == "kemenyConstant":
        v = ref.kemeny(g, w)
    elif name == "spectralBisection":
        v = ref.bisection(g, w)
    else:
        raise AssertionError(op)
    assert ref.render_value(name, g, v) == expected, (n, ref.render_value(name, g, v), expected)
    return g, w, wr, call, name, v


def operator(g, w, name, call):
    """The dense matrix whose eigenvalues a value of `name` comes from."""
    if name in ("spectralRadius", "adjacencySpectrum"):
        return ref.adjacency(g, w)
    if "normalized" in call or name in ("normalizedLaplacianSpectrum", "kemenyConstant"):
        return ref.normalized(g, w)
    return ref.laplacian(g, w)


def scale_of(g, w, name, call):
    vals = ref.eigvalsh(operator(g, w, name, call))
    return max([1.0] + [abs(x) for x in vals])


# ---------------------------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------------------------

def call_expr(call, wr, var="graph"):
    """The Swift call, with `weights` passed as the closure when the row has them."""
    if call.endswith(" weight:"):
        call = call[:-len(" weight:")]
    name = call.split("(")[0]
    inner = call[len(name) + 1:-1] if call.endswith(")") else ""
    args = [a.strip() for a in inner.split(",") if a.strip() and a.strip() != "weight:"]
    if wr is not None:
        if name == "resistanceDistance":
            args.append("weight: { weights[$0] }")
        else:
            args.insert(0, "weight: { weights[$0] }")
    return "%s.%s(%s)" % (var, name, ", ".join(args))


def weight_decl(wr, ind="        "):
    if wr is None:
        return []
    t, lit = weights_literal(wr)
    return [ind + "let weights: %s = %s" % (t, lit)]


def header(n):
    _, group, case, cell, op, expected = ROWS[n]
    return ['    @Test("SGT-%03d %s")' % (n, case.replace('"', '\\"'))]


def comment(n):
    _, group, case, cell, op, expected = ROWS[n]
    return "        // %s · %s → %s" % (cell, op, expected if len(expected) < 160 else expected[:157] + "…")


def matrix_lines(g, v):
    n = len(v)
    vals = [[float(x) for x in row] for row in v]
    offsets, columns, stored = [0], [], []
    for row in vals:
        for j, x in enumerate(row):
            if abs(x) > 1e-15:
                columns.append(j)
                stored.append(x)
        offsets.append(len(columns))
    out = ["        #expect(matrix.rowCount == %d)" % n,
           "        #expect(matrix.nonzeroCount == %d)" % len(stored),
           "        #expect(matrix.offsets == %s)" % ints(offsets),
           "        #expect(matrix.columns == %s)" % ints(columns),
           "        // The stored values, row by row (relative 1e-12: exact up to rounding).",
           "        let stored: [Double] = %s" % nums(stored),
           "        #expect(matrix.values.count == stored.count)",
           "        for (k, value) in zip(matrix.values, stored).enumerated() {",
           "            #expect(abs(value.0 - value.1) <= 1e-12 * max(1, abs(value.1)), \"stored entry \\(k)\")",
           "        }",
           "        #expect(!matrix.values.contains(0))",
           "        #expect(matrix.pattern.vertexCount == %d)" % n,
           "        #expect(matrix.pattern.offsets == matrix.offsets && matrix.pattern.targets == matrix.columns)"]
    if 0 < n <= 8:
        out += ["        // Every entry through the subscript, 0 where nothing is stored.",
                "        let rows: [[Double]] = ["]
        for row in vals:
            out.append("            %s," % nums(row, per_line=99))
        out += ["        ]",
                "        for i in 0 ..< %d {" % n,
                "            for j in 0 ..< %d {" % n,
                "                #expect(abs(matrix[i, j] - rows[i][j]) <= 1e-12 * max(1, abs(rows[i][j])), \"entry (\\(i), \\(j))\")",
                "            }",
                "        }"]
    elif n > 8:
        tr = sum(vals[i][i] for i in range(n))
        tot = sum(x for row in vals for x in row)
        sq = sum(x * x for row in vals for x in row)
        out += ["        // The catalog's invariants: trace, Σ entries, Σ entries².",
                "        let trace = (0 ..< %d).reduce(0.0) { $0 + matrix[$1, $1] }" % n,
                "        #expect(abs(trace - %s) <= 1e-9 * max(1, %s))" % (num(tr), num(abs(tr))),
                "        #expect(abs(matrix.values.reduce(0, +) - %s) <= 1e-9 * max(1, %s))" % (num(tot), num(abs(sq))),
                "        #expect(abs(matrix.values.reduce(0) { $0 + $1 * $1 } - %s) <= 1e-9 * max(1, %s))" % (num(sq), num(sq))]
    return out


def spectrum_lines(vals, call_text):
    big = max([1.0] + [abs(x) for x in vals])
    return ["        let spectrum = %s" % call_text,
            "        let expected: [Double] = %s" % nums(vals),
            "        #expect(spectrum.count == expected.count)",
            "        #expect(zip(spectrum, spectrum.dropFirst()).allSatisfy { $0 <= $1 })",
            "        let tolerance = 1e-9 * %s" % num(big),
            "        for (k, value) in zip(spectrum, expected).enumerated() {",
            "            #expect(abs(value.0 - value.1) <= tolerance, \"eigenvalue \\(k)\")",
            "        }"]


def row_test(n):
    g, w, wr, call, name, v = raw(n)
    ce = call_expr(call, wr)
    lines = header(n) + ["    func sgt%03d() throws {" % n, comment(n)]
    lines += graph_lines(g)
    lines += weight_decl(wr)
    if name.endswith("Matrix"):
        lines.append("        let matrix = " + ce)
        lines += matrix_lines(g, v)
    elif name.endswith("Spectrum"):
        lines += spectrum_lines(v, ce)
    elif name == "algebraicConnectivity":
        lines.append("        let value = " + ce)
        if v == 0 and len(ref.components(g, w)) > 1:
            lines.append("        // Not connected: exactly 0, found by the components pass.")
            lines.append("        #expect(value == 0)")
        else:
            s = scale_of(g, w, name, call)
            lines.append("        // Iterative: 1e-6 · max(1, scale), scale = %s, the largest eigenvalue." % num(s))
            lines.append("        #expect(abs(value - %s) <= 1e-6 * %s)" % (num(v), num(s)))
    elif name == "fiedlerVector":
        lines += fiedler_lines(g, w, call, v, ce)
    elif name == "spectralOrdering":
        lines += ordering_lines(g, w, call, v, ce)
    elif name == "spectralRadius":
        lines.append("        let value = " + ce)
        if g.m == 0:
            lines.append("        #expect(value == 0)")
        else:
            s = max(1.0, v)
            lines.append("        #expect(abs(value - %s) <= 1e-6 * %s)" % (num(v), num(s)))
    elif name == "numberOfSpanningTrees":
        lines.append("        let count = " + ce)
        x = float(v)
        if x == 0:
            lines.append("        #expect(count == 0)")
        else:
            if wr is None and v < 2 ** 53:
                lines.append("        // Unweighted below 2⁵³: rounded to an integer.")
                lines.append("        #expect(count == count.rounded())")
            if isinstance(v, Fraction) and v.denominator == 1 and v > 2 ** 53:
                lines.append("        // Exactly %d." % v)
            lines.append("        #expect(abs(count - %s) <= 1e-9 * %s)" % (num(x), num(max(1.0, x))))
    elif name == "resistanceDistance":
        lines.append("        let value = " + ce)
        if v is None:
            lines.append("        #expect(value == nil)")
        elif v == 0:
            lines.append("        #expect(value == 0)")
        else:
            x = float(v)
            lines.append("        let resistance = try #require(value)")
            lines.append("        // %s" % ref.fnum(v))
            lines.append("        #expect(abs(resistance - %s) <= 1e-6 * %s)" % (num(x), num(max(1.0, x))))
    elif name in ("effectiveGraphResistance", "kemenyConstant"):
        lines.append("        let value = " + ce)
        if v is None:
            lines.append("        #expect(value == nil)")
        elif v == 0:
            lines.append("        #expect(value == 0)")
        else:
            x = float(v)
            lines.append("        let result = try #require(value)")
            if isinstance(v, Fraction):
                lines.append("        // %s" % ref.fnum(v))
            lines.append("        #expect(abs(result - %s) <= 1e-9 * %s)" % (num(x), num(max(1.0, abs(x)))))
    else:
        raise AssertionError(name)
    lines.append("    }")
    if not any(re.search(r"(^|[^A-Za-z])try ", l) for l in lines):
        lines[1] = lines[1].replace("() throws {", "() {")
    return lines


def null_vector(g, w, normalized):
    if normalized:
        d = [float(x) for x in ref.degrees(ref.adjacency(g, w))]
        z = [x ** 0.5 for x in d]
    else:
        z = [1.0] * g.n
    s = sum(x * x for x in z) ** 0.5
    return [x / s for x in z]


def fiedler_lines(g, w, call, v, ce):
    normalized = "normalized" in call
    mname = "normalizedLaplacianMatrix" if normalized else "laplacianMatrix"
    if v is None:
        return ["        #expect(%s == nil)" % ce]
    s = scale_of(g, w, "fiedlerVector", call)
    wcall = "weight: { weights[$0] }" if "weight" in call else ""
    mcall = "graph.%s(%s)" % (mname, wcall)
    out = ["        let fiedler = try #require(%s)" % ce]
    if v[0] == "degenerate":
        lam, k = v[1], v[2]
        spec = "graph.%s(%s)" % ("normalizedLaplacianSpectrum" if normalized else "laplacianSpectrum", wcall)
        z = null_vector(g, w, normalized)
        out += ["        // Degenerate: λ₂ = %s with multiplicity %d. Only invariants are pinned." % (num(lam), k),
                "        let scale: Double = %s" % num(s),
                "        #expect(abs(fiedler.algebraicConnectivity - %s) <= 1e-6 * scale)" % num(lam),
                "        #expect(%s.filter { abs($0 - %s) <= 1e-6 * scale }.count == %d)" % (spec, num(lam), k),
                "        let x = fiedler.values",
                "        #expect(x.count == %d)" % g.n,
                "        #expect(abs(x.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)"]
        if normalized:
            out += ["        let null: [Double] = %s" % nums(z),
                    "        #expect(abs(zip(x, null).reduce(0) { $0 + $1.0 * $1.1 }) <= 1e-6)"]
        else:
            out.append("        #expect(abs(x.reduce(0, +)) <= 1e-6)")
        out += ["        let mx = %s * x" % mcall,
                "        let residual = zip(mx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }",
                "        #expect(residual.squareRoot() <= 1e-6 * scale)",
                "        let rayleigh = zip(mx, x).reduce(0) { $0 + $1.0 * $1.1 }",
                "        #expect(abs(rayleigh - %s) <= 1e-6 * scale)" % num(lam)]
        return out
    lam, x = v
    out += ["        // λ₂ to 1e-6 · max(1, scale), scale = %s; entries to 1e-5, canonical sign." % num(s),
            "        #expect(abs(fiedler.algebraicConnectivity - %s) <= 1e-6 * %s)" % (num(lam), num(s)),
            "        let expected: [Double] = %s" % nums(x),
            "        #expect(fiedler.values.count == expected.count)",
            "        for (k, value) in zip(fiedler.values, expected).enumerated() {",
            "            #expect(abs(value.0 - value.1) <= 1e-5, \"entry \\(k)\")",
            "        }",
            "        #expect(abs(fiedler.values.reduce(0) { $0 + $1 * $1 } - 1) <= 1e-9)",
            "        for (i, vertex) in graph.vertices.enumerated() {",
            "            #expect(fiedler.value(of: vertex) == fiedler.values[i] && fiedler.value(ofIndex: i) == fiedler.values[i])",
            "        }"]
    return out


def ordering_lines(g, w, call, v, ce):
    order, tied = v
    names = [g.vertices[i] for i in order]
    if not tied:
        return ["        #expect(%s == %s)" % (ce, ints(names))]
    comps = ref.components(g, w)
    assert len(comps) == 1, "ties rows are connected"
    f = ref.fiedler(g, w, "normalized" in call)
    assert f[0] != "degenerate"
    x = f[1]
    xs = [x[g.vertices.index(name)] for name in names]
    return ["        let order = " + ce,
            "        // Ties: the order relies on the tie rule, so it is checked against the returned",
            "        // Fiedler vector, and against the catalog list wherever the model's entries differ by",
            "        // more than 1e-4.",
            "        let catalog = %s" % ints(names),
            "        #expect(order.sorted() == catalog.sorted())",
            "        let fiedler = try #require(graph.fiedlerVector())",
            "        for (a, b) in zip(order, order.dropFirst()) {",
            "            #expect(fiedler.value(of: a) <= fiedler.value(of: b) + 1e-6, \"\\(a) before \\(b)\")",
            "        }",
            "        let model: [Double] = %s" % nums(xs),
            "        let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })",
            "        for i in catalog.indices {",
            "            for j in catalog.indices where j > i && model[j] - model[i] > 1e-4 {",
            "                #expect(position[catalog[i]]! < position[catalog[j]]!, \"\\(catalog[i]) before \\(catalog[j])\")",
            "            }",
            "        }"]


# ---------------------------------------------------------------------------------------------
# Traps: the fault in a child process, then the same setup without it
# ---------------------------------------------------------------------------------------------
# Each trap row's call without the fault, and what it answers.
WITHOUT = {
    32: ("weights", "[Int]", "[1, 2]", "        #expect(graph.laplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)"),
    33: ("weights", "[Double]", "[1, 2]", "        #expect(graph.laplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)"),
    34: ("weights", "[Double]", "[1, 2]", "        #expect(graph.laplacianMatrix(weight: { weights[$0] }).nonzeroCount == 7)"),
    35: ("weights", "[Double]", "[1, 2]", "        #expect(graph.adjacencyMatrix(weight: { weights[$0] }).nonzeroCount == 4)"),
    84: ("weights", "[Int]", "[1, 1]", "        #expect(graph.laplacianSpectrum(weight: { weights[$0] }).count == 3)"),
    106: ("graph", None, None, "        #expect(abs(graph.algebraicConnectivity() - 2) <= 1e-6 * 2)"),
    107: ("graph", None, None, "        #expect(abs(graph.algebraicConnectivity() - 2) <= 1e-6 * 2)"),
    126: ("graph", None, None, "        #expect(graph.fiedlerVector()?.values.count == 2)"),
    183: ("call", None, None, "        #expect(graph.resistanceDistance(from: 0, to: 2).map { abs($0 - 2) <= 1e-6 * 2 } == true)"),
    184: ("weights", "[Int]", "[1, 1]", "        #expect(graph.resistanceDistance(from: 0, to: 2, weight: { weights[$0] }).map { abs($0 - 2) <= 1e-6 * 2 } == true)"),
    210: ("call", None, None, "        #expect(graph.numberOfSpanningTrees(root: 0) == 1)"),
}


def trap_test(n):
    _, group, case, cell, op, expected = ROWS[n]
    g = ref.parse_graph(cell)
    wr = ref.parse_weights(op)
    call = op.split(" [")[0].strip()
    ce = call_expr(call, wr)
    lines = header(n) + ["    func sgt%03d() async {" % n, comment(n),
                         "        await #expect(processExitsWith: .failure) {"]
    lines += graph_lines(g, ind="            ")
    lines += weight_decl(wr, ind="            ")
    lines.append("            _ = " + ce)
    lines.append("        }")
    kind, t, good, check = WITHOUT[n]
    if kind == "weights":
        lines.append("        // Without the fault: the same graph with valid weights.")
        lines += graph_lines(g)
        lines.append("        let weights: %s = %s" % (t, good))
    elif kind == "graph":
        lines.append("        // Without the fault: the same call on two vertices joined by an edge.")
        lines += graph_lines(ref.parse_graph("U: K(2)"))
    else:
        lines.append("        // Without the fault: the same graph and a vertex.")
        lines += graph_lines(g)
    lines.append(check)
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Phase 2 (behind --phase2)
# ---------------------------------------------------------------------------------------------

def phase2_test(n):
    if is_trap(n):
        return trap_test(n)
    g, w, wr, call, name, v = raw(n)
    ce = call_expr(call, wr)
    lines = header(n) + ["    func sgt%03d() throws {" % n, comment(n)]
    lines += graph_lines(g)
    lines += weight_decl(wr)
    if name == "numberOfSpanningTrees":
        lines.append("        let count = " + ce)
        lines.append("        #expect(abs(count - %s) <= 1e-9 * %s)" % (num(v), num(max(1, float(v)))))
    elif name.endswith("Spectrum"):
        lines += spectrum_lines(v, ce)
    elif name == "spectralBisection":
        if v is None:
            lines.append("        #expect(%s == nil)" % ce)
        elif v[0] == "degenerate":
            lines += ["        let split = try #require(%s)" % ce,
                      "        let fiedler = try #require(graph.fiedlerVector())",
                      "        let all = (split.negative + split.nonnegative).sorted()",
                      "        #expect(all == Array(graph.vertices).sorted())",
                      "        #expect(split.negative.allSatisfy { fiedler.value(of: $0) < 0 })",
                      "        #expect(split.nonnegative.allSatisfy { fiedler.value(of: $0) >= -1e-6 })"]
        else:
            lines.append("        let split = try #require(%s)" % ce)
            lines.append("        #expect(split.negative == %s && split.nonnegative == %s)" % (ints(v[0]), ints(v[1])))
    lines.append("    }")
    if not any(re.search(r"(^|[^A-Za-z])try ", l) for l in lines):
        lines[1] = lines[1].replace("() throws {", "() {")
    return lines


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, PHASE2_FIRST) if ROWS[n][1] in groups and not is_trap(n)]


TRAPS = [n for n in range(1, PHASE2_FIRST) if is_trap(n)]
FILES = [
    ("SpectralMatrixTests.swift", "SpectralGraphTheory matrices", ids("Matrices"),
     "Matrices (catalog SGT-001 – SGT-046): A with an undirected loop adding 2, L = D − A with loops\n"
     "// cancelling, N and L_rw with zero rows at degree 0, Q = D + A; parallel edges and weights adding\n"
     "// up, weight 0 storing nothing, rows in `vertices` order; directed A and L over out-degrees. Each\n"
     "// matrix is pinned as its exact CSR arrays, its stored values, every entry (n ≤ 8) and `pattern`."),
    ("SpectrumTests.swift", "SpectralGraphTheory spectra", ids("Spectra"),
     "Spectra (catalog SGT-047 – SGT-083): every eigenvalue of A, L and N, ascending, multiplicities\n"
     "// repeated, on the named families, multigraphs, loops and weights."),
    ("AlgebraicConnectivityTests.swift", "SpectralGraphTheory algebraic connectivity", ids("Algebraic connectivity"),
     "Algebraic connectivity (catalog SGT-085 – SGT-105): λ₂ of L, or of N with `normalized: true`; 0\n"
     "// when not connected (weight-0 edges do not connect)."),
    ("FiedlerVectorTests.swift", "SpectralGraphTheory Fiedler vector", ids("Fiedler vector"),
     "Fiedler vector (catalog SGT-108 – SGT-125): every entry where λ₂ is simple, with the canonical\n"
     "// sign (the first entry of magnitude at least 1e-4 of the largest is positive); only invariants\n"
     "// where λ₂ is multiple; nil when not connected."),
    ("SpectralOrderingTests.swift", "SpectralGraphTheory spectral ordering", ids("Spectral ordering"),
     "Spectral ordering (catalog SGT-127 – SGT-134): components by least vertex index, components of at\n"
     "// most two vertices in index order, larger ones by their Fiedler vector with ties in index order."),
    ("SpectralRadiusTests.swift", "SpectralGraphTheory spectral radius", ids("Spectral radius"),
     "Spectral radius (catalog SGT-135 – SGT-147): max |λ(A)|, 0 without edges."),
    ("SpanningTreeCountTests.swift", "SpectralGraphTheory spanning tree counts", ids("Spanning trees"),
     "Spanning tree counts (catalog SGT-148 – SGT-168): Kirchhoff's theorem, loops never on a tree,\n"
     "// parallel edges each counted, weights multiplied; 0 when not connected or empty, 1 for one vertex."),
    ("ResistanceTests.swift", "SpectralGraphTheory resistance", ids("Resistance distance", "Effective graph resistance"),
     "Resistance distance and effective graph resistance (catalog SGT-169 – SGT-193): weights are\n"
     "// conductances; 0 from a vertex to itself; nil across components."),
    ("KemenyConstantTests.swift", "SpectralGraphTheory Kemeny constant", ids("Kemeny constant"),
     "Kemeny constant (catalog SGT-194 – SGT-204): Σ 1/μᵢ over N's nonzero eigenvalues, a loop counted\n"
     "// twice in the degree; nil when not connected, 0 for zero or one vertex."),
    ("SpectralPreconditionTests.swift", "SpectralGraphTheory preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the fault, so the trap is the fault's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]
if PHASE2:
    FILES.append(("SpectralPhase2Tests.swift", "SpectralGraphTheory phase 2", list(range(PHASE2_FIRST, N + 1)),
                  "Phase 2 (catalog SGT-205 – SGT-217): directed arborescence counts, the signless spectrum and\n"
                  "// spectral bisection. Written only with --phase2."))


def write(fname, suite, rows, comment_text):
    if fname == "SpectralPhase2Tests.swift":
        tests = [phase2_test(n) for n in rows]
    else:
        tests = [trap_test(n) if is_trap(n) else row_test(n) for n in rows]
    if fname == "SpectralPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    imports = ["GrafluentTestSupport", "GraphProtocols", "SpectralGraphTheory", "Testing"]
    text = "\n".join(body)
    for module, needle in (("AdjacencyListModule", "AdjacencyList"), ("CompressedSparseRowModule", "CompressedSparseRow("),
                           ("AdjacencyMatrixModule", "AdjacencyMatrix("), ("Multigraphs", "Pseudograph<")):
        if needle in text:
            imports.append(module)
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "SpectralPreconditionTests.swift" else ""
    out = ["// " + comment_text, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname, suite, rows, comment_text in FILES:
    k = write(fname, suite, rows, comment_text)
    print(fname, k)
    total += k
    rows_total += len(rows)
assert rows_total == (N if PHASE2 else PHASE2_FIRST - 1), rows_total
print("catalog rows", rows_total, "tests", total)
