"""Writes the catalog-row test files of Tests/BipartiteGraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 python3 swiftgen.py [OUT_DIR]   # default: Tests/BipartiteGraphsTests

First checks that ref.py's model reproduces cases.md exactly (ref.build_rows), then re-evaluates
every row with the model's functions (structured values, not the printed cells), asserts each value
matches its catalog cell, and writes one @Test per row. Representation rows (AdjacencyList and
AdjacencyMatrix through `.undirected`) are recomputed with the model on those representations' row
orders: successors then predecessors, arcs in insertion order (AdjacencyList) or row-major order
(AdjacencyMatrix).
"""
import os, sys, json

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "BipartiteGraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check
# ---------------------------------------------------------------------------------------------
rows = ref.build_rows()
text = ref.render(rows)
with open(ref.CASES_MD) as f:
    assert f.read() == text, "cases.md is not ref.py's output"
CELLS = {}
for line in text.splitlines():
    if line.startswith("| BP-"):
        parts = [p.strip() for p in line.strip("|").split(" | ")]
        CELLS[parts[0]] = parts
assert len(CELLS) == 166

ids = iter(f"BP-{i:03d}" for i in range(1, 167))
REC_IDS = [next(ids) for _ in ref.REC]
INITG_IDS = [next(ids) for _ in ref.INITG]
INITS_IDS = [next(ids) for _ in ref.INITS]
MUT_IDS = [next(ids) for _ in ref.MUT]
TRAP_IDS = [next(ids) for _ in ref.TRAP]
PROJ_IDS = [next(ids) for _ in ref.PROJ]
EQ_IDS = [next(ids) for _ in ref.EQ]

# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def lit(x):
    return json.dumps(x, ensure_ascii=False) if isinstance(x, str) else str(x)

def ty(values, default="Int"):
    values = list(values)
    if not values:
        return default
    return "String" if isinstance(values[0], str) else "Int"

def arr(xs):
    return "[" + ", ".join(lit(x) for x in xs) + "]"

def pairs_lit(E):
    return "[" + ", ".join(f"({lit(a)}, {lit(b)})" for a, b in E) + "]"

def nested(E):
    return "[" + ", ".join(f"[{lit(a)}, {lit(b)}]" for a, b in E) + "]"

def name_str(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')

def fn(id_):
    return "bp" + id_[3:]

def ind(lines, n):
    pad = " " * n
    return [pad + l if l else l for l in lines]

def header(comment, imports, suite, struct, tags=None):
    out = []
    for c in comment:
        out.append("// " + c if c else "//")
    out.append("")
    for i in imports:
        out.append(f"import {i}")
    out.append("")
    t = f", .tags({tags})" if tags else ""
    out.append(f'@Suite("{suite}"{t})')
    out.append(f"struct {struct} {{")
    return out

def write(name, lines):
    body = "\n".join(lines).rstrip() + "\n"
    body = body.replace("{\n\n    @Test", "{\n    @Test")
    with open(os.path.join(OUT, name), "w") as f:
        f.write(body)
    print("wrote", name, sum(1 for l in lines if l.strip().startswith("@Test")), "tests")

# ---------------------------------------------------------------------------------------------
# Recognition checks (shared body text; each test gets its own copy)
# ---------------------------------------------------------------------------------------------

def recognition_checks(V, side, cyc, T, edge_lit=None, index_note="vertex index"):
    """Lines checking a `graph` value. side: list of 0/1 per vertex number (V order), or None.
    cyc: (vs as vertex values, es as edge literals) when not bipartite."""
    L = []
    if side is not None:
        left = [V[i] for i in range(len(V)) if side[i] == 0]
        right = [V[i] for i in range(len(V)) if side[i] == 1]
        L += [
            "#expect(graph.isBipartite)",
            "#expect(graph.findOddCycle() == nil)",
            "let bipartition = try #require(graph.bipartition())",
            f"let left: [{T}] = {arr(left)}",
            f"let right: [{T}] = {arr(right)}",
            "#expect(Array(bipartition.left) == left)",
            "#expect(Array(bipartition.right) == right)",
            "for v in left { #expect(bipartition.side(of: v) == .left) }",
            "for v in right { #expect(bipartition.side(of: v) == .right) }",
            f"// side(ofIndex:) by {index_note}.",
            "for (i, v) in Array(graph.vertices).enumerated() { #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v)) }",
            "for edge in graph.edges { #expect(bipartition.side(of: edge.u) != bipartition.side(of: edge.v)) }",
            "let bipartite = try #require(BipartiteGraph(graph))",
            "#expect(Array(bipartite.left) == left)",
            "#expect(Array(bipartite.right) == right)",
        ]
    else:
        vs, es = cyc
        L += [
            "#expect(!graph.isBipartite)",
            "#expect(graph.bipartition() == nil)",
            "#expect(BipartiteGraph(graph) == nil)",
            "let cycle = try #require(graph.findOddCycle())",
            f"#expect(cycle.vertices == {arr(vs)})",
        ]
        if edge_lit is None:
            L.append(f"#expect(cycle.edges == {arr(es)})")
        else:
            L.append(f"#expect(cycle.edges.map {{ [$0.source, $0.target] }} == {nested(es)})")
        L += [
            "// Valid: odd, simple, each edge joining consecutive vertices, a cycle of the graph.",
            "let k = cycle.vertices.count",
            f"#expect(k == {len(vs)} && k % 2 == 1)",
            "#expect(Set(cycle.vertices).count == k)",
            "#expect(Set(cycle.edges).count == k)",
            "for i in 0 ..< k {",
            "    let edge = graph.edges[cycle.edges[i]]",
            "    #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))",
            "}",
            "#expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)",
        ]
    return L


def model_recognition(V, E, directed):
    side, c = ref.two_color(len(V), ref.rows_of(V, E, directed))
    if side is not None:
        return side, None
    vs, es = c
    return None, ([V[i] for i in vs], es)


def check_against_cell(id_, V, side, cyc):
    cell = CELLS[id_][4]
    if side is not None:
        left = [V[i] for i in range(len(V)) if side[i] == 0]
        right = [V[i] for i in range(len(V)) if side[i] == 1]
        assert cell == f"isBipartite true; left {ref.fmt(left)}; right {ref.fmt(right)}; findOddCycle() nil", (id_, cell)
    else:
        vs, es = cyc
        assert cell == f"isBipartite false; bipartition() nil; findOddCycle() cycle {ref.fmt(vs)} via {ref.fmt(es)} (length {len(vs)})", (id_, cell)


def summary(side, cyc, V):
    if side is not None:
        left = [V[i] for i in range(len(V)) if side[i] == 0]
        right = [V[i] for i in range(len(V)) if side[i] == 1]
        return f"left {ref.fmt(left)}, right {ref.fmt(right)}"
    vs, es = cyc
    return f"odd cycle {ref.fmt(vs)} via {ref.fmt(es)}"

# ---------------------------------------------------------------------------------------------
# RecognitionTests.swift
# ---------------------------------------------------------------------------------------------

def build_lines(c, kind):
    V, E = c["V"], c["E"]
    T = ty(V)
    L = [f"// {CELLS_INPUT[id(c)]}"]
    if kind == "pseudo":
        if E:
            L.append(f"let pairs: [({T}, {T})] = {pairs_lit(E)}")
            L.append(f"let graph = ReferencePseudograph(vertices: {arr(V)} as [{T}], edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        else:
            L.append(f"let graph = ReferencePseudograph<{T}>(vertices: {arr(V)}, edges: [])")
    elif kind == "digraph":
        L.append(f"let arcs: [({T}, {T})] = {pairs_lit(E)}")
        L.append(f"let digraph = AdjacencyList(vertices: {arr(V)} as [{T}], edges: arcs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})")
        L.append("let graph = digraph.undirected")
    return L

CELLS_INPUT = {}
for c, id_ in zip(ref.REC, REC_IDS):
    CELLS_INPUT[id(c)] = CELLS[id_][3]


def gen_recognition():
    out = header([
        "Recognition on any `Graph` (catalog §Recognition, BP-001 – BP-084): `isBipartite`,",
        "`bipartition()` with its canonical sides (each component's least vertex left, each side in",
        "`vertices` order), `side(of:)` and `side(ofIndex:)`, `BipartiteGraph(graph)` agreeing with",
        "them, and `findOddCycle()`: the exact cycle api.md's breadth-first search returns, in Cycles'",
        "canonical form, and its validity (odd, simple, each edge joining consecutive vertices,",
        "`Cycle(vertices:edges:in:)` not nil). Undirected rows run on `ReferencePseudograph`, whose rows",
        "are in position order (a self-loop twice, consecutively; parallel edges kept), so vertex",
        "numbers and edge positions are the catalog's. `digraph` rows (BP-069 – BP-074) are an",
        "`AdjacencyList` read through `.undirected`: rows are successors, then predecessors. Generated",
        "from cases.md by swiftgen.py, which re-evaluates each row with ref.py's model; see README.md.",
    ], ["AdjacencyListModule", "BipartiteGraphs", "GraphProtocols", "GrafluentTestSupport", "Testing", "Walks"],
        "Recognition: isBipartite, bipartition(), findOddCycle()", "RecognitionTests")
    for c, id_ in zip(ref.REC, REC_IDS):
        V, E = c["V"], c["E"]
        side, cyc = model_recognition(V, E, c["directed"])
        check_against_cell(id_, V, side, cyc)
        kind = "digraph" if c["directed"] else "pseudo"
        title = f"{id_} {c['name']}: {summary(side, cyc, V)}"
        body = build_lines(c, kind) + recognition_checks(V, side, cyc, ty(V), index_note="vertex index (the position in `vertices`)")
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() throws {{"] + ind(body, 8) + ["    }"]
    out.append("}")
    write("RecognitionTests.swift", out)

# ---------------------------------------------------------------------------------------------
# RecognitionRepresentationTests.swift
# ---------------------------------------------------------------------------------------------

def gen_representations():
    out = [
        "// Every recognition row (BP-001 – BP-084) again on the other representations: the package's",
        "// `UndirectedAdjacencyList` (stored index rows, so recognition reads `_withIncidentIndexRows`),",
        "// a file-private conformer with no vertex or edge indices (rows from `incidentEdges(of:)`,",
        "// `side(ofIndex:)` by position in `vertices`), `AdjacencyList.undirected` with each edge as an",
        "// arc as written, and `AdjacencyMatrix.undirected` with the arcs at their row-major cells, for",
        "// rows on 0..<n with no arc twice. Rows with parallel edges run on the unindexed conformer only.",
        "// Through `.undirected` a row is successors, then predecessors, so the odd cycle those",
        "// searches meet can differ from the catalog's: swiftgen.py computed each expected cycle with",
        "// ref.py's model on that representation's rows (sides do not depend on row order). Matrix",
        "// positions are cells, compared as [source, target]. See README.md.",
        "",
    ]
    for i in ["AdjacencyListModule", "AdjacencyMatrixModule", "BipartiteGraphs", "GraphProtocols", "Testing", "Walks"]:
        out.append(f"import {i}")
    out += [
        "",
        "/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.",
        "/// Rows are in position order, a self-loop's position twice; parallel edges are kept.",
        "private struct UnindexedGraph<Vertex: Hashable>: Graph {",
        "    let vertices: [Vertex]",
        "    let edges: [UndirectedEdge<Vertex>]",
        "",
        "    func incidentEdges(of vertex: Vertex) -> [Int] {",
        "        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }",
        "    }",
        "    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }",
        "}",
        "",
        '@Suite("Recognition on every representation")',
        "struct RecognitionRepresentationTests {",
    ]
    count = 0
    for c, id_ in zip(ref.REC, REC_IDS):
        V, E, directed, multi = c["V"], c["E"], c["directed"], c["multi"]
        T = ty(V)
        blocks = []
        names = []
        if not directed:
            side, cyc = model_recognition(V, E, False)
            check_against_cell(id_, V, side, cyc)
            if not multi:
                names.append("UndirectedAdjacencyList")
                b = []
                if E:
                    b.append(f"let pairs: [({T}, {T})] = {pairs_lit(E)}")
                    b.append(f"let graph = UndirectedAdjacencyList(vertices: {arr(V)} as [{T}], edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
                else:
                    b.append(f"let graph = UndirectedAdjacencyList<{T}>(vertices: {arr(V)} as [{T}])")
                b.append("#expect(graph.edgeCount == " + str(len(E)) + ")")
                b += recognition_checks(V, side, cyc, T)
                blocks.append(("UndirectedAdjacencyList: the catalog's values", b))
            names.append("no indices")
            b = []
            if E:
                b.append(f"let pairs: [({T}, {T})] = {pairs_lit(E)}")
                b.append(f"let graph = UnindexedGraph(vertices: {arr(V)} as [{T}], edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
            else:
                b.append(f"let graph = UnindexedGraph<{T}>(vertices: {arr(V)}, edges: [])")
            b.append("#expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)")
            b += recognition_checks(V, side, cyc, T, index_note="position in `vertices`")
            blocks.append(("No vertex or edge indices: the catalog's values", b))
            if not multi:
                names.append("AdjacencyList.undirected")
                s2, c2 = model_recognition(V, E, True)
                b = [f"let arcs: [({T}, {T})] = {pairs_lit(E)}",
                     f"let graph = AdjacencyList(vertices: {arr(V)} as [{T}], edges: arcs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected"]
                b += recognition_checks(V, s2, c2, T)
                note = "the catalog's values" if (s2, c2) == (side, cyc) else "rows successors then predecessors, so another cycle"
                blocks.append((f"AdjacencyList.undirected, each edge an arc as written: {note}", b))
        else:
            side, cyc = model_recognition(V, E, True)
            check_against_cell(id_, V, side, cyc)
        # Matrix: vertices exactly 0..<n, no arc twice.
        n = len(V)
        if all(isinstance(v, int) for v in V) and sorted(V) == list(range(n)) and len(set(E)) == len(E):
            arcs = sorted(E)
            Vm = list(range(n))
            sm, cm = model_recognition(Vm, arcs, True)
            if cm is not None:
                cm = (cm[0], [arcs[e] for e in cm[1]])
            names.append("AdjacencyMatrix.undirected")
            b = [f"let arcs: [(Int, Int)] = {pairs_lit(E)}",
                 f"let graph = AdjacencyMatrix(vertexCount: {n}, edges: arcs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected"]
            b += recognition_checks(Vm, sm, cm, "Int", edge_lit=True)
            blocks.append(("AdjacencyMatrix.undirected: vertices 0..<n, arcs at row-major cells, rows successors then predecessors", b))
        if not blocks:
            continue
        count += 1
        title = f"{id_} {c['name']}, on " + ", ".join(names)
        body = [f"// {CELLS[id_][3]}"]
        for note, b in blocks:
            body.append(f"do {{ // {note}")
            body += ind(b, 4)
            body.append("}")
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() throws {{"] + ind(body, 8) + ["    }"]
    out.append("}")
    write("RecognitionRepresentationTests.swift", out)

# ---------------------------------------------------------------------------------------------
# BipartiteGraph state checks
# ---------------------------------------------------------------------------------------------

def state_checks(b, var="graph", T="String"):
    V, Lft, R, E = b.vertices(), b.left(), b.right(), b.edges()
    return [
        f"#expect(Array({var}.vertices) == {arr(V)} as [{T}])",
        f"#expect(Array({var}.left) == {arr(Lft)} as [{T}])",
        f"#expect(Array({var}.right) == {arr(R)} as [{T}])",
        f"#expect({var}.edges.map {{ [$0.u, $0.v] }} == {nested(E)} as [[{T}]])",
        f"for v in {var}.left {{ #expect({var}.side(of: v) == .left) }}",
        f"for v in {var}.right {{ #expect({var}.side(of: v) == .right) }}",
    ]


def side_init_expr(left, right, edges, T):
    if edges is None:
        return f"BipartiteGraph<{T}>(left: {arr(left)} as [{T}], right: {arr(right)} as [{T}])"
    return (f"BipartiteGraph<{T}>(left: {arr(left)} as [{T}], right: {arr(right)} as [{T}], "
            f"edges: {pairs_lit(edges)}.map {{ UndirectedEdge<{T}>($0.0, $0.1) }})" if edges else
            f"BipartiteGraph<{T}>(left: {arr(left)} as [{T}], right: {arr(right)} as [{T}], edges: [UndirectedEdge<{T}>]())")

# ---------------------------------------------------------------------------------------------
# BipartiteGraphFromGraphTests.swift
# ---------------------------------------------------------------------------------------------

def gen_from_graph():
    out = header([
        "`BipartiteGraph(graph)` and `BipartiteGraph(graph, left:)` (catalog BP-085 – BP-104): the",
        "graph's vertex order, its edges in position order stored left endpoint first (so, without",
        "parallel edges, at the graph's positions), the canonical sides of `bipartition()` or the given",
        "left side with every other vertex right; nil on an odd cycle, on an edge with both ends on one",
        "side, or when `left:` names a non-vertex. Each row runs on `ReferencePseudograph` (rows in",
        "position order, parallel edges kept) and, when it has no parallel edges, again on",
        "`UndirectedAdjacencyList`. Edges are compared as [u, v] to see the stored orientation.",
        "Generated from cases.md by swiftgen.py; see README.md.",
    ], ["AdjacencyListModule", "BipartiteGraphs", "GraphProtocols", "GrafluentTestSupport", "Testing"],
        "BipartiteGraph(graph) and BipartiteGraph(graph, left:)", "BipartiteGraphFromGraphTests")
    for c, id_ in zip(ref.INITG, INITG_IDS):
        V, E, left = c["V"], c["E"], c["left"]
        T = ty(V)
        b = ref.BG.from_graph(V, E, left)
        exp = "nil" if b is None else b.describe()
        assert CELLS[id_][4] == exp, (id_, CELLS[id_][4], exp)
        call = "BipartiteGraph(graph)" if left is None else f"BipartiteGraph(graph, left: {arr(left)} as [{T}])"
        body = [f"// {CELLS[id_][3]}"]
        reps = [("ReferencePseudograph", "ReferencePseudograph")]
        if not c["multi"]:
            reps.append(("UndirectedAdjacencyList", "UndirectedAdjacencyList"))
        for label, typ in reps:
            body.append(f"do {{ // {label}")
            blk = []
            if E:
                blk.append(f"let pairs: [({T}, {T})] = {pairs_lit(E)}")
                blk.append(f"let graph = {typ}(vertices: {arr(V)} as [{T}], edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
            else:
                if typ == "ReferencePseudograph":
                    blk.append(f"let graph = ReferencePseudograph<{T}>(vertices: {arr(V)}, edges: [])")
                else:
                    blk.append(f"let graph = UndirectedAdjacencyList<{T}>(vertices: {arr(V)} as [{T}])")
            if b is None:
                blk.append(f"#expect({call} == nil)")
            else:
                blk.append(f"let bipartite = try #require({call})")
                blk += state_checks(b, "bipartite", T)
                if not c["multi"]:
                    blk.append("// No parallel edges: the graph's positions.")
                    blk.append("#expect(Array(bipartite.edges) == Array(graph.edges))")
                if left is None:
                    blk.append("let bipartition = try #require(graph.bipartition())")
                    blk.append("#expect(Array(bipartite.left) == Array(bipartition.left))")
                    blk.append("#expect(Array(bipartite.right) == Array(bipartition.right))")
            body += ind(blk, 4)
            body.append("}")
        title = f"{id_} {c['name']}" + ("" if b is None else f": L {ref.fmt(b.left())}, R {ref.fmt(b.right())}")
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() throws {{"] + ind(body, 8) + ["    }"]
    out.append("}")
    write("BipartiteGraphFromGraphTests.swift", out)

# ---------------------------------------------------------------------------------------------
# BipartiteGraphSideInitializerTests.swift
# ---------------------------------------------------------------------------------------------

def gen_side_inits():
    out = header([
        "`BipartiteGraph(left:right:)` and `BipartiteGraph(left:right:edges:)` (catalog BP-105 – BP-118):",
        "`left` then `right` in `vertices` order, repeats within a side dropped, edges in order, a",
        "repeat in either orientation once, each stored left endpoint first; nil when the sides",
        "overlap, or an edge is inside a side, a self-loop, or has an endpoint on neither side",
        "(endpoints are never inserted implicitly). Edges are compared as [u, v] to see the stored",
        "orientation. Generated from cases.md by swiftgen.py; see README.md.",
    ], ["BipartiteGraphs", "GraphProtocols", "Testing"],
        "BipartiteGraph(left:right:) and BipartiteGraph(left:right:edges:)", "BipartiteGraphSideInitializerTests")
    for c, id_ in zip(ref.INITS, INITS_IDS):
        left, right, edges = c["left"], c["right"], c["edges"]
        T = ty(left + right, "String")
        b = ref.BG.from_sides(left, right, edges or ())
        exp = "nil" if b is None else b.describe()
        assert CELLS[id_][4] == exp, (id_, CELLS[id_][4], exp)
        expr = side_init_expr(left, right, edges, T)
        body = [f"// {CELLS[id_][3]}"]
        if b is None:
            body.append(f"#expect({expr} == nil)")
        else:
            body.append(f"let graph = try #require({expr})")
            body += state_checks(b, "graph", T)
            body.append(f"#expect(graph.vertexCount == {len(b.vertices())})")
            body.append(f"#expect(graph.edgeCount == {len(b.edges())})")
        title = f"{id_} {c['name']}" + ("" if b is None else f": V {ref.fmt(b.vertices())}, E {ref.fmt_edges(b.edges())}")
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() throws {{"] + ind(body, 8) + ["    }"]
    out.append("}")
    write("BipartiteGraphSideInitializerTests.swift", out)

# ---------------------------------------------------------------------------------------------
# Mutation and precondition rows
# ---------------------------------------------------------------------------------------------

SIDE = {ref.LEFT: ".left", ref.RIGHT: ".right"}


def init_expr(init, T):
    left, right, edges = init
    return side_init_expr(left, right, edges, T)


def op_lines(b, op, T, check=True):
    """Applies op to the model b and returns Swift lines doing and checking the same."""
    k = op[0]
    if not check:
        if k == "iv":
            return [f"graph.insert({lit(op[1])}, on: {SIDE[op[2]]})"]
        if k == "ie":
            return [f"graph.insert(edge: UndirectedEdge({lit(op[1])}, {lit(op[2])}))"]
        if k == "re":
            return [f"graph.remove(edge: UndirectedEdge({lit(op[1])}, {lit(op[2])}))"]
        if k == "rv":
            return [f"graph.remove({lit(op[1])})"]
        if k == "side":
            return [f"_ = graph.side(of: {lit(op[1])})"]
        raise ValueError(op)
    if k == "iv":
        r = b.insert_vertex(op[1], op[2])
        if not check:
            return [f"graph.insert({lit(op[1])}, on: {SIDE[op[2]]})"]
        return [f"do {{ let result = graph.insert({lit(op[1])}, on: {SIDE[op[2]]}); #expect({"" if r else "!"}result.inserted); #expect(result.memberAfterInsert == {lit(op[1])}) }}"]
    if k == "ie":
        r, m = b.insert_edge(op[1], op[2])
        if not check:
            return [f"graph.insert(edge: UndirectedEdge({lit(op[1])}, {lit(op[2])}))"]
        return [f"do {{ let result = graph.insert(edge: UndirectedEdge({lit(op[1])}, {lit(op[2])})); #expect({"" if r else "!"}result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [{lit(m[0])}, {lit(m[1])}]) }}"]
    if k == "re":
        r = b.remove_edge(op[1], op[2])
        if not check:
            return [f"graph.remove(edge: UndirectedEdge({lit(op[1])}, {lit(op[2])}))"]
        if r is None:
            return [f"#expect(graph.remove(edge: UndirectedEdge({lit(op[1])}, {lit(op[2])})) == nil)"]
        return [f"do {{ let removed = graph.remove(edge: UndirectedEdge({lit(op[1])}, {lit(op[2])})); #expect(removed.map {{ [$0.u, $0.v] }} == [{lit(r[0])}, {lit(r[1])}]) }}"]
    if k == "rv":
        r = b.remove_vertex(op[1])
        if not check:
            return [f"graph.remove({lit(op[1])})"]
        return [f"#expect(graph.remove({lit(op[1])}) == {'nil' if r is None else lit(r)})"]
    if k == "rae":
        b.remove_all_edges()
        return ["graph.removeAllEdges()"]
    if k == "ra":
        b.remove_all()
        return ["graph.removeAll()"]
    if k == "side":
        if not check:
            return [f"_ = graph.side(of: {lit(op[1])})"]
        s = b.side_of(op[1])
        return [f"#expect(graph.side(of: {lit(op[1])}) == {SIDE[s]})"]
    if k == "proj":
        p = b.projected(op[1])
        return [f"let projection = graph.projectedGraph(onto: {SIDE[op[1]]})",
                f"#expect(Array(projection.vertices) == {arr(p.verts)} as [{T}])",
                f"#expect(projection.edges.map {{ [$0.u, $0.v] }} == {nested(p.edges())} as [[{T}]])"]
    raise ValueError(op)


def gen_mutation():
    out = header([
        "Mutation (catalog BP-119 – BP-141): `insert(_:on:)`, `insert(edge:)`, `remove(_:)`,",
        "`remove(edge:)`, `removeAllEdges()`, `removeAll()`, with each call's result and the final",
        "`vertices`, `left`, `right` and `edges` (as [u, v], left endpoint first). Removing a vertex",
        "moves the last slot into its place (as `UndirectedAdjacencyList` does) and the side's last",
        "vertex into its place in `left` or `right`; removing an edge moves the last edge into its",
        "position. A vertex keeps its side when its edges go. BP-141 is ref.py's `random_ops(7)`",
        "written out, with every intermediate result as the model gives it. Generated from cases.md",
        "by swiftgen.py; see README.md.",
    ], ["AdjacencyListModule", "BipartiteGraphs", "GraphProtocols", "Testing"],
        "BipartiteGraph mutation", "BipartiteGraphMutationTests")
    for c, id_ in zip(ref.MUT, MUT_IDS):
        ops = ref.random_ops(7) if c["ops"] == "random7" else c["ops"]
        left, right, edges = c["init"]
        allv = list(left) + list(right) + [o[1] for o in ops if o[0] in ("iv", "ie", "re", "rv", "side")]
        T = ty(allv)
        b = ref.BG.from_sides(left, right, edges or ())
        body = [f"// {CELLS[id_][3]}"]
        if not left and not right and not edges:
            body.append(f"var graph = BipartiteGraph<{T}>()")
        else:
            body.append(f"var graph = try #require({init_expr(c['init'], T)})")
        for op in ops:
            body += op_lines(b, op, T)
        assert CELLS[id_][4].endswith(f"final {b.describe()}"), (id_, CELLS[id_][4], b.describe())
        body.append("// Final state.")
        body += state_checks(b, "graph", T)
        title = f"{id_} {c['name']}"
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() throws {{"] + ind(body, 8) + ["    }"]
    out.append("}")
    write("BipartiteGraphMutationTests.swift", out)


def gen_preconditions():
    out = header([
        "Preconditions, as exit tests (catalog BP-142 – BP-149): `insert(_:on:)` with a vertex already",
        "on the other side; `insert(edge:)` inside a side, a self-loop, or with an endpoint that is not",
        "a vertex; `side(of:)` on a non-vertex, also one just removed. Then the same preconditions",
        "the catalog does not list: `side(of:)` on the empty graph, `insert(edge:)` on the empty",
        "graph, and `Bipartition.side(of:)` on a non-vertex and `side(ofIndex:)` out of range. Each",
        "exit test builds its inputs inside the closure. Generated from cases.md by swiftgen.py, the",
        "last test written by hand; see README.md.",
    ], ["AdjacencyListModule", "BipartiteGraphs", "GraphProtocols", "GrafluentTestSupport", "Testing"],
        "BipartiteGraph preconditions", "BipartiteGraphPreconditionTests", tags=".precondition")
    for c, id_ in zip(ref.TRAP, TRAP_IDS):
        T = "String"
        b = ref.BG.from_sides(*[x or () for x in c["init"]])
        mutates = any(op[0] in ("iv", "ie", "re", "rv") for op in c["ops"])
        lines = [f"{'var' if mutates else 'let'} graph = {init_expr(c['init'], T)}!"]
        for op in c["ops"]:
            lines += op_lines(b, op, T, check=False)
        assert ref.apply_ops(c["init"], c["ops"], trap_ok=True)[4]
        title = f"{id_} {c['name']} traps: {CELLS[id_][4][len('trap ('):-1]}"
        body = [f"// {CELLS[id_][3]}", "await #expect(processExitsWith: .failure) {"] + ind(lines, 4) + ["}"]
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() async {{"] + ind(body, 8) + ["    }"]
    out += [
        "",
        '    @Test("side(of:) and insert(edge:) on the empty graph trap: not a vertex")',
        "    func emptyGraph() async {",
        "        await #expect(processExitsWith: .failure) {",
        "            _ = BipartiteGraph<Int>().side(of: 0)",
        "        }",
        "        await #expect(processExitsWith: .failure) {",
        "            var graph = BipartiteGraph<Int>()",
        "            graph.insert(edge: UndirectedEdge(0, 1))",
        "        }",
        "        await #expect(processExitsWith: .failure) {",
        "            // One endpoint present, on the left; the other missing.",
        "            var graph = BipartiteGraph<Int>()",
        "            graph.insert(0, on: .left)",
        "            graph.insert(edge: UndirectedEdge(0, 1))",
        "        }",
        "    }",
        "",
        '    @Test("Bipartition.side(of:) traps on a non-vertex, side(ofIndex:) outside 0..<vertexCount")',
        "    func bipartitionQueries() async {",
        "        await #expect(processExitsWith: .failure) {",
        "            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])",
        "            _ = graph.bipartition()!.side(of: 7)",
        "        }",
        "        await #expect(processExitsWith: .failure) {",
        "            let graph = ReferencePseudograph(edges: [UndirectedEdge(\"a\", \"b\")])",
        "            _ = graph.bipartition()!.side(of: \"z\")",
        "        }",
        "        await #expect(processExitsWith: .failure) {",
        "            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])",
        "            _ = graph.bipartition()!.side(ofIndex: 2)",
        "        }",
        "        await #expect(processExitsWith: .failure) {",
        "            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])",
        "            _ = graph.bipartition()!.side(ofIndex: -1)",
        "        }",
        "        await #expect(processExitsWith: .failure) {",
        "            _ = UndirectedAdjacencyList<Int>().bipartition()!.side(ofIndex: 0)",
        "        }",
        "    }",
        "}",
    ]
    write("BipartiteGraphPreconditionTests.swift", out)


def gen_projection():
    out = header([
        "`projectedGraph(onto:)` (catalog BP-150 – BP-161): the side's vertices in `left` or `right`",
        "order, isolated ones included, and an edge between two of them iff they share a neighbour,",
        "once however many they share, never a self-loop. Positions follow api.md's discovery order",
        "(for each u in side order, each neighbour w in u's row, each x ≠ u in w's row: {u, x}), and",
        "edges are compared as [u, v]. ref.py checks every row against NetworkX 3.7's",
        "`projected_graph`. Generated from cases.md by swiftgen.py; see README.md.",
    ], ["AdjacencyListModule", "BipartiteGraphs", "GraphProtocols", "Testing"],
        "projectedGraph(onto:)", "ProjectionTests")
    for c, id_ in zip(ref.PROJ, PROJ_IDS):
        T = ty(c["left"] + c["right"])
        b = ref.BG.from_sides(c["left"], c["right"], c["edges"])
        p = b.projected(c["side"])
        assert CELLS[id_][4] == f"V {ref.fmt(p.verts)}; E {ref.fmt_edges(p.edges())}"
        body = [f"// {CELLS[id_][3]}",
                f"let graph = try #require({side_init_expr(c['left'], c['right'], c['edges'], T)})",
                f"let projection = graph.projectedGraph(onto: {SIDE[c['side']]})",
                f"#expect(Array(projection.vertices) == {arr(p.verts)} as [{T}])",
                f"#expect(projection.edges.map {{ [$0.u, $0.v] }} == {nested(p.edges())} as [[{T}]])",
                f"#expect(projection.edgeCount == {len(p.edges())})",
                "#expect(projection.edges.allSatisfy { !$0.isSelfLoop })"]
        title = f"{id_} {c['name']}"
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() throws {{"] + ind(body, 8) + ["    }"]
    out.append("}")
    write("ProjectionTests.swift", out)


def gen_equality():
    out = header([
        "Equality (catalog BP-162 – BP-166): vertex sets, edge sets and each vertex's side, not orders",
        "or orientations; the same graph with its sides swapped is a different value. Equal values",
        "hash alike. Generated from cases.md by swiftgen.py; see README.md.",
    ], ["BipartiteGraphs", "GraphProtocols", "Testing"],
        "BipartiteGraph equality", "BipartiteGraphEqualityTests", tags=".conformance")
    for c, id_ in zip(ref.EQ, EQ_IDS):
        a = ref.BG.from_sides(*[x or () for x in c["a"]])
        b = ref.BG.from_sides(*[x or () for x in c["b"]])
        r = a.key() == b.key()
        assert CELLS[id_][4] == str(r).lower()
        body = [f"// {CELLS[id_][3]}",
                f"let a = try #require({init_expr(c['a'], 'String')})",
                f"let b = try #require({init_expr(c['b'], 'String')})",
                f"#expect((a == b) == {str(r).lower()})",
                f"#expect((b == a) == {str(r).lower()})",
                "#expect(a == a && b == b)"]
        if r:
            body.append("#expect(a.hashValue == b.hashValue)")
            body.append("#expect(Set([a, b]).count == 1)")
        else:
            body.append("#expect(Set([a, b]).count == 2)")
        title = f"{id_} {c['name']}: {str(r).lower()}"
        out += ["", f'    @Test("{name_str(title)}")', f"    func {fn(id_)}() throws {{"] + ind(body, 8) + ["    }"]
    out.append("}")
    write("BipartiteGraphEqualityTests.swift", out)


gen_recognition()
gen_representations()
gen_from_graph()
gen_side_inits()
gen_mutation()
gen_preconditions()
gen_projection()
gen_equality()
