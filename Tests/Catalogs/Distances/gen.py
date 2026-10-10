"""Generate the catalog-row Swift tests of Tests/DistancesTests from cases.md and ref.py.

Every Expected literal is the catalog cell; ref.py re-evaluates each row and the generator asserts
that it equals the cell. Representation rows on CompressedSparseRow (row-major positions) are
evaluated by ref.py on the rewritten graph.

Run (from the repository root; OUTDIR defaults to Tests/DistancesTests):
    uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 Tests/Catalogs/Distances/gen.py [OUTDIR]
"""

import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ref  # noqa: E402

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE.parent.parent / "DistancesTests"

lines, ROWS, ORDER = ref.read_rows(ref.CASES, "DI")

# ------------------------------------------------------------------------------------------------
# Swift literals
# ------------------------------------------------------------------------------------------------


def sv(v):
    return str(v) if isinstance(v, int) else f'"{v}"'


def swift_num(s):
    if s == "inf":
        return ".infinity"
    if s == "nan":
        return ".nan"
    return s


def is_double_text(s):
    return "." in s or s in ("inf", "nan") or "e-" in s


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


# ------------------------------------------------------------------------------------------------
# Graph construction
# ------------------------------------------------------------------------------------------------


def range_of(s):
    m = re.fullmatch(r"(-?\d+)\.\.(-?\d+)", s.strip())
    return (int(m.group(1)), int(m.group(2))) if m else None


def pair_parts(es, directed):
    """Swift expressions (each of type [(V, V)]) for an edge list, in written order."""
    parts, literal = [], []

    def flush():
        if literal:
            parts.append("[" + ", ".join(f"({sv(a)}, {sv(b)})" for a, b in literal) + "]")
            literal.clear()

    extra_vertices = None
    for t in ref.split_top(es):
        if t.startswith("P("):
            r = range_of(t[2:-1])
            if r and r[1] - r[0] >= 6:
                flush()
                parts.append(f"({r[0]} ..< {r[1]}).map {{ ($0, $0 + 1) }}")
            else:
                literal.extend(ref.edge_tokens(t)[1])
        elif t.startswith("C("):
            r = range_of(t[2:-1])
            if r and r[1] - r[0] >= 6:
                flush()
                parts.append(f"({r[0]} ..< {r[1]}).map {{ ($0, $0 + 1) }} + [({r[1]}, {r[0]})]")
            else:
                literal.extend(ref.edge_tokens(t)[1])
        elif t.startswith("S("):
            c, rest = t[2:-1].split(";")
            r = range_of(rest)
            if r and r[1] - r[0] >= 6:
                flush()
                parts.append(f"({r[0]} ... {r[1]}).map {{ ({c}, $0) }}")
            else:
                literal.extend(ref.edge_tokens(t)[1])
        elif t.startswith("K(") and t[2:-1].isdigit() and int(t[2:-1]) > 4:
            flush()
            n = int(t[2:-1])
            parts.append(f"(0 ..< {n}).flatMap {{ i in (i + 1 ..< {n}).map {{ (i, $0) }} }}")
        elif t.startswith("grid("):
            flush()
            r, c = (int(x) for x in t[5:-1].split(","))
            extra_vertices = f"0 ..< {r * c}"
            parts.append(
                f"(0 ..< {r * c}).flatMap {{ v -> [(Int, Int)] in (v % {c} + 1 < {c} ? [(v, v + 1)] : []) + (v / {c} + 1 < {r} ? [(v, v + {c})] : []) }}"
            )
        elif t.startswith("kary("):
            flush()
            n, k = (int(x) for x in t[5:-1].split(","))
            parts.append(f"(0 ..< {n}).flatMap {{ i -> [(Int, Int)] in ({k} * i + 1 ... {k} * i + {k}).filter {{ $0 < {n} }}.map {{ (i, $0) }} }}")
        elif t.startswith("nx("):
            flush()
            nodes, pairs = ref.nx_named(t[3:-1])
            assert nodes == list(range(len(nodes)))
            extra_vertices = f"0 ..< {len(nodes)}"
            literal.extend(pairs)
            flush()
        else:
            literal.extend(ref.edge_tokens(t)[1])
    flush()
    return parts, extra_vertices


def wrap_literal(expr, indent):
    """Wrap a long `[(a, b), …]` literal over lines of at most ~110 characters."""
    if len(expr) + indent < 110 or not expr.startswith("[("):
        return expr
    items = re.findall(r"\([^()]*\)", expr)
    out, cur = [], ""
    pad = " " * (indent + 4)
    for it in items:
        piece = it + ", "
        if len(pad) + len(cur) + len(piece) > 110:
            out.append(pad + cur.rstrip())
            cur = ""
        cur += piece
    out.append(pad + cur.rstrip().rstrip(","))
    return "[\n" + "\n".join(out) + "\n" + " " * indent + "]"


def vertices_arg(listed):
    if not listed.strip():
        return None
    r = range_of(listed) if "," not in listed else None
    if r:
        return f"{r[0]} ... {r[1]}"
    return "[" + ", ".join(sv(x) for x in ref.items(listed)) + "]"


def build(cell, kind="reference", indent=8):
    """Swift lines that build `graph` for a catalog cell. kind: reference, reversed, ual, al."""
    cell = cell.strip("`")
    rev = cell.endswith("~rev")
    if rev:
        cell = cell[: -len("~rev")].strip()
    k, rest = cell.split(":", 1)
    directed = k.strip() == "D"
    m = re.match(r"\s*\[(.*?)\]\s*(.*)", rest)
    listed, es = m.group(1), m.group(2)
    parts, extra = pair_parts(es, directed)
    g = ref.parse_graph(cell)
    vtype = "String" if any(isinstance(v, str) for v in g.vertices) else "Int"
    verts = vertices_arg(listed) or extra
    pad = " " * indent
    out = []
    edge = "DirectedEdge(from: $0.0, to: $0.1)" if directed else "UndirectedEdge($0.0, $0.1)"
    if kind == "reversed":
        typ = "ReversedPseudograph"
    elif kind == "ual":
        typ = "UndirectedAdjacencyList"
    elif kind == "al":
        typ = "AdjacencyList"
    else:
        typ = "ReferenceDirectedMultigraph" if directed else "ReferencePseudograph"
    if not parts:
        out.append(f"{pad}let graph = {typ}<{vtype}>(vertices: {verts or '[]'}, edges: [])")
        return out, g, directed
    expr = " + ".join(parts)
    if len(parts) == 1:
        expr = wrap_literal(expr, indent)
    out.append(f"{pad}let pairs: [({vtype}, {vtype})] = {expr}")
    vpart = f"vertices: {verts}, " if verts else ""
    if kind == "reversed":
        out.append(f"{pad}let graph = {typ}(vertices: {verts or '[]'}, edges: pairs.map {{ {edge} }})")
    else:
        out.append(f"{pad}let graph = {typ}({vpart}edges: pairs.map {{ {edge} }})")
    return out, g, directed


# ------------------------------------------------------------------------------------------------
# Ops
# ------------------------------------------------------------------------------------------------


class Weight:
    def __init__(self, spec, m):
        self.spec = spec
        self.double = False
        self.decl = []
        self.empty = False
        if spec is None:
            self.arg = None
            return
        s = spec.strip()
        if s == "[]":
            self.empty = True
            self.decl = ["var calls = 0"]
            self.arg = "{ (_: Int) -> Int in\n            calls += 1\n            return 1\n        }"
            self.arc = None
        elif s.startswith("["):
            vals = ref.split_top(s[1:-1])
            self.double = any(is_double_text(v) for v in vals)
            body = "[" + ", ".join(swift_num(v) for v in vals) + "]"
            self.decl = [f"let w: [Double] = {body}" if self.double else f"let w = {body}"]
            self.arg = "{ w[$0] }"
            self.arc = "{ w[$0.position] }"
        else:
            mm = re.fullmatch(r"e%(\d+)\+(\d+)", s)
            if mm:
                self.arg = f"{{ $0 % {mm.group(1)} + {mm.group(2)} }}"
                self.arc = f"{{ $0.position % {mm.group(1)} + {mm.group(2)} }}"
            else:
                self.double = "." in s
                self.arg = f"{{ _ in {s} }}"
                self.arc = self.arg

    def call(self, name, extra=""):
        if self.arg is None:
            return f"{name}({extra})"
        sep = ", " if extra else ""
        if self.empty:
            return f"{name}({extra}{sep}weight: weight)"
        return f"{name}({extra}{sep}weight: {self.arg})"


def parse_list(s):
    s = s.strip()
    assert s.startswith("[") and s.endswith("]"), s
    inner = s[1:-1].strip()
    return [x.strip() for x in inner.split(",")] if inner else []


def vlist(items):
    return "[" + ", ".join(x if re.fullmatch(r"-?\d+", x) else f'"{x}"' for x in items) + "]"


def numlit(s):
    return "nil" if s == "nil" else swift_num(s.lstrip("#"))


def op_display(view, name, wspec, of):
    args = []
    if of is not None:
        args.append(f"of: {of}")
    if wspec is not None:
        args.append(f"weight: {wspec}")
    call = f"{name}({', '.join(args)})" if name != "density" else "density"
    return (f"{view}.{call}" if view else call)


def body_for(row, kind="reference", with_tree=True, indent=8, graph_lines=None):
    """Swift statements for one catalog row; returns (lines, needs_throws)."""
    cell, op, exp = row["Graph"].strip("`"), row["Op"].strip("`"), row["Expected"].strip("`")
    view, name, wspec, of = ref.parse_op(op)
    pad = " " * indent
    if graph_lines is None:
        glines, g, directed = build(cell, kind, indent)
        out = [f"{pad}// {cell}"] + glines
    else:
        out = []
        g = ref.parse_graph(cell)
        directed = g.directed
    target = "graph" if view is None else f"graph.{view}"
    W = Weight(wspec, g.m)
    for d in W.decl:
        out.append(pad + d)
    if W.empty:
        out.append(pad + "let weight = { (_: Int) -> Int in")
        out.append(pad + "    calls += 1")
        out.append(pad + "    return 1")
        out.append(pad + "}")
    throws = False
    if view is not None:
        out.append(f"{pad}let view = {target}")
        target = "view"
    t = target

    def ofarg():
        return sv(ref.vtok(str(of))) if of is not None else ""

    if name == "eccentricities":
        typ = "[Double?]" if (W.double or any(is_double_text(x) for x in parse_list(exp))) else "[Int?]"
        vals = [numlit(x) for x in parse_list(exp)]
        out.append(f"{pad}let expected: {typ} = [{', '.join(vals)}]")
        out.append(f"{pad}let eccentricities = {t}.{W.call('eccentricities')}")
        out.append(f"{pad}let byIndex = (0 ..< {t}.vertexCount).map {{ eccentricities.eccentricity(ofIndex: $0) }}")
        out.append(f"{pad}#expect(byIndex == expected)")
        out.append(f"{pad}let byVertex = {t}.vertices.map {{ eccentricities.eccentricity(of: $0) }}")
        out.append(f"{pad}#expect(byVertex == expected)")
        if W.arg is None:
            out.append(f"{pad}let oneByOne = {t}.vertices.map {{ {t}.eccentricity(of: $0) }}")
        else:
            out.append(f"{pad}let oneByOne = {t}.vertices.map {{ {t}.eccentricity(of: $0, weight: {W.arg}) }}")
        out.append(f"{pad}#expect(oneByOne == expected)")
        for member in ("radius", "diameter", "center", "periphery"):
            out.append(f"{pad}#expect({t}.{W.call(member)} == eccentricities.{member})")
        if not directed and view is None and kind != "tree":
            if W.arg is None:
                out.append(f"{pad}let arcs = graph.directed.eccentricities()")
            else:
                out.append(f"{pad}let arcs = graph.directed.eccentricities(weight: {W.arc})")
            out.append(f"{pad}let viaArcs = (0 ..< graph.vertexCount).map {{ arcs.eccentricity(ofIndex: $0) }}")
            out.append(f"{pad}#expect(viaArcs == expected)")
    elif name == "eccentricity":
        e = numlit(exp)
        out.append(f"{pad}#expect({t}.{W.call('eccentricity', 'of: ' + ofarg())} == {e})")
        out.append(f"{pad}#expect({t}.{W.call('eccentricities')}.eccentricity(of: {ofarg()}) == {e})")
    elif name in ("radius", "diameter"):
        e = numlit(exp)
        out.append(f"{pad}#expect({t}.{W.call(name)} == {e})")
        out.append(f"{pad}#expect({t}.{W.call('eccentricities')}.{name} == {e})")
    elif name in ("center", "periphery"):
        e = vlist(parse_list(exp))
        out.append(f"{pad}#expect({t}.{W.call(name)} == {e})")
        out.append(f"{pad}#expect({t}.{W.call('eccentricities')}.{name} == {e})")
    elif name == "centroid":
        e = vlist(parse_list(exp))
        out.append(f"{pad}#expect({t}.{W.call(name)} == {e})")
    elif name in ("wienerIndex", "averageShortestPathLength"):
        e = numlit(exp)
        out.append(f"{pad}#expect({t}.{W.call(name)} == {e})")
    elif name == "density":
        out.append(f"{pad}#expect({t}.density == {numlit(exp)})")
    elif name == "diameterPath":
        if exp == "nil":
            out.append(f"{pad}#expect({t}.{W.call(name)} == nil)")
        else:
            m = re.fullmatch(r"(\[[^\]]*\])/(\[[^\]]*\])(?: #(\S+))?", exp)
            vs, es, d = m.group(1), m.group(2), m.group(3)
            throws = True
            if W.arg is None:
                out.append(f"{pad}let path = try #require({t}.diameterPath())")
                out.append(f"{pad}#expect(path.vertices == {vlist(parse_list(vs))})")
                out.append(f"{pad}#expect(path.edges == {es})")
                out.append(f"{pad}#expect(path.length == {t}.diameter())")
            else:
                out.append(f"{pad}let result = try #require({t}.{W.call(name)})")
                out.append(f"{pad}#expect(result.path.vertices == {vlist(parse_list(vs))})")
                out.append(f"{pad}#expect(result.path.edges == {es})")
                out.append(f"{pad}#expect(result.distance == {swift_num(d)})")
    else:
        raise AssertionError(name)
    # Agreement with TreeAlgorithms.
    note = row.get("Notes", "")
    ta = re.search(r"= (TA-\d+)", note)
    if with_tree and ta and name in ("center", "centroid", "diameter", "diameterPath") and kind == "reference":
        throws = True
        out.append(f"{pad}// {ta.group(1)}: Tree's own member (TreeAlgorithms), and Distances on the tree as a Graph.")
        out.append(f"{pad}let tree = try #require(Tree(graph))")
        vt = "String" if any(isinstance(v, str) for v in g.vertices) else "Int"
        if name in ("center", "centroid"):
            e = vlist(parse_list(exp))
            out.append(f"{pad}#expect(tree.{W.call(name)} == {e})")
            wtail = f"weight: {W.arg if not W.empty else 'weight'}" if W.arg else ""
            out.append(f"{pad}func onGraph<G: Graph>(_ g: G) -> [G.Vertex] where G.Edges.Index == Int {{ g.{name}({wtail}) }}")
            out.append(f"{pad}#expect(onGraph(tree) == {e})")
        elif name == "diameter":
            e = numlit(exp)
            out.append(f"{pad}#expect(tree.{W.call(name)} == {e})")
            wtail = f"weight: {W.arg if not W.empty else 'weight'}" if W.arg else ""
            rt = "Double?" if W.double else "Int?"
            out.append(f"{pad}func onGraph<G: Graph>(_ g: G) -> {rt} where G.Edges.Index == Int {{ g.diameter({wtail}) }}")
            out.append(f"{pad}#expect(onGraph(tree) == {e})")
        else:
            m = re.fullmatch(r"(\[[^\]]*\])/(\[[^\]]*\])(?: #(\S+))?", exp)
            vs, es, d = m.group(1), m.group(2), m.group(3)
            if W.arg is None:
                out.append(f"{pad}let treePath = tree.diameterPath()")
                out.append(f"{pad}#expect(treePath.vertices == {vlist(parse_list(vs))})")
                out.append(f"{pad}#expect(treePath.edges == {es})")
                out.append(f"{pad}func onGraph<G: Graph>(_ g: G) -> Path<G.Vertex, Int>? where G.Edges.Index == Int {{ g.diameterPath() }}")
                out.append(f"{pad}let graphPath = try #require(onGraph(tree))")
                out.append(f"{pad}#expect(graphPath == treePath)")
            else:
                wt = "Double" if W.double else "Int"
                warg = W.arg if not W.empty else "weight"
                out.append(f"{pad}let treeResult = tree.diameterPath(weight: {warg})")
                out.append(f"{pad}#expect(treeResult.path.vertices == {vlist(parse_list(vs))})")
                out.append(f"{pad}#expect(treeResult.path.edges == {es})")
                out.append(f"{pad}#expect(treeResult.distance == {swift_num(d)})")
                out.append(
                    f"{pad}func onGraph<G: Graph>(_ g: G) -> (path: Path<G.Vertex, Int>, distance: {wt})? where G.Edges.Index == Int {{ g.diameterPath(weight: {warg}) }}"
                )
                out.append(f"{pad}let graphResult = try #require(onGraph(tree))")
                out.append(f"{pad}#expect(graphResult.path == treeResult.path)")
                out.append(f"{pad}#expect(graphResult.distance == treeResult.distance)")
        _ = vt
    if W.empty:
        out.append(f"{pad}#expect(calls == 0)")
    return out, throws


def fname(row):
    cell, op = row["Graph"].strip("`"), row["Op"].strip("`")
    view, name, wspec, of = ref.parse_op(op)
    base = name
    if view:
        base = view + name[0].upper() + name[1:]
    if wspec is not None:
        base += "Weighted"
    return base + row["ID"][3:]


def display(row):
    cell, op, exp = row["Graph"].strip("`"), row["Op"].strip("`"), row["Expected"].strip("`")
    view, name, wspec, of = ref.parse_op(op)
    k, rest = cell.split(":", 1)
    rest = rest.strip()
    m = re.match(r"\[(.*?)\]\s*(.*)", rest)
    listed, es = m.group(1), m.group(2)
    inner = (f"[{listed}]" + ("; " + es if es else "")) if listed else es
    head = f"{k.strip()}({inner})"
    s = f"{row['ID']} {head}.{op_display(view, name, wspec, of)} is {exp}"
    note = row.get("Notes", "").strip()
    if note:
        s += ": " + note
    return esc(s)


def check_row(row):
    got = ref.evaluate(row["Graph"].strip("`"), row["Op"].strip("`"))
    assert got == row["Expected"].strip("`"), (row["ID"], got)


def test_for(row, kind="reference", indent=4):
    check_row(row)
    lines_, throws = body_for(row, kind, indent=indent + 4)
    sig = f"func {fname(row)}() throws {{" if throws else f"func {fname(row)}() {{"
    pad = " " * indent
    return [f'{pad}@Test("{display(row)}")', pad + sig] + lines_ + [pad + "}"]


def in_range(cid, lo, hi):
    n = int(cid[3:])
    return lo <= n <= hi


TRAPS = {r for r in ORDER if ROWS[r]["Expected"].strip("`") == "trap"}

FILES = [
    ("DegenerateGraphTests.swift", "Degenerate graphs", "DegenerateGraphTests", 1, 99, """// §A: the empty graph, K₁, two isolated vertices, K₂ both ways and a lone self-loop. The empty
// graph has no eccentricities: radius and diameter nil, center, periphery and centroid empty, the
// Wiener index the empty sum 0, the average nil (no pairs), density 0 (DI-001 – DI-012). Two
// isolated vertices have every eccentricity infinite (nil), so every vertex is in the center and
// the periphery (DI-028, DI-029). K₁ weighted never calls the closure (DI-023, DI-024). Rows citing
// `= TA-nnn` also run `Tree`'s own member (TreeAlgorithms) and Distances on the `Tree` as a
// `Graph`, and must equal the catalog cell. Every literal is a catalog cell (`ref.py`: api.md's
// model, Floyd–Warshall, NetworkX 3.7 and scipy 1.18.1). DI-042 (not a vertex) is an exit test in
// `DistancePreconditionTests.swift`. Case IDs (DI-nnn) refer to the catalog; see README.md."""),
    ("UndirectedDistanceTests.swift", "Undirected, unweighted", "UndirectedDistanceTests", 100, 199, """// §B: connected undirected graphs without weights: NetworkX's docstring graph and grid, cycles and
// complete graphs (vertex-transitive: every vertex central and peripheral, the bounding
// algorithm's worst shape), K₃,₄, Petersen, Zachary's karate club, two triangles joined by a path,
// and a path with 12 pseudo-random chords. Every `eccentricities` row also checks
// `eccentricity(ofIndex:)`, `eccentricity(of:)` on the value and on the graph, that the one-shot
// `radius()`, `diameter()`, `center()` and `periphery()` equal the value's members, and that
// `graph.directed` gives the same eccentricities; every radius, diameter, center and periphery row
// checks the one-shot call and the `Eccentricities` member. `diameterPath()` pins the breadth-first
// path from the first peripheral vertex (rows in position order). Literals are catalog cells.
// Case IDs (DI-nnn) refer to the catalog; see README.md."""),
    ("TreeAgreementTests.swift", "Trees: agreement with TreeAlgorithms, and tie order", "TreeAgreementTests", 200, 299, """// §C: trees, where every value must equal TreeAlgorithms' (`= TA-nnn` rows: `Tree.center()`,
// `centroid()`, `diameter()`, `diameterPath()`, weighted too); each such row runs Distances on the
// `ReferencePseudograph`, `Tree`'s own member, and Distances on the `Tree` read as a `Graph`
// through a generic function, which must all give the catalog cell. `vertices` order decides
// `center`, `periphery` and `centroid` order (DI-201, DI-250) and the start of `diameterPath`
// (DI-204, DI-251); row order decides the path between fixed endpoints (DI-251 against DI-252,
// DI-253 against DI-254, the `~rev` rows on a conformer private to this file whose rows are
// reversed). Weighted rows use `Int` and `Double` weights, zeros included (DI-229, DI-236). Literals
// are catalog cells. DI-240 (a negative weight) is an exit test in `DistancePreconditionTests.swift`.
// Case IDs (DI-nnn) refer to the catalog; see README.md."""),
    ("DisconnectedGraphTests.swift", "Disconnected undirected graphs", "DisconnectedGraphTests", 300, 399, """// §D: undirected graphs that are not connected. Every eccentricity is infinite (nil), so the radius
// and the diameter are nil, every vertex is in the center and the periphery and the centroid
// (nil == nil, as JGraphT and scipy's infinities give), the Wiener index and the average are nil,
// and `diameterPath()` is nil; density still counts edges (DI-310). An isolated vertex is not a
// center of eccentricity 0 (igraph's reading). Literals are catalog cells. Case IDs (DI-nnn) refer
// to the catalog; see README.md."""),
    ("DirectedDistanceTests.swift", "Directed graphs", "DirectedDistanceTests", 400, 499, """// §E: directed graphs, over out-distances. A digraph that is not strongly connected has a finite
// radius when some vertex reaches every vertex (DI-402, DI-426: the dipath and the acyclic
// tournament) and a nil diameter; its center is the vertices of least finite eccentricity and its
// periphery the vertices that do not reach everything (DI-405, DI-427). The Wiener index sums
// ordered pairs, so `graph.directed` doubles it (DI-438) and keeps the average and the density
// (DI-437, DI-439); `digraph.undirected` reads each arc as an edge (DI-428, DI-429, DI-434). Loops
// count in the density (DI-441). Literals are catalog cells. Case IDs (DI-nnn) refer to the
// catalog; see README.md."""),
    ("MultigraphDistanceTests.swift", "Self-loops and parallel edges", "MultigraphDistanceTests", 500, 599, """// §F: self-loops and parallel edges, on the `ReferencePseudograph` and `ReferenceDirectedMultigraph`
// (the adjacency lists cannot hold parallel edges). Loops and parallel copies change no distance;
// `diameterPath()` goes through the first copy in the row (DI-503, DI-510); density counts every
// edge, a loop once, so it can exceed 1 (DI-504, DI-507, DI-509). Literals are catalog cells.
// Case IDs (DI-nnn) refer to the catalog; see README.md."""),
    ("WeightedDistanceTests.swift", "Weighted", "WeightedDistanceTests", 600, 699, """// §G: weighted measures, `Int` and `Double` weights given by edge position. The lighter of parallel
// edges counts and the path names it (DI-610 – DI-612); a zero-weight loop changes nothing; all-zero
// weights make every vertex central and give the trivial path at `vertices[0]` (DI-614 – DI-616);
// dyadic `Double` weights are exact (DI-617 – DI-619); directed weights (DI-620 – DI-624); a grid
// with weights e mod 3 + 1 (DI-625 – DI-628); `+infinity` is a value, not "unreachable" (DI-629).
// The weighted average needs `BinaryFloatingPoint` weights (DI-609). Literals are catalog cells.
// DI-630 – DI-633 (negative and NaN weights) are exit tests in `DistancePreconditionTests.swift`;
// the weight closure's call order is in `WeightReadingTests.swift`. Case IDs (DI-nnn) refer to the
// catalog; see README.md."""),
]

REVERSED = """
/// An undirected pseudograph whose incidence rows are not in position order: each row is built in
/// position order (a self-loop twice), then reversed (the catalog's `~rev`). Vertex and edge
/// indices are positions.
private struct ReversedPseudograph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>]) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { Array(inOrder.incidentEdges(of: $0).reversed()) }
    }

    func incidentEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}
"""

COUNTS = {}


def gen_section(fname_, title, suite, lo, hi, header):
    rows = [ROWS[c] for c in ORDER if in_range(c, lo, hi) and c not in TRAPS]
    tests = []
    imports = {"Distances", "GraphProtocols", "GrafluentTestSupport", "Testing"}
    for r in rows:
        kind = "reversed" if r["Graph"].strip("`").endswith("~rev") else "reference"
        t = test_for(r, kind)
        tests.append("\n".join(t))
        if any("Tree(" in x for x in t):
            imports |= {"Trees", "TreeAlgorithms"}
        if any("Path<" in x for x in t):
            imports.add("Walks")
    src = header + "\n\n" + "\n".join(f"import {m}" for m in sorted(imports, key=str.lower)) + "\n"
    if any(r["Graph"].strip("`").endswith("~rev") for r in rows):
        src += REVERSED
    src += f'\n@Suite("{title}")\nstruct {suite} {{\n' + "\n\n".join(tests) + "\n}\n"
    (OUT / fname_).write_text(src)
    COUNTS[fname_] = len(rows)
    return [r["ID"] for r in rows]


# ------------------------------------------------------------------------------------------------
# Representations
# ------------------------------------------------------------------------------------------------


def has_parallel(g):
    seen = set()
    for a, b in g.ends:
        key = (a, b) if g.directed else (min(a, b), max(a, b))
        if key in seen:
            return True
        seen.add(key)
    return False


def gen_representations():
    groups = {}
    for c in ORDER:
        if c in TRAPS or int(c[3:]) >= 900:
            continue
        r = ROWS[c]
        cell = r["Graph"].strip("`")
        if cell.endswith("~rev"):
            continue
        view = ref.parse_op(r["Op"].strip("`"))[0]
        if view is not None:
            continue
        groups.setdefault(cell, []).append(r)
    tests = []
    count = 0
    for cell, rows in groups.items():
        g = ref.parse_graph(cell)
        if has_parallel(g):
            continue
        kind = "al" if g.directed else "ual"
        typ = "AdjacencyList" if g.directed else "UndirectedAdjacencyList"
        ids = [r["ID"] for r in rows]
        idtext = ids[0] if len(ids) == 1 else f"{ids[0]} – {ids[-1]}" if len(ids) > 2 else f"{ids[0]} {ids[1]}"
        idtext = ", ".join(ids) if len(ids) <= 3 else idtext
        if len(ids) > 3:
            idtext = ", ".join(ids[:2]) + f" … {ids[-1]}"
        disp = esc(f"{idtext} on {typ}: {cell}")
        body = []
        glines, _, _ = build(cell, kind, 8)
        body += [f"        // {cell}"] + glines
        body.append(f"        #expect(Array(graph.vertices) == {vlist([str(v) for v in g.vertices])})")
        throws = False
        for k, r in enumerate(rows):
            check_row(r)
            body.append(f"        do {{")
            b, t = body_for(r, kind, with_tree=False, indent=12, graph_lines=False)
            body += [f"            // {r['ID']}: {r['Op'].strip('`')}"] + b
            body.append("        }")
            throws = throws or t
        name = ("adjacencyList" if g.directed else "undirectedAdjacencyList") + ids[0][3:]
        sig = f"func {name}() throws {{" if throws else f"func {name}() {{"
        tests.append("\n".join([f'    @Test("{disp}")', "    " + sig] + body + ["    }"]))
        count += 1
    # CompressedSparseRow: directed cells on 0..<n, arcs rewritten row-major (no repeats), weights
    # carried along; ref.py evaluates the rewritten graph.
    for cell, rows in groups.items():
        g = ref.parse_graph(cell)
        if not g.directed or has_parallel(g) or g.vertices != list(range(g.n)):
            continue
        order = sorted(range(g.m), key=lambda e: g.ends[e])
        arcs = [g.ends[e] for e in order]
        newcell = f"D: [0..{g.n - 1}] " + ", ".join(f"{a}>{b}" for a, b in arcs) if g.n else "D: []"
        if g.n and not arcs:
            newcell = f"D: [0..{g.n - 1}]"
        ids = [r["ID"] for r in rows]
        idtext = ", ".join(ids) if len(ids) <= 3 else ", ".join(ids[:2]) + f" … {ids[-1]}"
        disp = esc(f"{idtext} on CompressedSparseRow: {cell}, arcs rewritten row-major")
        body = [f"        // {newcell}"]
        if arcs:
            lit = "[" + ", ".join(f"({a}, {b})" for a, b in arcs) + "]"
            body.append(f"        let pairs: [(Int, Int)] = {wrap_literal(lit, 8)}")
            body.append(f"        let graph = CompressedSparseRow(vertexCount: {g.n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})")
        else:
            body.append(f"        let graph = CompressedSparseRow(vertexCount: {g.n})")
        throws = False
        for r in rows:
            view, name, wspec, of = ref.parse_op(r["Op"].strip("`"))
            op2 = r["Op"].strip("`")
            if wspec is not None:
                w = ref.parse_weights(wspec, g.m)
                w2 = [w[e] for e in order]
                txt = "[" + ", ".join(ref.fnum(x) for x in w2) + "]"
                op2 = op2.replace(f"weight: {wspec}", f"weight: {txt}")
            got = ref.evaluate(newcell, op2)
            fake = dict(r)
            fake["Graph"] = newcell
            fake["Op"] = op2
            fake["Expected"] = got
            fake["Notes"] = ""
            if name != "diameterPath":
                assert got == r["Expected"].strip("`"), (r["ID"], got)
            body.append("        do {")
            b, t = body_for(fake, "csr", with_tree=False, indent=12, graph_lines=False)
            note = "" if got == r["Expected"].strip("`") else f" (computed with ref.py on the rewritten arcs: {got})"
            body += [f"            // {r['ID']}: {op2}{note}"] + b
            body.append("        }")
            throws = throws or t
        name = "compressedSparseRow" + ids[0][3:]
        sig = f"func {name}() throws {{" if throws else f"func {name}() {{"
        tests.append("\n".join([f'    @Test("{disp}")', "    " + sig] + body + ["    }"]))
        count += 1
    header = """// The catalog rows on the package's representations (not a catalog section). Every row of §A – §G
// whose graph has no parallel edges and no `~rev` is repeated on `UndirectedAdjacencyList` or
// `AdjacencyList` built in written order, so vertex order, rows and positions are the catalog's
// (the vertex order is asserted first) and the values are the catalog cells;
// `UndirectedAdjacencyList` lends its index rows to the algorithms instead of `incidentEdges`.
// Directed rows on the vertices 0..<n are repeated on `CompressedSparseRow` with the arcs rewritten
// in row-major order (the representation's own positions) and the weights carried with their arcs;
// those literals were computed by `ref.py` on the rewritten graph, and every one but the edge
// positions of a path equals the catalog cell. One test per graph, each row in its own `do` block.
// Case IDs (DI-nnn) refer to the catalog; see README.md."""
    src = header + "\n\nimport AdjacencyListModule\nimport CompressedSparseRowModule\nimport Distances\nimport GraphProtocols\nimport Testing\n"
    src += '\n@Suite("Distances on every representation")\nstruct DistanceRepresentationTests {\n' + "\n\n".join(tests) + "\n}\n"
    (OUT / "DistanceRepresentationTests.swift").write_text(src)
    COUNTS["DistanceRepresentationTests.swift"] = count


def gen_double_repeats():
    tests = []
    count = 0
    for c in ORDER:
        if c in TRAPS or not (200 <= int(c[3:]) < 700):
            continue
        r = ROWS[c]
        view, name, wspec, of = ref.parse_op(r["Op"].strip("`"))
        if wspec is None or wspec.strip() == "[]":
            continue
        cell = r["Graph"].strip("`")
        g = ref.parse_graph(cell)
        w = ref.parse_weights(wspec, g.m)
        if any(isinstance(x, float) for x in w):
            continue
        for negzero in (False, True):
            if negzero and 0 not in w:
                continue
            fw = [(-0.0 if (negzero and x == 0) else float(x)) for x in w]
            txt = "[" + ", ".join(ref.fnum(x) for x in fw) + "]"
            op2 = r["Op"].strip("`").replace(f"weight: {wspec}", f"weight: {txt}")
            got = ref.evaluate(cell, op2)
            fake = dict(r)
            fake["Op"] = op2
            fake["Expected"] = got
            fake["Notes"] = ""
            kind = "reversed" if cell.endswith("~rev") else "reference"
            lines_, throws = body_for(fake, kind, with_tree=False, indent=8)
            tag = "Double weights, -0.0 for each zero" if negzero else "Double weights"
            disp = esc(f"{c} with {tag}: {cell}.{op_display(view, name, txt, of)} is {got} (the Int row gives {r['Expected'].strip('`')})")
            fn = fname(r) + ("NegativeZero" if negzero else "Double")
            sig = f"func {fn}() throws {{" if throws else f"func {fn}() {{"
            tests.append("\n".join([f'    @Test("{disp}")', "    " + sig, f"        // Computed with ref.py: the catalog row with the weights as Double{', -0.0 for each zero' if negzero else ''}."] + lines_ + ["    }"]))
            count += 1
    header = """// The Int-weighted rows of §C and §G again with the same weights as `Double`, and, where a weight is
// zero, with `-0.0` for each zero (not below `.zero`, so allowed, and equal to 0). The values are
// the Int rows' (every weight here is a small integer, so every sum is exact); each literal was
// computed by `ref.py` on the row with its weights rewritten. Case IDs (DI-nnn) refer to the
// catalog; see README.md."""
    src = header + "\n\nimport Distances\nimport GraphProtocols\nimport GrafluentTestSupport\nimport Testing\n"
    src += '\n@Suite("Double weights")\nstruct DoubleWeightTests {\n' + "\n\n".join(tests) + "\n}\n"
    (OUT / "DoubleWeightTests.swift").write_text(src)
    COUNTS["DoubleWeightTests.swift"] = count


if __name__ == "__main__":
    covered = []
    for f in FILES:
        covered += gen_section(*f)
    gen_representations()
    gen_double_repeats()
    for k, v in COUNTS.items():
        print(k, v)
    print("traps", sorted(TRAPS))
