"""Writes the catalog-row test files of Tests/CommunityDetectionTests from cases.md.

Every value is re-evaluated with ref.py's model (api.md in index space) and written at full
precision (repr of the double); the catalog cells are the same values rounded to 12 digits, and
this script asserts that they agree.

Run: uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 swiftgen.py [OUT_DIR]
(default OUT_DIR: Tests/CommunityDetectionTests)
"""

import math
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ref  # noqa: E402

OUT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else HERE.parent.parent / "CommunityDetectionTests"
PARTS = HERE / "parts"

SECTIONS = {
    "A": ("DegenerateGraphTests.swift", "Degenerate graphs", "CommunityDegenerateGraphTests"),
    "B": ("ModularityTests.swift", "Modularity", "ModularityTests"),
    "C": ("PartitionQualityTests.swift", "Partition quality", "PartitionQualityTests"),
    "D": ("LouvainTests.swift", "Louvain", "LouvainTests"),
    "E": ("GreedyModularityTests.swift", "Greedy modularity (Clauset–Newman–Moore)", "GreedyModularityTests"),
    "F": ("LabelPropagationTests.swift", "Label propagation", "LabelPropagationTests"),
    "G": ("CommunityDetectionPreconditionTests.swift", "Community detection preconditions", "CommunityDetectionPreconditionTests"),
}

HEADERS = {
    "A": """// §A: the empty graph (both kinds), one vertex, four isolated vertices, lone self-loops, K₂ and one
// arc: every entry point. m = 0 gives modularity 0 (NetworkX; igraph NaN); coverage and performance
// are NaN where their ratio is 0/0; every algorithm returns singletons on an edgeless graph, and
// self-loops never join two vertices (Louvain, greedy) and vote for nothing (label propagation).""",
    "B": """// §B: Newman–Girvan modularity with Reichardt–Bornholdt's resolution γ on `Graph` (an undirected
// self-loop is A_vv = 2w, parallel edges add), Leicht–Newman on `DirectedGraph` (a directed loop is one
// out- and one in-arc), weights by edge position, empty communities, community order, `connectedComponents()`
// as a partition, and labeled vertices.""",
    "C": """// §C: coverage (edges inside communities over edges, parallel copies each counted, a loop inside) and
// performance (vertex pairs classified correctly over pairs: adjacency is "at least one edge", loops
// are not pairs, ordered pairs on `DirectedGraph`). Each test checks both members of the result.""",
    "D": """// §D: Louvain (Blondel et al.) with NetworkX's arithmetic and stop rule: vertices in index order,
// a vertex stays when its own community ties the best gain, other ties go to the greatest community
// label; parallel edges are weight, self-loops count in degrees; the Dugué–Perez gain on
// `DirectedGraph`; `resolution`, `threshold`, weights, and `using:` on graphs where every order gives
// the same partition (CD-112 – CD-114). CD-174 (total weight 0, not a trap) is here too.""",
    "E": """// §E: greedy modularity (Clauset–Newman–Moore): merge the adjacent pair of greatest ΔQ while ΔQ ≥ 0,
// ties to the least pair (i, j) with i merged into j, NetworkX's `greedy_modularity_communities`;
// `resolution`, weights, parallel edges, loops and `DirectedGraph`. CD-173 (total weight 0, not a
// trap) is here too.""",
    "F": """// §F: label propagation on `Graph`. Semi-synchronous (Cordasco–Gargano, NetworkX's deterministic
// rules: a greedy largest-degree-first coloring, classes updated in color order) and asynchronous
// (Raghavan et al.: vertices in index order, ties to the greatest label; `using:` where every order and
// tie choice gives the same partition). Votes are the row: parallel copies each vote, self-loops vote
// for nothing, weights add.""",
    "G": """// Preconditions, as exit tests. The catalog's trap rows (CD-155 – CD-172): a collection that is not
// a partition of the vertices (a vertex missing, listed twice, or not a vertex), a resolution that is
// negative or NaN, a threshold that is negative or NaN, and weights that are negative, NaN or
// infinite, on every entry point that takes them; then api.md's other preconditions (see the second
// half of this file). Each exit test builds its inputs inside the closure.""",
}

COMMON = """// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); scalars compare within 1e-12 relative to max(1, |value|), partitions
// exactly, in canonical order (communities by least vertex number, each in `vertices` order). Every
// partition row also checks `count`, `community(of:)` against membership, `community(ofIndex:)`
// against `community(of:)`, and the modularity of the result (at the call's weight and resolution)
// against ref.py's; undirected rows of the measures, Louvain and greedy modularity also run on
// `graph.directed` (the same values). Case IDs (CD-nnn) refer to the catalog; see README.md."""


# ----------------------------------------------------------------------------------------------
# Formatting
# ----------------------------------------------------------------------------------------------


def fnum(x):
    if isinstance(x, int):
        return str(x)
    if x != x:
        return ".nan"
    if math.isinf(x):
        return ".infinity" if x > 0 else "-.infinity"
    if x == int(x) and abs(x) < 1e15:
        return str(int(x)) if x != 0 or math.copysign(1, x) > 0 else "-0.0"
    return repr(x)


def vlit(v):
    return f'"{v}"' if isinstance(v, str) else str(v)


def vtype(g):
    return "String" if any(isinstance(v, str) for v in g.vertices) else "Int"


def wrap_list(items, indent, prefix, suffix, width=110):
    """`prefix` + items joined + `suffix`, wrapped at `width` with continuation lines indented."""
    one = prefix + ", ".join(items) + suffix
    if len(indent) + len(one) <= width:
        return [indent + one]
    lines, cur = [], indent + prefix
    for i, it in enumerate(items):
        piece = it + ("," if i < len(items) - 1 else "")
        if len(cur) + len(piece) + 1 > width and cur.strip() not in ("", prefix.strip()):
            lines.append(cur.rstrip())
            cur = indent + "    " + piece + " "
        else:
            cur += piece + " "
    cur = cur.rstrip() + suffix
    lines.append(cur)
    return lines


def plit(groups, vt):
    """A partition literal."""
    return "[" + ", ".join("[" + ", ".join(vlit(v) for v in c) + "]" for c in groups) + "]"


def partition_lines(name, groups, vt, indent):
    items = ["[" + ", ".join(vlit(v) for v in c) + "]" for c in groups]
    return wrap_list(items, indent, f"let {name}: [[{vt}]] = [", "]")


def swift_string(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def short(s, n=70):
    s = re.sub(r"\[(?:[^\[\]]|\[[^\[\]]*\])*\]", lambda m: m.group(0) if len(m.group(0)) <= 40 else "[…]", s)
    return s if len(s) <= n else s[: n - 1] + "…"


# ----------------------------------------------------------------------------------------------
# Graphs
# ----------------------------------------------------------------------------------------------


def graph_lines(cell, g, indent, kind=None):
    """Swift lines building the catalog graph on the reference conformers as `graph`."""
    vt = vtype(g)
    directed = g.directed
    conformer = kind or ("ReferenceDirectedMultigraph" if directed else "ReferencePseudograph")
    edge = "DirectedEdge(from: $0.0, to: $0.1)" if directed else "UndirectedEdge($0.0, $0.1)"
    out = [f"{indent}// {cell.strip().strip('`')}"]
    vs = g.vertices
    if vs == list(range(len(vs))):
        vexpr = f"0 ..< {len(vs)}"
    else:
        vexpr = None
    if g.m == 0 and not vs:
        out.append(f"{indent}let graph = {conformer}<{vt}>(vertices: [], edges: [])")
        return out
    pairs = [f"({vlit(vs[a])}, {vlit(vs[b])})" for a, b in g.ends]
    out += wrap_list(pairs, indent, f"let pairs: [({vt}, {vt})] = [", "]")
    if vexpr is None:
        out += wrap_list([vlit(v) for v in vs], indent, f"let listed: [{vt}] = [", "]")
        vexpr = "listed"
    out.append(f"{indent}let graph = {conformer}(vertices: {vexpr}, edges: pairs.map {{ {edge} }})")
    return out


# ----------------------------------------------------------------------------------------------
# Rows
# ----------------------------------------------------------------------------------------------


def parse_rows():
    rows, sec = [], None
    for line in ref.CASES.read_text().splitlines():
        m = re.match(r"## ([A-G])\. ", line)
        if m:
            sec = m.group(1)
        m = re.match(r"\| (CD-\d+) \| (.*?) \| `(.*?)` \| `(.*?)` \| (.*?) \|(.*)\|$", line)
        if m:
            rows.append(dict(id=m.group(1), sec=sec, graph=m.group(2).strip(), op=m.group(3), exp=m.group(4),
                             tol=m.group(5).strip(), note=m.group(6).strip()))
    return rows


def weight_expr(spec, g, view):
    """(setup lines, closure text) for a `weight:` argument."""
    pos = "$0.position" if view else "$0"
    mm = re.fullmatch(r"e%(\d+)\+(\d+)", spec)
    if mm:
        return [], f"{{ Double({pos} % {mm.group(1)} + {mm.group(2)}) }}"
    ws = ref.parse_weights(spec, g.m)
    return [("w", [fnum(float(x)) for x in ws])], f"{{ w[{pos}] }}"


def call_args(a, g, view, skip=()):
    """(setup, argument text) in signature order: weight, resolution, threshold, using."""
    setup, args = [], []
    if "weight" in a and "weight" not in skip:
        s, clo = weight_expr(a["weight"], g, view)
        setup += s
        args.append(f"weight: {clo}")
    if "resolution" in a:
        args.append(f"resolution: {fnum(float(a['resolution']))}")
    if "threshold" in a:
        args.append(f"threshold: {fnum(float(a['threshold']))}")
    if "using" in a and "using" not in skip:
        args.append("using: &generator")
    return setup, ", ".join(args)


def setup_lines(setup, indent):
    out = []
    for name, vals in setup:
        out += wrap_list(vals, indent, f"let {name}: [Double] = [", "]")
    return out


def seed_of(a):
    return int(re.fullmatch(r"rng\((\d+)\)", a["using"]).group(1))


FUNC = {
    "modularity": "modularity",
    "partitionQuality": "quality",
    "louvainCommunities": "louvain",
    "greedyModularityCommunities": "greedy",
    "labelPropagationCommunities": "labelPropagation",
    "asynchronousLabelPropagationCommunities": "asynchronousLabelPropagation",
}


def close(indent, name, value, label=None):
    msg = f', "{label}"' if label else ""
    if value != value:
        return [f"{indent}#expect({name}.isNaN{msg})"]
    v = fnum(value)
    if value == 0:
        return [f"{indent}#expect(abs({name}) <= 1e-12{msg})"]
    return [f"{indent}#expect(abs({name} - {v}) <= 1e-12 * max(1, abs({v})){msg})"]


def model_q(g, a, labels, view=False):
    w = ref.weights_of(g, ref.parse_weights(a["weight"], g.m) if "weight" in a else None)
    return ref.modularity_model(g, w, labels, float(a.get("resolution", "1")))


def directed_eval(row):
    """The row's op run on graph.directed (ref.py `directed > op`)."""
    return ref.evaluate(row["graph"], "directed > " + row["op"])


def body_lines(row, indent, gname="graph", for_rep=False, rep_g=None, rep_eval=None):
    """Swift statements for one non-trap row. Returns (lines, uses_connectivity, uses_support)."""
    g, name, a, part, arg, got, kind, val = rep_eval or ref.evaluate(row["graph"], row["op"])
    if rep_g is not None:
        g = rep_g
    view, _, _, _, _ = ref.parse_op(row["op"])
    vt = vtype(g)
    lines = []
    uses_conn = False
    target = f"{gname}.directed" if view == "directed" else gname
    in_view = view == "directed"
    if name in ("modularity", "partitionQuality"):
        of = a["of"]
        if of == "components":
            lines.append(f"{indent}let communities = {gname}.connectedComponents()")
            uses_conn = True
        else:
            comms = ref.parse_partition(of)
            if comms:
                lines += partition_lines("communities", comms, vt, indent)
            else:
                lines.append(f"{indent}let communities: [[{vt}]] = []")
        setup, args = call_args(a, g, in_view)
        lines += setup_lines(setup, indent)
        args = ", " + args if args else ""
        if name == "modularity":
            lines.append(f"{indent}let value = {target}.modularity(of: communities{args})")
            lines += close(indent, "value", val)
            if not g.directed and view is None and not for_rep:
                dg, _, da, _, _, _, _, dval = directed_eval(row)
                dsetup, dargs = call_args(da, dg, True)
                # weights on graph.directed: the edge's weight through each arc's position
                ds, dclo = call_args(a, g, True)
                dargs = ", " + dclo if dclo else ""
                lines.append(f"{indent}let arcs = {gname}.directed.modularity(of: communities{dargs})")
                lines += close(indent, "arcs", dval, "graph.directed")
        else:
            lines.append(f"{indent}let quality = {target}.partitionQuality(of: communities)")
            lines += close(indent, "quality.coverage", val[0])
            lines += close(indent, "quality.performance", val[1])
            if not g.directed and view is None and not for_rep:
                dval = directed_eval(row)[7]
                lines.append(f"{indent}let arcs = {gname}.directed.partitionQuality(of: communities)")
                lines += close(indent, "arcs.coverage", dval[0], "graph.directed")
                lines += close(indent, "arcs.performance", dval[1], "graph.directed")
        return lines, uses_conn
    # A partition.
    setup, args = call_args(a, g, in_view)
    lines += setup_lines(setup, indent)
    if "using" in a:
        lines.append(f"{indent}var generator = SeededRandomNumberGenerator(seed: {seed_of(a)})")
    lines.append(f"{indent}let result = {target}.{name}({args})")
    groups = ref.canonical(val)
    vgroups = [[g.vertices[v] for v in c] for c in groups]
    q = model_q(g, a, val)
    qsetup, qargs = call_args({k: v for k, v in a.items() if k in ("weight", "resolution")}, g, in_view)
    qargs = ", " + qargs if qargs else ""
    if part == "count":
        lines.append(f"{indent}#expect(result.count == {len(groups)})")
        lines.append(f"{indent}#expect(result.reduce(0) {{ $0 + $1.count }} == {gname}.vertexCount)")
        lines.append(f"{indent}for (c, community) in result.enumerated() {{")
        lines.append(f"{indent}    for v in community {{")
        lines.append(f'{indent}        #expect(result.community(of: v) == c, "vertex \\(v)")')
        lines.append(f"{indent}    }}")
        lines.append(f"{indent}}}")
        return lines, uses_conn
    if part == "community":
        v = ref.vtok(arg)
        c = next(i for i, comm in enumerate(vgroups) if v in comm)
        lines.append(f"{indent}#expect(result.community(of: {vlit(v)}) == {c})")
        lines.append(f"{indent}#expect(result[{c}].contains({vlit(v)}))")
        lines.append(f"{indent}#expect(result.community(ofIndex: {g.vertices.index(v)}) == {c})")
        return lines, uses_conn
    if vgroups:
        lines += partition_lines("expected", vgroups, vt, indent)
    else:
        lines.append(f"{indent}let expected: [[{vt}]] = []")
    lines.append(f"{indent}#expect(result.map {{ Array($0) }} == expected)")
    lines.append(f"{indent}#expect(result.count == expected.count)")
    lines.append(f"{indent}for (c, community) in expected.enumerated() {{")
    lines.append(f"{indent}    for v in community {{")
    lines.append(f'{indent}        #expect(result.community(of: v) == c, "vertex \\(v)")')
    lines.append(f"{indent}    }}")
    lines.append(f"{indent}}}")
    lines.append(f"{indent}for (i, v) in {target}.vertices.enumerated() {{")
    lines.append(f'{indent}    #expect(result.community(ofIndex: i) == result.community(of: v), "index \\(i)")')
    lines.append(f"{indent}}}")
    lines.append(f"{indent}// The modularity of the result (ref.py's model).")
    lines.append(f"{indent}let q = {target}.modularity(of: result{qargs})")
    lines += close(indent, "q", q)
    if "using" in a:
        lines.append(f"{indent}var again = SeededRandomNumberGenerator(seed: {seed_of(a)})")
        lines.append(f"{indent}#expect({target}.{name}({args.replace('&generator', '&again')}) == result, \"the same seed again\")")
    elif not g.directed and view is None and name in ("louvainCommunities", "greedyModularityCommunities") and not for_rep:
        dval = directed_eval(row)[7]
        _, dargs = call_args(a, g, True)
        lines.append(f"{indent}let arcs = {gname}.directed.{name}({dargs})")
        if ref.canonical(dval) == groups:
            lines.append(f'{indent}#expect(arcs == result, "graph.directed")')
        else:
            dgroups = [[g.vertices[v] for v in c] for c in ref.canonical(dval)]
            lines += partition_lines("expectedArcs", dgroups, vt, indent)
            lines.append(f'{indent}#expect(arcs.map {{ Array($0) }} == expectedArcs, "graph.directed")')
    return lines, uses_conn


def row_title(row, g):
    cell = row["graph"].strip("`")
    kind, rest = cell.split(":", 1)
    view, _, _, _, _ = ref.parse_op(row["op"])
    op = row["op"]
    gtxt = f"{kind.strip()}({rest.strip()})"
    if view == "directed":
        op = re.sub(r"directed\s*>\s*", "", op)
        gtxt += ".directed"
    exp = row["exp"]
    exp = exp[1:] if exp.startswith("#") else exp
    exp = "NaN" if exp == "nan" else exp
    if exp == "trap":
        tail = "traps"
    elif len(exp) > 60:
        tail = f"is the catalog's partition ({exp.count('],') + 1 if exp != '[]' else 0} communities)"
    else:
        tail = f"is {exp}"
    title = f"{row['id']} {short(gtxt, 60)}.{short(op, 70)} {tail}"
    if row["note"]:
        title += f": {row['note']}"
    return swift_string(title)


def trap_test(row, indent):
    g, name, a, part, arg, got, kind, val = ref.evaluate(row["graph"], row["op"])
    assert got == "trap"
    num = row["id"][3:]
    lines = [f'{indent}@Test("{row_title(row, g)}")',
             f"{indent}func {FUNC[name]}{num}() async {{",
             f"{indent}    await #expect(processExitsWith: .failure) {{"]
    inner = indent + "        "
    lines += graph_lines(row["graph"], ref.parse_graph(row["graph"]), inner)
    if name in ("modularity", "partitionQuality"):
        comms = ref.parse_partition(a["of"])
        lines += partition_lines("communities", comms, vtype(g), inner)
        setup, args = call_args(a, g, False)
        lines += setup_lines(setup, inner)
        args = ", " + args if args else ""
        if name == "modularity":
            lines.append(f"{inner}_ = graph.modularity(of: communities{args})")
        else:
            lines.append(f"{inner}_ = graph.partitionQuality(of: communities)")
    else:
        setup, args = call_args(a, g, False)
        lines += setup_lines(setup, inner)
        lines.append(f"{inner}_ = graph.{name}({args})")
    lines += [f"{indent}    }}", f"{indent}}}"]
    return lines


def value_test(row, indent):
    g, name, a, part, arg, got, kind, val = ref.evaluate(row["graph"], row["op"])
    exp = row["exp"]
    assert ref.close_text(got, exp, 1e-12), (row["id"], got, exp)
    num = row["id"][3:]
    body, conn = body_lines(row, indent + "    ")
    head = [f'{indent}@Test("{row_title(row, g)}")', f"{indent}func {FUNC[name]}{num}() {{"]
    return head + graph_lines(row["graph"], ref.parse_graph(row["graph"]), indent + "    ") + body + [f"{indent}}}"], conn


def write_sections(rows):
    counts = {}
    for sec, (fname, title, struct) in SECTIONS.items():
        srows = [r for r in rows if r["sec"] == sec]
        if sec == "D":
            srows += [r for r in rows if r["id"] == "CD-174"]
        if sec == "E":
            srows += [r for r in rows if r["id"] == "CD-173"]
        if sec == "G":
            srows = [r for r in srows if r["exp"] == "trap"]
        tests, conn, uses_rng = [], False, False
        for r in srows:
            if r["exp"] == "trap":
                tests.append(trap_test(r, "    "))
            else:
                t, c = value_test(r, "    ")
                conn |= c
                tests.append(t)
            uses_rng |= "using:" in r["op"]
        header = HEADERS[sec] + "\n" + (COMMON if sec != "G" else "// Case IDs (CD-nnn) refer to the catalog; see README.md.")
        imports = ["CommunityDetection"] + (["Connectivity"] if conn else []) + ["GrafluentTestSupport", "GraphProtocols", "Testing"]
        tags = ", .tags(.precondition)" if sec == "G" else ""
        out = [header, ""] + [f"import {m}" for m in imports] + ["", f'@Suite("{title}"{tags})', f"struct {struct} {{"]
        for i, t in enumerate(tests):
            if i:
                out.append("")
            out += t
        part = {"G": "preconditions.swift.part", "E": "greedy.swift.part"}.get(sec)
        if part:
            out += ["", (PARTS / part).read_text().rstrip("\n")]
        out.append("}")
        (OUT / fname).write_text("\n".join(out) + "\n")
        counts[fname] = len(tests)
    return counts


# ----------------------------------------------------------------------------------------------
# Representations
# ----------------------------------------------------------------------------------------------


def is_simple(g, loops_ok=True):
    seen = set()
    for a, b in g.ends:
        if a == b and not loops_ok:
            return False
        k = (a, b) if g.directed else (min(a, b), max(a, b))
        if k in seen:
            return False
        seen.add(k)
    return True


def rewritten(g, symmetric=False):
    """The graph on 0..<n with arcs in row-major order (as CSR and AdjacencyMatrix store them), and
    each arc's original edge position."""
    arcs = {}
    for e, (a, b) in enumerate(g.ends):
        va, vb = g.vertices[a], g.vertices[b]
        arcs[(va, vb)] = e
        if symmetric:
            arcs[(vb, va)] = e
    order = sorted(arcs)
    n = len(g.vertices)
    ng = ref.G(True, list(range(n)), [(a, b) for a, b in order])
    return ng, order, [arcs[k] for k in order]


def rep_eval(row, ng, origin):
    """ref.py's model run on a rewritten graph, the row's weights carried along with their arcs."""
    view, name, a, part, arg = ref.parse_op(row["op"])
    a2 = dict(a)
    if "weight" in a:
        g0 = ref.parse_graph(row["graph"])
        ws = ref.parse_weights(a["weight"], g0.m)
        a2["weight"] = "[" + ", ".join(str(ws[e]) for e in origin) + "]"
    try:
        kind, val = ref.run(ng, name, a2)
    except ref.Trap:
        return None
    got = ref.present(ng, kind, val, part, arg)
    return ng, name, a2, part, arg, got, kind, val


def rep_body(row, indent, gname, ng, ev, by_arc):
    """Statements for one row on CSR / AdjacencyMatrix: the call with weights by arc."""
    g, name, a, part, arg, got, kind, val = ev
    lines = []
    wclo = None
    if "weight" in a:
        ws = ref.parse_weights(a["weight"], g.m)
        lines += wrap_list([fnum(float(x)) for x in ws], indent, "let w: [Double] = [", "]")
        if by_arc:
            lines.append(f"{indent}let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))")
            wclo = "{ weightOf[graph.edges[$0]]! }"
        else:
            wclo = "{ w[$0] }"
    args = []
    if wclo:
        args.append(f"weight: {wclo}")
    if "resolution" in a:
        args.append(f"resolution: {fnum(float(a['resolution']))}")
    if "threshold" in a:
        args.append(f"threshold: {fnum(float(a['threshold']))}")
    if "using" in a:
        lines.append(f"{indent}var generator = SeededRandomNumberGenerator(seed: {seed_of(a)})")
        args.append("using: &generator")
    argt = ", ".join(args)
    if name in ("modularity", "partitionQuality"):
        comms = ref.parse_partition(a["of"]) if a["of"] != "components" else None
        if comms is None:
            lines.append(f"{indent}let communities = {gname}.weaklyConnectedComponents()")
        else:
            lines += partition_lines("communities", comms, "Int", indent)
        if name == "modularity":
            extra = ", " + argt if argt else ""
            lines.append(f"{indent}let value = {gname}.modularity(of: communities{extra})")
            lines += close(indent, "value", val)
        else:
            lines.append(f"{indent}let quality = {gname}.partitionQuality(of: communities)")
            lines += close(indent, "quality.coverage", val[0])
            lines += close(indent, "quality.performance", val[1])
        return lines, comms is None
    lines.append(f"{indent}let result = {gname}.{name}({argt})")
    groups = ref.canonical(val)
    if part == "count":
        lines.append(f"{indent}#expect(result.count == {len(groups)})")
        return lines, False
    if part == "community":
        v = ref.vtok(arg)
        c = next(i for i, comm in enumerate(groups) if v in comm)
        lines.append(f"{indent}#expect(result.community(of: {v}) == {c})")
        return lines, False
    if groups:
        lines += partition_lines("expected", groups, "Int", indent)
    else:
        lines.append(f"{indent}let expected: [[Int]] = []")
    lines.append(f"{indent}#expect(result.map {{ Array($0) }} == expected)")
    lines.append(f"{indent}for v in {gname}.vertices {{")
    lines.append(f'{indent}    #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \\(v)")')
    lines.append(f"{indent}}}")
    w = ref.weights_of(g, ref.parse_weights(a["weight"], g.m) if "weight" in a else None)
    q = ref.modularity_model(g, w, val, float(a.get("resolution", "1")))
    qargs = ([f"weight: {wclo}"] if wclo else []) + ([f"resolution: {fnum(float(a['resolution']))}"] if "resolution" in a else [])
    qextra = ", " + ", ".join(qargs) if qargs else ""
    lines.append(f"{indent}let q = {gname}.modularity(of: result{qextra})")
    lines += close(indent, "q", q)
    return lines, False


def write_representations(rows):
    value_rows = [r for r in rows if r["exp"] != "trap" and r["sec"] in "ABCDEFG"]
    by_graph = {}
    for r in value_rows:
        by_graph.setdefault(r["graph"], []).append(r)
    tests, counts = [], {"UndirectedAdjacencyList": 0, "AdjacencyList": 0, "CompressedSparseRow": 0, "AdjacencyMatrix": 0}
    covered = {k: set() for k in counts}
    conn = False
    # Adjacency lists, built in written order: the catalog's numbering, rows and positions.
    for cell, rs in by_graph.items():
        g = ref.parse_graph(cell)
        if not is_simple(g):
            continue
        kind = "AdjacencyList" if g.directed else "UndirectedAdjacencyList"
        vt = vtype(g)
        ids = [r["id"] for r in rs]
        num = rs[0]["id"][3:]
        title = f"{', '.join(ids)} on {kind}: {short(cell.strip('`'), 60)}"
        lines = [f'    @Test("{swift_string(title)}")', f"    func {kind[0].lower() + kind[1:]}{num}() {{"]
        lines += graph_lines(cell, g, "        ", kind=kind)
        vs = ", ".join(vlit(v) for v in g.vertices)
        lines.append(f"        #expect(Array(graph.vertices) == [{vs}] as [{vt}])")
        for r in rs:
            lines.append("        do {")
            lines.append(f"            // {r['id']}: {r['op'] if len(r['op']) < 90 else short(r['op'], 90)}")
            body, c = body_lines(r, "            ", for_rep=True)
            conn |= c
            lines += body
            lines.append("        }")
        lines.append("    }")
        tests.append(lines)
        counts[kind] += 1
        covered[kind] |= set(ids)
    # CSR and the matrix: directed graphs on 0..<n, and undirected graphs without loops as symmetric
    # arcs, rewritten in row-major order; values recomputed by ref.py on the rewritten graph.
    for cell, rs in by_graph.items():
        g = ref.parse_graph(cell)
        if sorted(map(str, g.vertices)) != sorted(map(str, range(len(g.vertices)))) or vtype(g) != "Int":
            continue
        symmetric = not g.directed
        if symmetric and any(a == b for a, b in g.ends):
            continue
        if not is_simple(g):
            continue
        rs = [r for r in rs if ref.parse_op(r["op"])[1] in ("modularity", "partitionQuality", "louvainCommunities", "greedyModularityCommunities")
              and ref.parse_op(r["op"])[0] is None]
        if not rs:
            continue
        ng, order, origin = rewritten(g, symmetric)
        n = len(g.vertices)
        for kind in ("CompressedSparseRow", "AdjacencyMatrix"):
            ids = [r["id"] for r in rs]
            num = rs[0]["id"][3:]
            how = "as symmetric arcs" if symmetric else "arcs in row-major order"
            title = f"{', '.join(ids)} on {kind}, {how}: {short(cell.strip('`'), 60)}"
            lines = [f'    @Test("{swift_string(title)}")', f"    func {kind[0].lower() + kind[1:]}{num}() {{"]
            lines.append(f"        // {cell.strip('`')}" + (" (each edge as two arcs)" if symmetric else ""))
            if order:
                arcs = [f"({a}, {b})" for a, b in order]
                lines += wrap_list(arcs, "        ", "let arcs: [(Int, Int)] = [", "]")
                lines.append(f"        let graph = {kind}(vertexCount: {n}, edges: arcs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})")
                lines.append("        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })")
            else:
                lines.append(f"        let graph = {kind}(vertexCount: {n})")
            for r in rs:
                ev = rep_eval(r, ng, origin)
                if ev is None:
                    continue
                lines.append("        do {")
                lines.append(f"            // {r['id']}: {short(r['op'], 90)}")
                body, c = rep_body(r, "            ", "graph", ng, ev, kind == "AdjacencyMatrix")
                conn |= c
                lines += body
                lines.append("        }")
            lines.append("    }")
            tests.append(lines)
            counts[kind] += 1
            covered[kind] |= set(ids)
    header = """// The catalog rows on the package's representations (not a catalog section). Every row of §A – §F
// whose graph has no parallel edges is repeated on `UndirectedAdjacencyList` or `AdjacencyList`
// built in written order, so vertex order, rows and positions are the catalog's (the vertex order
// is asserted first) and the values are the same as on the reference conformers. The modularity,
// partition quality, Louvain and greedy rows of every graph on the vertices 0..<n without parallel
// edges are repeated on `CompressedSparseRow` and `AdjacencyMatrix`, whose rows are sorted and whose
// positions are row-major: directed graphs with their arcs in that order, undirected graphs without
// loops as symmetric digraphs (each edge as two arcs, the `DirectedGraph` entry points: Leicht–Newman
// modularity and the Dugué–Perez gain, which give the undirected values on a symmetric digraph).
// The arcs are asserted first; weights travel with their arcs, looked up by arc on the matrix,
// whose positions are not `Int`s. Those literals are ref.py's model on the rewritten graph (vertex
// numbering 0..<n, so the lcg rows' communities differ from the catalog's). One test per graph and
// representation, each row in its own `do` block. Case IDs (CD-nnn) refer to the catalog; see
// README.md."""
    imports = ["AdjacencyListModule", "AdjacencyMatrixModule", "CommunityDetection", "CompressedSparseRowModule"] + \
        (["Connectivity"] if conn else []) + ["GrafluentTestSupport", "GraphProtocols", "Testing"]
    out = [header, ""] + [f"import {m}" for m in imports] + ["", '@Suite("Community detection on every representation")', "struct CommunityDetectionRepresentationTests {"]
    for i, t in enumerate(tests):
        if i:
            out.append("")
        out += t
    out.append("}")
    (OUT / "CommunityDetectionRepresentationTests.swift").write_text("\n".join(out) + "\n")
    return counts, covered


def main():
    rows = parse_rows()
    assert len(rows) == 174
    counts = write_sections(rows)
    rc, covered = write_representations(rows)
    for k, v in counts.items():
        print(k, v)
    print("representations", sum(rc.values()), rc)
    for k, v in covered.items():
        print(k, len(v), sorted(v))


if __name__ == "__main__":
    main()
