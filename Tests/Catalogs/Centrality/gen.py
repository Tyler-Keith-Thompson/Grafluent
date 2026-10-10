"""Generate the catalog-row Swift files of Tests/CentralityTests from cases.md.

Every Expected literal is ref.py's model value at full precision (the limit for iterative rows),
required to agree with the catalog cell within 1e-11 (ref.py's own check). Representation literals
for CompressedSparseRow / AdjacencyMatrix (row-major arcs) are ref.py's model on the rewritten graph.

Run (from the repository root; OUTDIR defaults to Tests/CentralityTests):
    uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 Tests/Catalogs/Centrality/gen.py [OUTDIR]
"""

import math
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ref  # noqa: E402

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE.parent.parent / "CentralityTests"

ROWS = []
section = None
for line in ref.CASES.read_text().splitlines():
    m = re.match(r"## ([A-H])\. (.*)", line)
    if m:
        section = m.group(1)
    m = re.match(r"\| (CE-\d+) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \|(.*)\|$", line)
    if m:
        cid, gcell, op, expc, tolc, notes = (x.strip() for x in m.groups())
        ROWS.append(dict(cid=cid, g=gcell.strip("`"), op=op.strip("`"), exp=expc.strip("`"), tol=tolc, notes=notes, sec=section))

ITER = ref.ITERATIVE


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def num(x):
    if isinstance(x, float):
        if math.isnan(x):
            return ".nan"
        if math.isinf(x):
            return ".infinity" if x > 0 else "-.infinity"
        if x == 0:
            return "0"
        r = repr(x)
        return r[:-2] if r.endswith(".0") else r
    return str(x)


def lit(v):
    return f'"{v}"' if isinstance(v, str) else str(v)


def wrap(items, indent, width=104):
    one = "[" + ", ".join(items) + "]"
    if len(indent) + len(one) + 24 <= width:
        return one
    out, cur = [], ""
    for it in items:
        piece = it if not cur else cur + ", " + it
        if len(indent) + 4 + len(piece) + 1 > width and cur:
            out.append(cur + ",")
            cur = it
        else:
            cur = piece
    out.append(cur)
    inner = indent + "    "
    return "[\n" + "\n".join(inner + l for l in out) + "\n" + indent + "]"


def tol_value(row):
    return "1e-12" if row["tol"] == "exact" else row["tol"]


def short_list(vals):
    return "[" + ", ".join(f"{(0.0 if abs(v) < 1e-13 else v):.12g}" for v in vals) + "]"


def gdesc(cell):
    kind, rest = cell.split(":", 1)
    return f"{kind.strip()}({rest.strip()})"


def note_text(notes):
    n = notes.strip()
    if not n:
        return ""
    first = re.split(r"(?<=[.;])\s", n)[0].rstrip(".;")
    first = first.replace("`", "")
    return first if len(first) <= 90 else ""


def vertices_expr(labels):
    if labels == list(range(len(labels))):
        return f"0 ..< {len(labels)}" if labels else "[]"
    return "[" + ", ".join(lit(v) for v in labels) + "]"


def is_str(labels):
    return any(isinstance(v, str) for v in labels)


def build_graph(cell, indent, kind="reference"):
    """Swift lines that build `graph` for a catalog cell. kind: reference | list."""
    g = ref.parse_graph(cell)
    labels = g.vertices
    vt = "String" if is_str(labels) else "Int"
    lines = [f"// {cell}"]
    directed = g.directed
    pairs = [f"({lit(labels[a])}, {lit(labels[b])})" for a, b in g.ends]
    if directed:
        typ = "ReferenceDirectedMultigraph" if kind == "reference" else "AdjacencyList"
        mk = "DirectedEdge(from: $0.0, to: $0.1)"
    else:
        typ = "ReferencePseudograph" if kind == "reference" else "UndirectedAdjacencyList"
        mk = "UndirectedEdge($0.0, $0.1)"
    if not pairs:
        lines.append(f"let graph = {typ}<{vt}>(vertices: {vertices_expr(labels)}, edges: [])")
    else:
        lines.append(f"let pairs: [({vt}, {vt})] = " + wrap(pairs, indent))
        lines.append(f"let graph = {typ}(vertices: {vertices_expr(labels)}, edges: pairs.map {{ {mk} }})")
    return g, lines


ARG_ORDER = ["of", "weight", "alpha", "beta", "dampingFactor", "personalization", "normalized", "endpoints",
             "wfImproved", "tolerance", "maxIterations"]


def weight_decl(spec, m):
    w = ref.parse_weights(spec, m)
    m_ = re.fullmatch(r"e%(\d+)\+(\d+)", spec.strip())
    if m_:
        return w, f"let w = (0 ..< {m}).map {{ $0 % {m_.group(1)} + {m_.group(2)} }}"
    if any(isinstance(x, float) for x in w):
        return w, "let w: [Double] = [" + ", ".join(num(float(x)) for x in w) + "]"
    return w, "let w = [" + ", ".join(str(x) for x in w) + "]"


def call(name, a, view, weight_access=None, part=None):
    """The Swift call text and the declarations it needs."""
    decls, args = [], []
    target = "graph.directed" if view == "directed" else "graph"
    for k in ARG_ORDER:
        if k not in a:
            continue
        v = a[k]
        if k == "of":
            args.append(f"of: {lit(v)}")
        elif k == "weight":
            acc = weight_access or ("{ w[$0.position] }" if view == "directed" else "{ w[$0] }")
            args.append(f"weight: {acc}")
        elif k == "personalization":
            ps = [float(x) for x in ref.split_top(v[1:-1])]
            decls.append("let p: [Double] = [" + ", ".join(num(x) for x in ps) + "]")
            args.append("personalization: { p[$0] }")
        elif isinstance(v, bool):
            args.append(f"{k}: {'true' if v else 'false'}")
        else:
            args.append(f"{k}: {num(v)}")
    return target, decls, f"{name}({', '.join(args)})"


def other_args_without_of(a):
    return {k: v for k, v in a.items() if k != "of"}


def check_vector(lines, ind, result, expected, tol, target):
    lines.append(f"{ind}let expected: [Double] = " + wrap([num(float(x)) for x in expected], ind))
    lines.append(f"{ind}#expect({result}.scores.count == expected.count)")
    lines.append(f"{ind}for (i, value) in expected.enumerated() {{")
    lines.append(f"{ind}    let error = abs({result}.score(ofIndex: i) - value)")
    lines.append(f"{ind}    #expect(error <= {tol} * max(1, abs(value)), \"index \\(i)\")")
    lines.append(f"{ind}}}")
    lines.append(f"{ind}let byIndex = {result}.scores.indices.map {{ {result}.score(ofIndex: $0) }}")
    lines.append(f"{ind}#expect(byIndex == {result}.scores)")
    lines.append(f"{ind}let byVertex = {target}.vertices.map {{ {result}.score(of: $0) }}")
    lines.append(f"{ind}#expect(byVertex == {result}.scores)")


def emit_row_body(row, ind, kind="reference", override=None):
    """Body lines checking one row (graph already built). Returns (lines, throws)."""
    g = ref.parse_graph(row["g"])
    view, name, a, part = ref.parse_op(row["op"])
    _, _, _, _, exact, dflt = ref.evaluate(row["g"], row["op"]) if override is None else override
    lines, throws = [], False
    tol = tol_value(row)
    if "weight" in a:
        _, wd = weight_decl(a["weight"], g.m)
        lines.append(ind + wd)
    target, decls, text = call(name, a, view, part=part)
    lines += [ind + d for d in decls]
    iterative = name in ITER
    if name == "hits":
        text_full = f"{target}.{text}"
        if dflt is None:
            lines.append(f"{ind}#expect({text_full} == nil)")
            return lines, throws
        lines.append(f"{ind}let scores = try #require({text_full})")
        lines.append(f"{ind}let result = scores.{part}")
        throws = True
        check_vector(lines, ind, "result", exact, tol, target)
        other = "authorities" if part == "hubs" else "hubs"
        lines.append(f"{ind}let {other} = scores.{other}.scores")
        lines.append(f"{ind}#expect({other}.count == expected.count)")
        if g.n > 0:
            lines.append(f"{ind}// Each vector sums to 1 (api.md).")
            lines.append(f"{ind}let total = result.scores.reduce(0, +)")
            lines.append(f"{ind}#expect(abs(total - 1) <= 1e-12)")
            lines.append(f"{ind}let otherTotal = {other}.reduce(0, +)")
            lines.append(f"{ind}#expect(abs(otherTotal - 1) <= 1e-12)")
        return lines, throws
    if iterative and dflt is None:
        lines.append(f"{ind}#expect({target}.{text} == nil)")
        if view is None and not g.directed:
            lines.append(f"{ind}#expect(graph.directed.{call(name, a, 'directed')[2]} == nil)")
        return lines, throws
    if "of" in a:
        lines.append(f"{ind}let value = {target}.{text}")
        lines.append(f"{ind}let expected: Double = {num(float(exact))}")
        lines.append(f"{ind}let error = abs(value - expected)")
        lines.append(f"{ind}#expect(error <= {tol} * max(1, abs(expected)))")
        rest = other_args_without_of(a)
        _, _, full = call(name, rest, view)
        lines.append(f"{ind}let all = {target}.{full}")
        lines.append(f"{ind}let fromAll = all.score(of: {lit(a['of'])})")
        lines.append(f"{ind}let difference = abs(value - fromAll)")
        lines.append(f"{ind}#expect(difference <= {tol} * max(1, abs(expected)))")
        return lines, throws
    if iterative:
        lines.append(f"{ind}let result = try #require({target}.{text})")
        throws = True
    else:
        lines.append(f"{ind}let result = {target}.{text}")
    check_vector(lines, ind, "result", exact, tol, target)
    if g.n > 0 and name == "pageRank":
        lines.append(f"{ind}let total = result.scores.reduce(0, +)")
        lines.append(f"{ind}#expect(abs(total - 1) <= 1e-12, \"scores sum to 1\")")
    if g.n > 0 and (name == "eigenvectorCentrality" or (name == "katzCentrality" and a.get("normalized", True))):
        lines.append(f"{ind}let norm = result.scores.reduce(0) {{ $0 + $1 * $1 }}.squareRoot()")
        lines.append(f"{ind}#expect(abs(norm - 1) <= 1e-12, \"Euclidean norm 1\")")
    # One-vertex forms agree with the vector.
    if name in ("closenessCentrality", "harmonicCentrality"):
        lines.append(f"{ind}for v in {target}.vertices {{")
        _, _, one = call(name, dict(a, of="__V__"), view)
        one = one.replace('of: "__V__"', "of: v")
        lines.append(f"{ind}    let one = {target}.{one}")
        lines.append(f"{ind}    let difference = abs(one - result.score(of: v))")
        lines.append(f"{ind}    #expect(difference <= {tol} * max(1, abs(one)), \"vertex \\(v)\")")
        lines.append(f"{ind}}}")
    # graph.directed: the same values, or twice (degree; unnormalized betweenness).
    if view is None and not g.directed and kind != "skipview":
        twice = (name == "degreeCentrality" and g.n > 1) or (name == "betweennessCentrality" and a.get("normalized", True) is False)
        _, _, dtext = call(name, a, "directed")
        if iterative:
            lines.append(f"{ind}let arcs = try #require(graph.directed.{dtext})")
        else:
            lines.append(f"{ind}let arcs = graph.directed.{dtext}")
        factor = "2 * " if twice else ""
        lines.append(f"{ind}for (i, value) in expected.enumerated() {{")
        lines.append(f"{ind}    let error = abs(arcs.score(ofIndex: i) - {factor}value)")
        lines.append(f"{ind}    #expect(error <= {tol} * max(1, abs({factor}value)), \"graph.directed, index \\(i)\")")
        lines.append(f"{ind}}}")
    return lines, throws


def op_desc(row):
    return row["op"]


def exp_desc(row, exact):
    e = row["exp"]
    if len(e) <= 70:
        return e
    return f"{len(exact)} scores, {short_list(exact[:2])[:-1]}, …]"


FUNC_PREFIX = {
    "degreeCentrality": "degree", "inDegreeCentrality": "inDegree", "outDegreeCentrality": "outDegree",
    "closenessCentrality": "closeness", "harmonicCentrality": "harmonic", "betweennessCentrality": "betweenness",
    "eigenvectorCentrality": "eigenvector", "katzCentrality": "katz", "pageRank": "pageRank", "hits": "hits",
}


def test_for_row(row):
    view, name, a, part = ref.parse_op(row["op"])
    ev = ref.evaluate(row["g"], row["op"])
    exact = ev[4]
    num_id = row["cid"].split("-")[1]
    fname = FUNC_PREFIX[name] + num_id
    ind = "        "
    graphline = gdesc(row["g"])
    opd = row["op"]
    if opd.startswith("directed > "):
        graphline += ".directed"
        opd = opd[len("directed > "):]
    if "(" not in opd.split(".")[0]:
        base, _, rest = opd.partition(".")
        opd = base + "()" + ("." + rest if rest else "")
    note = note_text(row["notes"])
    title = f"{row['cid']} {graphline}.{opd} is {exp_desc(row, exact) if isinstance(exact, list) else row['exp']}"
    if note:
        title += f": {note}"
    _, glines = build_graph(row["g"], ind)
    body, throws = emit_row_body(row, ind)
    sig = f"func {fname}() throws {{" if throws else f"func {fname}() {{"
    out = [f'    @Test("{esc(title)}")', "    " + sig]
    out += [ind + l for l in glines]
    out += body
    out.append("    }")
    return "\n".join(out)


def trap_test(row):
    view, name, a, part = ref.parse_op(row["op"])
    num_id = row["cid"].split("-")[1]
    fname = FUNC_PREFIX[name] + num_id
    ind = "            "
    note = note_text(row["notes"])
    title = f"{row['cid']} {gdesc(row['g'])}.{row['op']} traps" + (f": {note}" if note else "")
    g, glines = build_graph(row["g"], ind)
    lines = [f'    @Test("{esc(title)}")', f"    func {fname}() async {{", "        await #expect(processExitsWith: .failure) {"]
    lines += [ind + l for l in glines]
    if "weight" in a:
        lines.append(ind + weight_decl(a["weight"], g.m)[1])
    target, decls, text = call(name, a, view)
    lines += [ind + d for d in decls]
    lines.append(f"{ind}_ = {target}.{text}")
    lines += ["        }", "    }"]
    return "\n".join(lines)


SECTIONS = {
    "A": ("DegenerateGraphTests.swift", "Degenerate graphs", "CentralityDegenerateGraphTests", [
        "§A: the empty graph (both kinds), K₁, three isolated vertices and K₂: every measure. The empty graph",
        "gives an empty result for every measure, iterative ones included (not nil: there is nothing to",
        "iterate); one vertex scores 1 for degree (NetworkX's rule) and 0 for closeness, harmonic and",
        "betweenness; edgeless graphs are uniform for eigenvector, Katz, PageRank and HITS (api.md).",
    ]),
    "B": ("DegreeCentralityTests.swift", "Degree", "DegreeCentralityTests", [
        "§B: degree(of: v)/(n − 1), so a self-loop counts 2 and each parallel copy counts (the score can",
        "exceed 1); directed: in + out, in, out, a directed loop one in-arc and one out-arc;",
        "`graph.directed` doubles the undirected value.",
    ]),
    "C": ("ClosenessHarmonicTests.swift", "Closeness and harmonic", "ClosenessHarmonicTests", [
        "§C: closeness with and without the Wasserman–Faust factor, harmonic (not normalized), incoming",
        "distances d(v, u) on directed graphs, `Int` and `Double` weights (zeros allowed), isolated",
        "vertices, loops and parallel copies changing no distance, and the one-vertex forms. Every vector",
        "row also checks each `closenessCentrality(of:)` / `harmonicCentrality(of:)` against the vector.",
    ]),
    "D": ("BetweennessTests.swift", "Betweenness", "BetweennessTests", [
        "§D: Brandes betweenness with NetworkX's rescaling (normalized, endpoints, directed ordered pairs),",
        "parallel edges as distinct shortest paths (edge sequences), self-loops on no path, `Int` and",
        "`Double` weights with ties by exact equality (CE-114).",
    ]),
    "E": ("EigenvectorTests.swift", "Eigenvector", "EigenvectorTests", [
        "§E: the principal eigenvector of Aᵀ by power iteration on A + I from the uniform start, Euclidean",
        "norm 1; an undirected loop is 2 in A, parallel copies add; disconnected graphs; nil on a DAG and",
        "with too few iterations.",
    ]),
    "F": ("KatzTests.swift", "Katz", "KatzTests", [
        "§F: x = αAᵀx + β1 from x₀ = 0, normalized to Euclidean norm 1 by default; nil when α ≥ 1/ρ(A).",
    ]),
    "G": ("PageRankTests.swift", "PageRank", "PageRankTests", [
        "§G: PageRank with the damping factor, dangling vertices following the personalization, each",
        "undirected edge two arcs and a loop two loop arcs, parallel arcs adding, weights per row; nil with",
        "too few iterations.",
    ]),
    "H": ("HITSTests.swift", "HITS", "HITSTests", [
        "§H: hubs and authorities from the uniform start, each summing to 1; the limit from the uniform",
        "start where σ₁ is not simple; parallel arcs adding; weights; `graph.directed` on the karate club",
        "(hubs = authorities); nil after one iteration. Each test also checks that the other vector has",
        "one score per vertex.",
    ]),
}

TOL_NOTE = [
    "Expected values are ref.py's model at full precision (the catalog cells are the same values",
    "rounded to 12 digits); non-iterative rows compare within 1e-12 relative to max(1, |value|), the",
    "iterative ones within the catalog's Tol of the limit. Undirected rows also run on",
    "`graph.directed` (the same values; twice for degree and unnormalized betweenness).",
    "Case IDs (CE-nnn) refer to the catalog; see README.md.",
]

counts = {}
traps = []
for sec, (fname, title, suite, header) in SECTIONS.items():
    rows = [r for r in ROWS if r["sec"] == sec]
    tests = []
    for r in rows:
        if r["exp"] == "trap":
            traps.append(r)
            continue
        tests.append(test_for_row(r))
    imports = ["import Centrality", "import GrafluentTestSupport", "import GraphProtocols", "import Testing"]
    text = "\n".join("// " + l for l in header + TOL_NOTE) + "\n\n" + "\n".join(imports) + "\n\n"
    text += f'@Suite("{title}")\nstruct {suite} {{\n' + "\n\n".join(tests) + "\n}\n"
    (OUT / fname).write_text(text)
    counts[fname] = len(tests)

# CentralityPreconditionTests.swift: a written header, the catalog's trap rows, then the
# preconditions api.md states beyond the catalog (handtraps.part, written by hand).
(OUT / "CentralityPreconditionTests.swift").write_text(
    (HERE / "preconditions_head.part").read_text()
    + "\n\n".join(trap_test(r) for r in traps)
    + "\n\n" + (HERE / "handtraps.part").read_text().rstrip("\n") + "\n}\n"
)
counts["traps"] = len(traps)


# ------------------------------------------------------------------------------------------
# Representations
# ------------------------------------------------------------------------------------------

def has_parallel(g):
    seen = set()
    for a, b in g.ends:
        k = (a, b) if g.directed else tuple(sorted((a, b)))
        if k in seen:
            return True
        seen.add(k)
    return False


def rowmajor_cell(g):
    """D: [0..n-1] arcs sorted by (source, target), and the permutation old position -> new."""
    order = sorted(range(g.m), key=lambda e: g.ends[e])
    arcs = ", ".join(f"{g.ends[e][0]}>{g.ends[e][1]}" for e in order)
    cell = f"D: [0..{g.n - 1}] {arcs}" if g.n else "D: []"
    return cell, order


rep_tests = []
by_graph = {}
for r in ROWS:
    if r["exp"] == "trap":
        continue
    by_graph.setdefault(r["g"], []).append(r)

rep_count = 0
for cell, rows in by_graph.items():
    g = ref.parse_graph(cell)
    if has_parallel(g):
        continue
    first = rows[0]["cid"].split("-")[1]
    ids = ", ".join(r["cid"] for r in rows)
    ind = "        "
    # Adjacency lists, built in written order: the catalog's values.
    kindname = "AdjacencyList" if g.directed else "UndirectedAdjacencyList"
    _, glines = build_graph(cell, ind, kind="list")
    lines = [f'    @Test("{esc(ids)} on {kindname}: {esc(cell)}")']
    body = []
    throws = False
    for r in rows:
        b, t = emit_row_body(r, ind + "    ")
        throws |= t
        body.append(f"{ind}do {{\n{ind}    // {r['cid']}: {r['op']}\n" + "\n".join(b) + f"\n{ind}}}")
    lines.append(f"    func {('adjacencyList' if g.directed else 'undirectedAdjacencyList')}{first}() {'throws ' if throws else ''}{{")
    lines += [ind + l for l in glines]
    labels = g.vertices
    lines.append(f"{ind}#expect(Array(graph.vertices) == [" + ", ".join(lit(v) for v in labels) + "])")
    lines += body
    lines.append("    }")
    rep_tests.append("\n".join(lines))
    rep_count += 1
    # CompressedSparseRow and AdjacencyMatrix: directed rows on 0..<n, arcs row-major.
    if g.directed and g.vertices == list(range(g.n)):
        rcell, order = rowmajor_cell(g)
        for rep in ("CompressedSparseRow", "AdjacencyMatrix"):
            lines = [f'    @Test("{esc(ids)} on {rep}, arcs in row-major order: {esc(cell)}")']
            body = []
            throws = False
            for r in rows:
                view, name, a, part = ref.parse_op(r["op"])
                op2 = r["op"]
                wdecl = None
                if "weight" in a:
                    w = ref.parse_weights(a["weight"], g.m)
                    w2 = [w[e] for e in order]
                    op2 = re.sub(r"weight: (\[[^\]]*\]|e%\d+\+\d+)", "weight: [" + ", ".join(repr(x) if isinstance(x, float) else str(x) for x in w2) + "]", op2)
                    if rep == "CompressedSparseRow":
                        wdecl = None
                    else:
                        wdecl = w2
                ev = ref.evaluate(rcell, op2)
                r2 = dict(r, g=rcell, op=op2)
                b, t = emit_row_body(r2, ind + "    ", override=ev)
                if rep == "AdjacencyMatrix" and "weight" in a:
                    b = [l.replace("weight: { w[$0] }", "weight: { w[arcs.firstIndex(of: graph.edges[$0])!] }") for l in b]
                    b.insert(1, f"{ind}    let arcs = pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}")
                throws |= t
                body.append(f"{ind}do {{\n{ind}    // {r['cid']}: {r['op']}" + (" (weights carried with their arcs)" if "weight" in a else "") + "\n" + "\n".join(b) + f"\n{ind}}}")
            pairs = [f"({g.ends[e][0]}, {g.ends[e][1]})" for e in order]
            fn = ("compressedSparseRow" if rep == "CompressedSparseRow" else "adjacencyMatrix") + first
            lines.append(f"    func {fn}() {'throws ' if throws else ''}{{")
            lines.append(f"{ind}// {rcell}")
            if pairs:
                lines.append(f"{ind}let pairs: [(Int, Int)] = " + wrap(pairs, ind))
                lines.append(f"{ind}let graph = {rep}(vertexCount: {g.n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})")
                lines.append(f"{ind}#expect(Array(graph.edges) == pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})")
            else:
                lines.append(f"{ind}let graph = {rep}(vertexCount: {g.n})")
            lines += body
            lines.append("    }")
            rep_tests.append("\n".join(lines))
            rep_count += 1

rep_header = [
    "The catalog rows on the package's representations (not a catalog section). Every row of §A – §H",
    "whose graph has no parallel edges is repeated on `UndirectedAdjacencyList` or `AdjacencyList`",
    "built in written order, so vertex order, rows and positions are the catalog's (the vertex order",
    "is asserted first) and the values are the same as on the reference conformers. Directed rows on",
    "the vertices 0..<n are repeated on `CompressedSparseRow` and `AdjacencyMatrix`, whose rows are",
    "sorted and whose positions are row-major: the arcs are rewritten in that order (asserted",
    "first) with the weights carried with their arcs, and those literals are ref.py's model on the",
    "rewritten graph (the same values as the catalog's up to rounding). The matrix's positions are not",
    "`Int`s, so its weights are looked up by arc. One test per graph and representation, each row in",
    "its own `do` block. Case IDs (CE-nnn) refer to the catalog; see README.md.",
]
text = "\n".join("// " + l for l in rep_header) + "\n\n"
text += "import AdjacencyListModule\nimport AdjacencyMatrixModule\nimport Centrality\nimport CompressedSparseRowModule\nimport GraphProtocols\nimport Testing\n\n"
text += '@Suite("Centrality on every representation")\nstruct CentralityRepresentationTests {\n' + "\n\n".join(rep_tests) + "\n}\n"
(OUT / "CentralityRepresentationTests.swift").write_text(text)
counts["CentralityRepresentationTests.swift"] = rep_count

for k, v in counts.items():
    print(k, v)
