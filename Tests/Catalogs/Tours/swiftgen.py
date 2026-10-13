"""Writes the catalog-row test files of Tests/ToursTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 \
        python3 swiftgen.py [OUT_DIR]          # default: Tests/ToursTests

First runs ref.py's catalog with every case builder instrumented, so each row's graph is kept as a
structured value, and checks that the rendered catalog equals cases.md byte for byte. Then
re-evaluates each row with ref.py's models (the definitions, Hierholzer, the depth-first
Hamiltonian search, nearest neighbour, Christofides, 2-opt, Held–Karp), asserts that the value
renders to its catalog cell exactly, and writes one @Test per row.

The representation tests run the rows again on other representations. Each representation lists a
vertex's edges in its own order (`AdjacencyList.undirectedView`: out-edges, then in-edges;
`AdjacencyMatrix` and `CompressedSparseRow`: by neighbour) and some number edges by row-major cell.
For each row and representation the same models run on that representation's rows and positions;
where they give the catalog's walk (its vertices, and the same edges), the test pins it exactly,
and otherwise the test checks that the result is genuine (every edge once, consecutive edges, the
documented start) and that it exists exactly when the catalog's does. Hand-written tests spliced
in: extra_traps.swift (preconditions the catalog does not list).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "ToursTests")
os.chdir(HERE)
import ref  # noqa: E402

RECORDS = {}


def instrument(kind, fn):
    def wrapper(*args, **kwargs):
        start = len(ref.CASES)
        r = fn(*args, **kwargs)
        for i in range(start, len(ref.CASES)):
            RECORDS[i] = (kind, args, kwargs)
        return r
    return wrapper


for kind, name in [("euler", "euler_rows"), ("cfrom", "circuit_from_rows"), ("tfrom", "trail_from_rows"),
                   ("trap", "trap"), ("ham", "ham_rows"), ("hfrom", "ham_from_rows"), ("nn", "nn_rows"),
                   ("chr", "christofides_rows"), ("two", "two_opt_rows"), ("hk", "shortest_rows")]:
    setattr(ref, name, instrument(kind, getattr(ref, name)))
ref.build()
assert not ref.FAILS, ref.FAILS
TOTAL = len(ref.CASES)
assert TOTAL == 531

text = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == text, "cases.md is not ref.py's output"

CELLS = {}
for line in text.splitlines():
    if line.startswith("| TO-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[parts[0]] = parts
assert len(CELLS) == TOTAL


def cid_of(i):
    return f"TO-{i + 1:03d}"


# ---------------------------------------------------------------------------------------------
# Rows as structured values
# ---------------------------------------------------------------------------------------------


class Row:
    """One catalog row: its graph and what the call asks for."""

    def __init__(self, cid, kind, group, g, call, start=None, target=None, initial=None):
        self.cid, self.kind, self.group, self.g, self.call = cid, kind, group, g, call
        self.start, self.target, self.initial = start, target, initial

    @property
    def what(self):
        """isE, hasT, circuit, trail, path, cycle, nn, chr, two, hk."""
        grp = self.group.replace("Directed", "")
        return {"IsEulerian": "isE", "HasEulerianTrail": "hasT", "EulerianCircuit": "circuit",
                "EulerianCircuitFrom": "circuit", "EulerianTrail": "trail", "EulerianTrailFrom": "trail",
                "HamiltonianPath": "path", "HamiltonianPathFrom": "path", "HamiltonianCycle": "cycle",
                "NearestNeighborTour": "nn", "ChristofidesTour": "chr", "TwoOptTour": "two",
                "TwoOptTourImproving": "two", "ShortestTour": "hk"}[grp]


ROWS = []
for i in range(TOTAL):
    cid = cid_of(i)
    kind, args, kwargs = RECORDS[i]
    group = CELLS[cid][1]
    call = CELLS[cid][4].strip("`")
    if kind == "trap":
        ROWS.append(Row(cid, kind, group, None, call))
    elif kind == "euler":
        ROWS.append(Row(cid, kind, group, args[2], call))
    elif kind in ("cfrom", "tfrom"):
        ROWS.append(Row(cid, kind, group, args[2], call, start=args[3]))
    elif kind == "ham":
        ROWS.append(Row(cid, kind, group, args[1], call))
    elif kind == "hfrom":
        ROWS.append(Row(cid, kind, group, args[1], call, start=args[2], target=args[3] if len(args) > 3 else kwargs.get("t")))
    elif kind == "nn":
        st = args[2] if len(args) > 2 else kwargs.get("start")
        ROWS.append(Row(cid, kind, group, args[1], call, start=st))
    elif kind in ("chr", "hk"):
        ROWS.append(Row(cid, kind, group, args[1], call))
    elif kind == "two":
        ini = args[2] if len(args) > 2 else kwargs.get("initial")
        ROWS.append(Row(cid, kind, group, args[1], call, initial=ini))
    else:
        raise ValueError(kind)


# ---------------------------------------------------------------------------------------------
# Representations: their rows and positions, in catalog terms
# ---------------------------------------------------------------------------------------------


def repeated_arc(g):
    return len(set(g.E)) != len(g.E)


def primary(g):
    if g.directed:
        return "dpseudo" if g.multi() else "al"
    return "pseudo" if g.multi() else "ual"


REP_NAMES = {
    "al": "AdjacencyList", "dpseudo": "DirectedPseudograph", "refd": "ReferenceDirectedMultigraph",
    "unidx": "no indices", "csr": "CompressedSparseRow", "am": "AdjacencyMatrix",
    "ual": "UndirectedAdjacencyList", "pseudo": "Pseudograph", "refu": "ReferencePseudograph",
    "unidxu": "no indices", "alu": "AdjacencyList.undirectedView", "amu": "AdjacencyMatrix.undirectedView",
}


def reps(g):
    """The representations a row runs on again, after its primary one."""
    if g.directed:
        out = ["refd" if primary(g) == "dpseudo" else "dpseudo", "unidx"]
        if not repeated_arc(g):
            out += ["csr", "am"]
        return out
    out = ["refu" if primary(g) == "pseudo" else "pseudo", "unidxu"]
    if not repeated_arc(g):
        out += ["alu", "amu"]
    return out


def index_form(rep):
    return rep in ("csr", "am", "amu")


def rep_order(g, rep):
    """Catalog edge numbers in the representation's position order."""
    if index_form(rep):
        return sorted(range(g.m), key=lambda k: g.E[k])
    return list(range(g.m))


def rep_rows(g, rep):
    """Each vertex's row on the representation, as (catalog edge, neighbour)."""
    n = g.n
    if rep == "alu":
        rows = [[] for _ in range(n)]
        for v in range(n):
            rows[v] = [(e, b) for e, (a, b) in enumerate(g.E) if a == v] + [(e, a) for e, (a, b) in enumerate(g.E) if b == v]
        return rows
    if rep == "amu":
        rows = [[] for _ in range(n)]
        for v in range(n):
            out = sorted((b, e) for e, (a, b) in enumerate(g.E) if a == v)
            inn = sorted((a, e) for e, (a, b) in enumerate(g.E) if b == v)
            rows[v] = [(e, b) for b, e in out] + [(e, a) for a, e in inn]
        return rows
    if rep in ("csr", "am"):
        rows = [[] for _ in range(n)]
        for v in range(n):
            rows[v] = [(e, b) for b, e in sorted((b, e) for e, (a, b) in enumerate(g.E) if a == v)]
        return rows
    return g.rows()


class RepG(ref.G):
    """The row's graph as a representation holds it: edges at its positions, its rows."""

    def __init__(self, g, rep):
        self.order = rep_order(g, rep)
        inv = {k: r for r, k in enumerate(self.order)}
        super().__init__(g.labels, [(g.labels[g.E[k][0]], g.labels[g.E[k][1]]) for k in self.order], g.directed,
                         w=None if g.w is None else [g.w[k] for k in self.order], token=g.token, wtype=g.wtype)
        self._rows = [[(inv[e], x) for e, x in r] for r in rep_rows(g, rep)]

    def rows(self, order="position"):
        return [list(r) for r in self._rows]


class Same(ref.G):
    """The catalog's own representation (position order), with the same interface as RepG."""

    def __init__(self, g):
        super().__init__(g.labels, [(g.labels[u], g.labels[v]) for u, v in g.E], g.directed, w=g.w, token=g.token, wtype=g.wtype)
        self.order = list(range(g.m))


# ---------------------------------------------------------------------------------------------
# The models, per row
# ---------------------------------------------------------------------------------------------


def evaluate(row, view):
    """The model's answer on `view` (Same or RepG): a bool, None, or (vertex indices, catalog edges)."""
    w = row.what
    g = view
    if w == "isE":
        return ref.euler_status(g)[0]
    if w == "hasT":
        return ref.euler_status(g)[1]
    if w == "circuit":
        res = ref.euler_circuit(g, row.start)
    elif w == "trail":
        res = ref.euler_trail(g, row.start)
    elif w == "path":
        res = ref.ham_path(g, row.start, row.target)
    elif w == "cycle":
        res = ref.ham_cycle(g)
    elif w == "nn":
        order = ref.nearest_neighbor(g, 0 if row.start is None else row.start)
        res = None if order is None else ref.tour_of(g, order)[:2]
    elif w == "chr":
        r = ref.christofides(g)
        res = None if r is None else ref.tour_of(g, r[0])[:2]
    elif w == "two":
        if g.n < 3:
            res = None
        else:
            st = ref.nearest_neighbor(g, 0) if row.initial is None else row.initial
            res = ref.tour_of(g, ref.two_opt(g, st))[:2]
    elif w == "hk":
        order = ref.held_karp(g)
        res = None if order is None else ref.tour_of(g, order)[:2]
    else:
        raise ValueError(w)
    if res is None:
        return None
    vs, es = res
    return list(vs), [view.order[e] for e in es]


def is_tour(row):
    return row.what in ("nn", "chr", "two", "hk")


def expected_cell(row, res):
    g = row.g
    w = row.what
    if w in ("isE", "hasT"):
        return str(res).lower()
    if is_tour(row):
        return ref.tour_text(g, None if res is None else res[0])
    kind = {"circuit": "circuit", "trail": "trail", "path": "path", "cycle": "cycle"}[w]
    return ref.show_walk(g, kind, res)


def verify(row):
    res = evaluate(row, Same(row.g))
    exp = expected_cell(row, res)
    assert CELLS[row.cid][5] == exp, (row.cid, CELLS[row.cid][5], exp)
    return res


# ---------------------------------------------------------------------------------------------
# Literals
# ---------------------------------------------------------------------------------------------


def lit(x):
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, str):
        return json.dumps(x, ensure_ascii=False)
    if isinstance(x, float):
        if x != x:
            return ".nan"
        return repr(x)
    return str(x)


def arr(xs):
    return "[" + ", ".join(lit(x) for x in xs) + "]"


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def vtype(g):
    return "String" if any(isinstance(x, str) for x in g.labels) else "Int"


def wtype(g):
    return "Double" if g.wtype == "Double" else "Int"


def labels_of(g, idxs, rep):
    if index_form(rep):
        return list(idxs)
    return [g.labels[i] for i in idxs]


def vlist(g, rep):
    if index_form(rep):
        return f"{arr(range(g.n))} as [Int]"
    return f"{arr(g.labels)} as [{vtype(g)}]"


def vertex_arg(g, rep, i):
    return lit(i) if index_form(rep) else lit(g.labels[i])


def pairs_line(g, rep):
    if index_form(rep):
        T = "Int"
        ps = list(g.E)
    else:
        T = vtype(g)
        ps = [(g.labels[u], g.labels[v]) for u, v in g.E]
    return f"let pairs: [({T}, {T})] = [" + ", ".join(f"({lit(u)}, {lit(v)})" for u, v in ps) + "]"


def weights_line(g):
    return f"let weights: [{wtype(g)}] = {arr(g.w)}"


def graph_line(g, rep):
    T = "Int" if index_form(rep) else vtype(g)
    V = vlist(g, rep)
    n = g.n
    de = "pairs.map { DirectedEdge(from: $0.0, to: $0.1) }"
    ue = "pairs.map { UndirectedEdge($0.0, $0.1) }"
    return {
        "al": f"let graph = AdjacencyList<{T}>(vertices: {V}, edges: {de})",
        "dpseudo": f"let graph = DirectedPseudograph<{T}>(vertices: {V}, edges: {de})",
        "refd": f"let graph = ReferenceDirectedMultigraph<{T}>(vertices: {V}, edges: {de})",
        "unidx": f"let graph = UnindexedDirectedGraph<{T}>(vertices: {V}, edges: {de})",
        "csr": f"let graph = CompressedSparseRow(vertexCount: {n}, edges: {de})",
        "am": f"let graph = AdjacencyMatrix(vertexCount: {n}, edges: {de})",
        "ual": f"let graph = UndirectedAdjacencyList<{T}>(vertices: {V}, edges: {ue})",
        "pseudo": f"let graph = Pseudograph<{T}>(vertices: {V}, edges: {ue})",
        "refu": f"let graph = ReferencePseudograph<{T}>(vertices: {V}, edges: {ue})",
        "unidxu": f"let graph = UnindexedGraph<{T}>(vertices: {V}, edges: {ue})",
        "alu": f"let graph = AdjacencyList<{T}>(vertices: {V}, edges: {de}).undirectedView",
        "amu": f"let graph = AdjacencyMatrix(vertexCount: {n}, edges: {de}).undirectedView",
    }[rep]


def prelude(row, rep):
    """The graph, its vertex list, and `ends` (each edge's ends as vertex indices, by catalog edge)."""
    g = row.g
    L = [pairs_line(g, rep)]
    if g.w is not None:
        L.append(weights_line(g))
    L.append(graph_line(g, rep))
    if rep in ("unidx", "unidxu"):
        L.append("#expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)")
    L += ["let vertexList = Array(graph.vertices)",
          f"#expect(vertexList == {vlist(g, rep)})"]
    if index_form(rep):
        if rep == "amu":
            find = "graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }!"
        else:
            find = "graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }!"
        L += ["// Positions here are row-major cells: each catalog edge's position, and back.",
              f"let positionOfEdge = pairs.map {{ p in {find} }}",
              "let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })",
              "#expect(edgeOf.count == pairs.count && graph.edges.count == pairs.count)"]
    elif g.directed:
        L.append("#expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })")
    else:
        L.append("#expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })")
    L += ["let n = vertexList.count",
          "// Each edge's ends as vertex indices (positions in `vertices`), by catalog edge."]
    if index_form(rep):
        L.append("let ends = pairs")
    else:
        L.append("let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }")
    return L


def walked_expr(var, rep):
    return f"{var}.edges.map {{ edgeOf[$0]! }}" if index_form(rep) else f"{var}.edges"


def weight_closure(rep):
    return "{ weights[edgeOf[$0]!] }" if index_form(rep) else "{ weights[$0] }"


def call_expr(row, rep, closure=None):
    """The call on `graph`, its vertex arguments in the representation's terms."""
    g = row.g
    w = row.what
    if w == "isE":
        return "graph.isEulerian"
    if w == "hasT":
        return "graph.hasEulerianTrail"
    if w == "circuit":
        return "graph.eulerianCircuit()" if row.start is None else f"graph.eulerianCircuit(from: {vertex_arg(g, rep, row.start)})"
    if w == "trail":
        return "graph.eulerianTrail()" if row.start is None else f"graph.eulerianTrail(from: {vertex_arg(g, rep, row.start)})"
    if w == "path":
        if row.start is None:
            return "graph.hamiltonianPath()"
        if row.target is None:
            return f"graph.hamiltonianPath(from: {vertex_arg(g, rep, row.start)})"
        return f"graph.hamiltonianPath(from: {vertex_arg(g, rep, row.start)}, to: {vertex_arg(g, rep, row.target)})"
    if w == "cycle":
        return "graph.hamiltonianCycle()"
    cl = closure if closure is not None else f"weight: {weight_closure(rep)}"
    if w == "nn":
        if row.start is None:
            return f"graph.nearestNeighborTour({cl})"
        return f"graph.nearestNeighborTour(from: {vertex_arg(g, rep, row.start)}, {cl})"
    if w == "chr":
        return f"graph.christofidesTour({cl})"
    if w == "two":
        if row.initial is None:
            return f"graph.twoOptTour({cl})"
        return f"graph.twoOptTour(improving: start, {cl})"
    if w == "hk":
        return f"graph.shortestTour({cl})"
    raise ValueError(w)


def trailing_call(row, rep):
    """The call with a trailing closure that records each position asked."""
    e = call_expr(row, rep, closure="weight: §")
    head, tail = e.split("weight: §")
    assert tail == ")"
    head = head.rstrip(", ")
    if head.endswith("("):
        head = head[:-1]
    else:
        head += ")"
    return head


# ---------------------------------------------------------------------------------------------
# In-test checks
# ---------------------------------------------------------------------------------------------


def degree_lines(g):
    if g.directed:
        return ["// Degrees, counted here: a self-loop is one edge out and one in.",
                "var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)",
                "for (a, b) in ends {",
                "    outDegree[a] += 1",
                "    inDegree[b] += 1",
                "}"]
    return ["// Degrees, counted here: a self-loop adds 2.",
            "var degree = [Int](repeating: 0, count: n)",
            "for (a, b) in ends {",
            "    degree[a] += 1",
            "    degree[b] += 1",
            "}"]


def connected_lines():
    return ["// The vertices with edges in one (weakly) connected component: union–find over the edges.",
            "var parent = Array(0 ..< n)",
            "func root(_ x: Int) -> Int {",
            "    var x = x",
            "    while parent[x] != x { x = parent[x] }",
            "    return x",
            "}",
            "for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }",
            "let components = Set(ends.map { root($0.0) }).count"]


def definition_lines(row):
    g = row.g
    L = degree_lines(g) + connected_lines()
    if g.directed:
        L += ["let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }",
              "let balanced = surplus.allSatisfy { $0 == 0 }",
              "let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }",
              "// The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.",
              "#expect(graph.isEulerian == (components <= 1 && balanced))",
              "#expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))"]
    else:
        L += ["let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }",
              "// The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.",
              "#expect(graph.isEulerian == (components <= 1 && odd.isEmpty))",
              "#expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))"]
    L += ["// And as api.md relates them to the walks.",
          "#expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))",
          "#expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))"]
    return L


def join_check(g, var="k"):
    if g.directed:
        return [f"let (a, b) = ends[{var}]", "#expect(a == x && b == y, \"step \\(i)\")"]
    return [f"let (a, b) = ends[{var}]", "#expect((a == x && b == y) || (a == y && b == x), \"step \\(i)\")"]


def euler_genuine(row, var, closed, start_index, rep):
    g = row.g
    L = [f"let walked = {walked_expr(var, rep)}",
         f"let at = {var}.vertices.map {{ vertexList.firstIndex(of: $0)! }}",
         "// Genuine, checked here: every edge exactly once, edge i joining vertex i and the next" +
         (" (the last back to the first)." if closed else "."),
         "#expect(walked.sorted() == Array(pairs.indices))",
         f"#expect(at.count == walked.count{'' if closed else ' + 1'})",
         "for (i, k) in walked.enumerated() {",
         f"    let x = at[i], y = {'at[(i + 1) % at.count]' if closed else 'at[i + 1]'}"]
    L += ["    " + l for l in join_check(g)]
    L.append("}")
    T = "Circuit" if closed else "Trail"
    L.append(f"#expect({T}(vertices: {var}.vertices, edges: {var}.edges, in: graph) != nil)")
    L.append(f"// The documented start: {start_doc(row)}.")
    L.append(f"#expect(at.first == {start_index})")
    return L


def start_doc(row):
    g = row.g
    if row.start is not None:
        return "the given vertex"
    if row.what == "circuit":
        return "the first vertex with an edge"
    eu, tr, s0 = ref.euler_status(g)
    if g.m == 0:
        return "the first vertex (no edges: the trivial trail)"
    if eu:
        return "Eulerian, so the first vertex with an edge"
    return "the vertex with out − in = 1" if g.directed else "the first odd vertex"


def euler_start(row):
    g = row.g
    if row.start is not None:
        return row.start
    if row.what == "circuit":
        return min(v for v in range(g.n) if ref.deg(g, v))
    return ref.euler_status(g)[2]


def ham_genuine(row, var, closed, rep):
    g = row.g
    L = [f"let walked = {walked_expr(var, rep)}",
         f"let at = {var}.vertices.map {{ vertexList.firstIndex(of: $0)! }}",
         "// Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next" +
         (" (the last back to the first), no edge twice." if closed else "."),
         "#expect(at.sorted() == Array(0 ..< n))",
         f"#expect(walked.count == {'n' if closed else 'n - 1'} && Set(walked).count == walked.count)",
         "for (i, k) in walked.enumerated() {",
         f"    let x = at[i], y = {'at[(i + 1) % n]' if closed else 'at[i + 1]'}"]
    L += ["    " + l for l in join_check(g)]
    L.append("}")
    T = "Cycle" if closed else "Path"
    L.append(f"#expect({T}(vertices: {var}.vertices, edges: {var}.edges, in: graph) != nil)")
    return L


def lightest_lines(g):
    if g.directed:
        return ["// The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);",
                "// self-loops ignored. `d` is its weight.",
                "var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)",
                "for k in pairs.indices where ends[k].0 != ends[k].1 {",
                "    let (a, b) = ends[k]",
                "    if let e = lightest[a][b], weights[e] <= weights[k] { continue }",
                "    lightest[a][b] = k",
                "}",
                f"let d: (Int, Int) -> {wtype(g)} = {{ weights[lightest[$0][$1]!] }}"]
    return ["// The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops",
            "// ignored. `d` is its weight.",
            "var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)",
            "for k in pairs.indices where ends[k].0 != ends[k].1 {",
            "    let (a, b) = ends[k]",
            "    if let e = lightest[a][b], weights[e] <= weights[k] { continue }",
            "    lightest[a][b] = k",
            "    lightest[b][a] = k",
            "}",
            f"let d: (Int, Int) -> {wtype(g)} = {{ weights[lightest[$0][$1]!] }}"]


def tour_genuine(row, var, rep):
    L = ham_genuine(row, var, True, rep)
    L += ["// Each step through its pair's lightest edge.",
          "for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], \"step \\(i)\") }"]
    return L


def brute_ham_lines(row):
    """Existence by every ordering of the vertices (n ≤ 8)."""
    g = row.g
    cyc = row.what == "cycle"
    L = ["// Brute force, checked here: some ordering of the vertices with an edge from each to the next" +
         (" (and back to the first; a self-loop is the cycle of one vertex, two edges that of two)." if cyc else "."),
         "var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)"]
    if cyc:
        L += ["var loops = [Int](repeating: 0, count: n)",
              "for (a, b) in ends {",
              "    if a == b {",
              "        loops[a] += 1",
              "    } else {",
              "        joins[a][b] += 1"]
        if not g.directed:
            L.append("        joins[b][a] += 1")
        L += ["    }", "}"]
    else:
        L += ["for (a, b) in ends where a != b {", "    joins[a][b] += 1"]
        if not g.directed:
            L.append("    joins[b][a] += 1")
        L.append("}")
    if cyc:
        if g.directed:
            cond = "n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 })"
        else:
            cond = "n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 })"
    else:
        cond = "(0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 })"
    s, t = row.start, row.target
    if s is not None:
        cond = f"order[0] == {s} && " + ("(" + cond + ")" if "?" in cond else cond)
    if t is not None:
        cond = f"order[n - 1] == {t} && " + cond
    L += ["var order = Array(0 ..< n)",
          "var exists = false"]
    if row.what == "path" and s is None:
        L.append("var firstStart = n")
    L += ["while true {",
          f"    if {cond} {{"]
    if row.what == "path" and s is None:
        L += ["        exists = true",
              "        firstStart = min(firstStart, order[0])"]
    else:
        L += ["        exists = true", "        break"]
    L += ["    }",
          "    // The next permutation, in lexicographic order.",
          "    var i = n - 2",
          "    while i >= 0 && order[i] >= order[i + 1] { i -= 1 }",
          "    if i < 0 { break }",
          "    var j = n - 1",
          "    while order[j] <= order[i] { j -= 1 }",
          "    order.swapAt(i, j)",
          "    order[(i + 1)...].reverse()",
          "}"]
    return L


def brute_tsp_lines(g, least=True):
    """The optimum and the lexicographically least optimal tour from the first vertex (n ≤ 9)."""
    W = wtype(g)
    L = ["// Brute force, checked here: every ordering of the other vertices after the first; the least weight" +
         (",\n// and the first such ordering in lexicographic order." if least else "."),
         "var order = Array(0 ..< n)",
         f"var optimum: {W}? = nil"]
    if least:
        L.append("var best: [Int] = []")
    L += [
            "while true {",
            "    if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {",
            f"        var total: {W} = 0",
            "        for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }",
            "        if optimum == nil || total < optimum! {",
            "            optimum = total"] + (["            best = order"] if least else []) + [
            "        }",
            "    }",
            "    var i = n - 2",
            "    while i >= 1 && order[i] >= order[i + 1] { i -= 1 }",
            "    if i < 1 { break }",
            "    var j = n - 1",
            "    while order[j] <= order[i] { j -= 1 }",
            "    order.swapAt(i, j)",
            "    order[(i + 1)...].reverse()",
            "}"]
    return [y for x in L for y in x.split("\n")]


def asked_lines(row, var):
    return ["var asked: [Int] = []",
            f"let {var} = {trailing_call(row, 'p')} {{ position in",
            "    asked.append(position)",
            "    return weights[position]",
            "}",
            "// `weight` is called once per non-loop edge, in position order.",
            "#expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })"]


def opt_of(g):
    if g.n < 3 or g.n > 9:
        return None
    b = ref.brute_tsp(g)
    return None if b is None else b[0]


def walk_label(row):
    return {"circuit": "circuit", "trail": "trail", "path": "path", "cycle": "cycle"}.get(row.what, "tour")


def exact_lines(row, var, res, rep):
    g = row.g
    T = "Int" if index_form(rep) else vtype(g)
    vs, es = res
    return [f"#expect({var}.vertices == {arr(labels_of(g, vs, rep))} as [{T}])",
            f"#expect({walked_expr(var, rep)} == {arr(es)} as [Int])"]


# ---------------------------------------------------------------------------------------------
# Row bodies
# ---------------------------------------------------------------------------------------------


def comment_input(cid):
    parts = CELLS[cid]
    s = f"{parts[3]}; {parts[4]}".replace("`", "")
    if len(s) > 200:
        s = s[:197] + "…"
    return "// " + s


def title(cid, maxlen=118):
    parts = CELLS[cid]
    name, exp = parts[2], parts[5]
    t = f"{cid} {name}"
    if len(t) + len(exp) + 2 <= maxlen:
        t += ": " + exp
    return esc(t)


def fname(cid):
    return "to" + cid[3:]


def indent(lines, n):
    pad = " " * n
    return [(pad + l) if l else "" for l in lines]


def unused_cleanup(lines):
    """Drop `let name = …` lines whose name is never read later (warnings are errors), to a fixpoint."""
    lines = list(lines)
    changed = True
    while changed:
        changed = False
        for i, l in enumerate(lines):
            m = re.match(r"^\s*let (\w+)(?:: [^=]+)? = ", l)
            if not m or "{" in l and l.rstrip().endswith("{"):
                continue
            name = m.group(1)
            rest = "\n".join(re.sub(r'"[^"\\]*"', '""', x.split("// ")[0] if x.strip().startswith("//") else x) for x in lines[i + 1:])
            if not re.search(r"(?<![\w.])" + name + r"(?!\w)", rest):
                del lines[i]
                changed = True
                break
    return lines


def emit_test(cid, ttl, body, throws=False):
    sig = f"func {fname(cid)}() throws {{" if throws else f"func {fname(cid)}() {{"
    return indent([f'@Test("{ttl}")', sig], 4) + indent(body, 8) + ["    }", ""]


def result_lines(row, rep, res, exact, primary_row):
    """The call and every check of its result, on `graph` (built by prelude)."""
    g = row.g
    w = row.what
    L = []
    if w in ("isE", "hasT"):
        L.append(f"#expect({call_expr(row, rep)} == {lit(res)})")
        if primary_row:
            L += definition_lines(row)
        return L
    if is_tour(row):
        if row.initial is not None:
            vs = labels_of(g, row.initial, rep)
            T = "Int" if index_form(rep) else vtype(g)
            L.append(f"let start = try #require(Cycle({arr(vs)} as [{T}], in: graph))")
        if res is None:
            L.append(f"#expect({call_expr(row, rep)} == nil)")
            if primary_row and g.n >= 3:
                L += ["// No Hamiltonian cycle at all.", "#expect(graph.hamiltonianCycle() == nil)"]
            return L
        if primary_row:
            L += asked_lines(row, "result")
        else:
            L.append(f"let result = {call_expr(row, rep)}")
        L.append("let tour = try #require(result)")
        total = ref.tour_of(g, res[0])[2]
        if exact:
            L += exact_lines(row, "tour", res, rep)
        else:
            L.append("// Not pinned here: this representation numbers the edges differently, which changes ties.")
        L.append(f"#expect(tour.weight({weight_closure(rep)}) == {lit(total)})" if exact else
                 f"let total = tour.weight({weight_closure(rep)})")
        L += lightest_lines(g)
        L += tour_genuine(row, "tour", rep)
        first = row.start if (w == "nn" and row.start is not None) else (row.initial[0] if row.initial is not None else 0)
        L.append("// It starts at " + ("the given vertex." if w == "nn" and row.start is not None else
                                        "the first vertex of the tour it improves." if row.initial is not None else
                                        "the first vertex."))
        L.append(f"#expect(at[0] == {first})")
        wt = "weight" if exact else "total"
        if exact:
            L.append(f"let {wt} = tour.weight({weight_closure(rep)})")
        if w == "nn" and primary_row:
            L += ["// The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`",
                  "// order on ties.",
                  "var visited = [Bool](repeating: false, count: n)",
                  "visited[at[0]] = true",
                  "for i in 1 ..< n {",
                  "    let from = at[i - 1]",
                  "    let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!",
                  "    #expect(at[i] == nearest, \"step \\(i)\")",
                  "    visited[at[i]] = true",
                  "}"]
        if w == "two":
            L += ["// 2-optimal, checked here: no two edges (a, b), (c, e) whose exchange for (a, c), (b, e) is lighter.",
                  "for i in 0 ..< n {",
                  "    for j in 0 ..< n where j >= i + 2 && !(i == 0 && j == n - 1) {",
                  "        let a = at[i], b = at[i + 1], c = at[j], e = at[(j + 1) % n]",
                  "        #expect(!(d(a, c) + d(b, e) < d(a, b) + d(c, e)), \"move \\(i), \\(j)\")",
                  "    }",
                  "}"]
            if row.initial is None:
                L += ["// No heavier than the nearest-neighbour tour it starts from.",
                      f"let first = try #require(graph.nearestNeighborTour(weight: {weight_closure(rep)}))",
                      f"#expect({wt} <= first.weight({weight_closure(rep)}))"]
            else:
                L += ["// No heavier than the tour it improves.",
                      f"#expect({wt} <= start.weight({weight_closure(rep)}))"]
        if primary_row and g.n <= 9:
            L += brute_tsp_lines(g, w == "hk")
            if w == "hk":
                L += [f"#expect({wt} == optimum)", "#expect(at == best)"]
            else:
                L.append(f"#expect({wt} >= optimum!)")
                if w == "chr" and ref.is_metric(g):
                    L += ["// The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.",
                          f"#expect(2 * {wt} <= 3 * optimum!)"]
        elif w == "chr" and not exact and ref.is_metric(g) and opt_of(g) is not None:
            L += [f"// The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum, {lit(opt_of(g))}.",
                  f"#expect(2 * {wt} <= 3 * {lit(opt_of(g))})"]
        return L
    # Walks
    var = walk_label(row)
    call = call_expr(row, rep)
    if res is None:
        L.append(f"#expect({call} == nil)")
        if primary_row and w in ("path", "cycle") and 1 <= g.n <= 8:
            L += brute_ham_lines(row)
            L.append("#expect(!exists)")
        return L
    L.append(f"let {var} = try #require({call})")
    if exact:
        L += exact_lines(row, var, res, rep)
    else:
        L.append("// Not pinned here: this representation lists each vertex's edges in another order, which the walk follows.")
    if w in ("circuit", "trail"):
        if g.m == 0:
            L += [f"// No edges: the trivial trail at {'the given vertex' if row.start is not None else 'the first vertex'}.",
                  f"#expect({var}.edges.isEmpty && {var}.vertices == [{vertex_arg(g, rep, euler_start(row))}])"]
        else:
            L += euler_genuine(row, var, w == "circuit", euler_start(row), rep)
    else:
        L += ham_genuine(row, var, w == "cycle", rep)
        if w == "cycle":
            L += ["// The search starts at the first vertex.", "#expect(at[0] == 0)"]
        else:
            if row.start is not None:
                L += ["// From the given start.", f"#expect(at[0] == {row.start})"]
            else:
                L += ["// The first vertex from which some Hamiltonian path starts.", f"#expect(at[0] == {res[0][0]})"]
            if row.target is not None:
                L += ["// To the given end.", f"#expect(at[n - 1] == {row.target})"]
        if primary_row and 1 <= g.n <= 8:
            L += brute_ham_lines(row)
            L.append("#expect(exists)")
            if w == "path" and row.start is None:
                L.append("#expect(at[0] == firstStart)")
    return L


def body_row(row):
    res = verify(row)
    rep = primary(row.g)
    L = [comment_input(row.cid)] + prelude(row, rep)
    L += result_lines(row, rep, res, True, True)
    return L


def rep_test(row):
    res = verify(row)
    rs = reps(row.g)
    names = ", ".join(REP_NAMES[r] for r in rs)
    t = esc(f"{row.cid} {CELLS[row.cid][2]}, on {names}")
    body = [comment_input(row.cid)]
    needs_throw = False
    exact_all = True
    for r in rs:
        here = evaluate(row, RepG(row.g, r))
        if (here is None) != (res is None):
            raise AssertionError((row.cid, r, "existence differs"))
        exact = here == res
        exact_all &= exact
        block = unused_cleanup(prelude(row, r) + result_lines(row, r, res, exact, False))
        if any("try #require" in l for l in block):
            needs_throw = True
        body += [f"do {{ // {REP_NAMES[r]}"] + indent(block, 4) + ["}"]
    STATS["rep_blocks"] += len(rs)
    return emit_test(row.cid, t, body, throws=needs_throw), exact_all


STATS = {"rep_blocks": 0, "rep_validity": 0}


# ---------------------------------------------------------------------------------------------
# Traps
# ---------------------------------------------------------------------------------------------

C3 = "UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])"
P3 = "UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])"
CD3 = "AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])"
PD3 = "AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])"
C4 = "UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])"
SQ = ("UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), "
      "UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])")
SQW = "let weights = [1, 2, 1, 1, 2, 1]  // Manhattan distances of (0,0), (0,1), (1,1), (1,0)"
K3 = "UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])"
K3W = "let weights: [Double] = [1.0, .nan, 2.0]"
TRAPS = {
    "TO-285": (C3, "_ = graph.eulerianCircuit(from: 7)"),
    "TO-286": (P3, "_ = graph.eulerianTrail(from: 7)"),
    "TO-287": (CD3, "_ = graph.eulerianCircuit(from: 7)"),
    "TO-288": (PD3, "_ = graph.eulerianTrail(from: 7)"),
    "TO-289": ("UndirectedAdjacencyList<Int>(vertices: [], edges: [])", "_ = graph.eulerianCircuit(from: 0)"),
    "TO-397": (P3, "_ = graph.hamiltonianPath(from: 7)"),
    "TO-398": (P3, "_ = graph.hamiltonianPath(from: 0, to: 7)"),
    "TO-399": (PD3, "_ = graph.hamiltonianPath(from: 7)"),
    "TO-492": (C4, "_ = graph.nearestNeighborTour(weight: { _ in 1 })"),
    "TO-493": (C4, "_ = graph.christofidesTour(weight: { _ in 1 })"),
    "TO-494": (C4, "_ = graph.twoOptTour(weight: { _ in 1 })"),
    "TO-495": (SQ, f"{SQW}\nlet tour = Cycle([0, 1, 2], in: graph)!\n_ = graph.twoOptTour(improving: tour, weight: {{ weights[$0] }})"),
    "TO-496": (SQ, f"{SQW}\n// A `Cycle` cannot repeat a vertex (`Cycle(vertices: [0, 1, 2, 1], …)` is nil, checked in the test\n"
                   f"// above), so four vertices with one that is not the graph's stand for a tour that does not list\n"
                   f"// every vertex once.\nlet tour = Cycle(vertices: [0, 1, 2, 9], edges: [0, 3, 5, 2])!\n"
                   f"_ = graph.twoOptTour(improving: tour, weight: {{ weights[$0] }})"),
    "TO-497": (SQ, f"{SQW}\n_ = graph.nearestNeighborTour(from: 7, weight: {{ weights[$0] }})"),
    "TO-498": (K3, f"{K3W}\n_ = graph.nearestNeighborTour(weight: {{ weights[$0] }})"),
    "TO-499": (K3, f"{K3W}\n_ = graph.christofidesTour(weight: {{ weights[$0] }})"),
    "TO-500": (K3, f"{K3W}\n_ = graph.shortestTour(weight: {{ weights[$0] }})"),
    "TO-501": ("UndirectedAdjacencyList<Int>(vertices: 0 ..< 32, edges: (0 ..< 32).flatMap { i in (i + 1 ..< 32).map { UndirectedEdge(i, $0) } })",
               "_ = graph.shortestTour(weight: { _ in 1 })"),
    "TO-502": ("UndirectedAdjacencyList<Int>(vertices: 0 ..< 26, edges: (0 ..< 26).flatMap { i in (i + 1 ..< 26).map { UndirectedEdge(i, $0) } })",
               "_ = graph.shortestTour(weight: { _ in 1 })"),
    "TO-503": (K3, "let weights: [Double] = [1.0, .infinity, 2.0]\n_ = graph.nearestNeighborTour(weight: { weights[$0] })"),
    "TO-504": (K3, "let weights: [Double] = [1.0, -.infinity, 2.0]\n_ = graph.twoOptTour(weight: { weights[$0] })"),
    "TO-505": ("UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), "
               "UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 3)])",
               "// The tree is the path 0-1-2-3, its odd vertices 0 and 3, so the matching reads only 0-3; 1-3 is\n"
               "// never part of the tree, the matching or the tour.\n"
               "let weights: [Double] = [1.0, 1.0, 1.0, 5.0, 5.0, .infinity]\n_ = graph.christofidesTour(weight: { weights[$0] })"),
    "TO-506": ("UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), "
               "UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])",
               "// Without the check, ∞ + (−∞) = NaN in the table and the reconstruction found no vertex after the first.\n"
               "let weights: [Double] = [1.0, 1.0, 1.0, .infinity, 1.0, -.infinity]\n_ = graph.shortestTour(weight: { weights[$0] })"),
    "TO-529": ("AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0), "
               "DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1)])",
               "let weights: [Double] = [1.0, 2.0, .nan, 1.0, 2.0, 1.0]\n_ = graph.shortestTour(weight: { weights[$0] })"),
    "TO-530": ("DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), "
               "DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])",
               "// The second copy of 0→1 is heavier and never used, and its weight still traps.\n"
               "let weights: [Double] = [1.0, .infinity, 1.0, 1.0]\n_ = graph.shortestTour(weight: { weights[$0] })"),
    "TO-531": ("AdjacencyList<Int>(vertices: 0 ..< 26, edges: (0 ..< 26).flatMap { i in (0 ..< 26).filter { $0 != i }.map { DirectedEdge(from: i, to: $0) } })",
               "_ = graph.shortestTour(weight: { _ in 1 })"),
}


def trap_test(cid):
    parts = CELLS[cid]
    why = re.sub(r"^trap: ", "", parts[5])
    graph, call = TRAPS[cid]
    body = [comment_input(cid)]
    if cid == "TO-496":
        body += ["// The tour the row describes is not a `Cycle` at all.",
                 "#expect(Cycle<Int, Int>(vertices: [0, 1, 2, 1], edges: [0, 3, 4, 1]) == nil)"]
    body += ["await #expect(processExitsWith: .failure) {", f"    let graph = {graph}"]
    body += indent(call.split("\n"), 4) + ["}"]
    t = f"{cid} {parts[2]} traps ({why})"
    lines = indent([f'@Test("{esc(t)}")', f"func {fname(cid)}() async {{"], 4)
    return lines + indent(body, 8) + ["    }", ""]


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

DIRECTED_CONFORMER = [
    "/// A directed graph with no vertex or edge indices: only the protocol's vertex-level members. Out-rows",
    "/// are in position order; parallel edges and self-loops are kept.",
    "private struct UnindexedDirectedGraph<Vertex: Hashable>: DirectedGraph {",
    "    let vertices: [Vertex]",
    "    let edges: [DirectedEdge<Vertex>]",
    "",
    "    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }",
    "    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }",
    "}",
    "",
]

UNDIRECTED_CONFORMER = [
    "/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members. Rows",
    "/// are in position order, a self-loop's position twice; parallel edges are kept.",
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
]


def wrap(s, width=98):
    out, cur = [], ""
    for w in s.split(" "):
        if cur and len(cur) + 1 + len(w) > width:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w) if cur else w
    if cur:
        out.append(cur)
    return out


def used_imports(lines):
    t = "\n".join(lines)
    out = ["GraphProtocols", "Testing", "Tours"]
    if "UndirectedAdjacencyList" in t or "AdjacencyList<" in t:
        out.append("AdjacencyListModule")
    if "AdjacencyMatrix" in t:
        out.append("AdjacencyMatrixModule")
    if "CompressedSparseRow" in t:
        out.append("CompressedSparseRowModule")
    if "DirectedPseudograph<" in t or re.search(r"(?<![A-Za-z])Pseudograph<", t):
        out.append("Multigraphs")
    if "ReferencePseudograph" in t or "ReferenceDirectedMultigraph" in t:
        out.append("GrafluentTestSupport")
    if re.search(r"\b(Circuit|Trail|Path|Cycle)(<[^>]*>)?\(", t):
        out.append("Walks")
    return sorted(set(out), key=lambda s: s.lower())


def header(comment, imports, suite, struct, tags=None, conformers=False, lines=()):
    L = [("// " + c) if c else "//" for c in comment]
    L.append("")
    L += [f"import {i}" for i in imports]
    L.append("")
    if conformers:
        t = "\n".join(lines)
        if "UnindexedDirectedGraph" in t:
            L += DIRECTED_CONFORMER
        if "UnindexedGraph<" in t:
            L += UNDIRECTED_CONFORMER
    tg = f", .tags({tags})" if tags else ""
    L.append(f'@Suite("{suite}"{tg})')
    L.append(f"struct {struct} {{")
    return L


def write(name, lines):
    while lines and lines[-1] == "":
        lines.pop()
    lines.append("}")
    with open(os.path.join(OUT, name), "w") as f:
        f.write("\n".join(lines) + "\n")


COMMON = ("Directed rows are `AdjacencyList`, or `DirectedPseudograph` with a self-loop or a repeated edge; "
          "undirected rows `UndirectedAdjacencyList`, or `Pseudograph` with a self-loop or parallel edges; each "
          "built by inserting the row's vertices, then its edges in order, so positions are the catalog's. "
          "In-test checks number vertices by their index in `vertices`. Generated from cases.md by swiftgen.py, "
          "which re-evaluates each row with ref.py's models; see README.md.")

FILES = [
    ("IsEulerianTests.swift", ("IsEulerian", "IsEulerianDirected"), "isEulerian", "IsEulerianTests",
     "`isEulerian` (catalog §IsEulerian, §IsEulerianDirected): exact; the definition checked in each test "
     "(degrees, a self-loop counting 2 or one in and one out, and the vertices with edges in one component "
     "by union–find; isolated vertices ignored; every edgeless graph Eulerian); `isEulerian` exactly when "
     "`eulerianCircuit()` is not nil or there are no edges, `hasEulerianTrail` exactly when "
     "`eulerianTrail()` is not nil or there is no vertex."),
    ("HasEulerianTrailTests.swift", ("HasEulerianTrail", "HasEulerianTrailDirected"), "hasEulerianTrail", "HasEulerianTrailTests",
     "`hasEulerianTrail` (catalog §HasEulerianTrail, §HasEulerianTrailDirected): exact; the definition "
     "checked in each test (no odd vertex or exactly two; balanced, or one vertex with out − in = 1 and "
     "one with in − out = 1), with the same component rule and the same relations to the walks."),
    ("EulerianCircuitTests.swift", ("EulerianCircuit", "EulerianCircuitDirected", "EulerianCircuitFrom", "EulerianCircuitFromDirected"),
     "eulerianCircuit", "EulerianCircuitTests",
     "`eulerianCircuit()` and `eulerianCircuit(from:)` (catalog §EulerianCircuit, §EulerianCircuitDirected, "
     "§EulerianCircuitFrom, §EulerianCircuitFromDirected): Hierholzer's walk exactly (its vertices, the "
     "start not repeated, and its edge positions), pinned by the documented rows; checked here as genuine "
     "(every edge exactly once, edge i joining vertex i and the next, the last back to the first, "
     "`Circuit(vertices:edges:in:)` accepting it) and starting where api.md says (the first vertex with an "
     "edge, or the given one); nil without edges, when not Eulerian, or from a vertex without edges."),
    ("EulerianTrailTests.swift", ("EulerianTrail", "EulerianTrailDirected", "EulerianTrailFrom", "EulerianTrailFromDirected"),
     "eulerianTrail", "EulerianTrailTests",
     "`eulerianTrail()` and `eulerianTrail(from:)` (catalog §EulerianTrail, §EulerianTrailDirected, "
     "§EulerianTrailFrom, §EulerianTrailFromDirected): Hierholzer's walk exactly, checked here as genuine "
     "(every edge exactly once, consecutive edges, `Trail(vertices:edges:in:)` accepting it) and starting "
     "where api.md says (the first odd vertex, the vertex with out − in = 1, or, Eulerian, the first vertex "
     "with an edge; the trivial trail at the first vertex without edges); nil with no vertex or no trail."),
    ("HamiltonianPathTests.swift", ("HamiltonianPath", "HamiltonianPathDirected", "HamiltonianPathFrom", "HamiltonianPathFromDirected"),
     "hamiltonianPath", "HamiltonianPathTests",
     "`hamiltonianPath()`, `hamiltonianPath(from:)` and `hamiltonianPath(from:to:)` (catalog §HamiltonianPath, "
     "§HamiltonianPathDirected, §HamiltonianPathFrom, §HamiltonianPathFromDirected): the first path of the "
     "documented depth-first search exactly; checked here as genuine (every vertex once, consecutive edges, "
     "`Path(vertices:edges:in:)` accepting it) with its ends; on up to 8 vertices, brute force over every "
     "ordering of the vertices for existence and for the first vertex any path starts from."),
    ("HamiltonianCycleTests.swift", ("HamiltonianCycle", "HamiltonianCycleDirected"), "hamiltonianCycle", "HamiltonianCycleTests",
     "`hamiltonianCycle()` (catalog §HamiltonianCycle, §HamiltonianCycleDirected): the first cycle of the "
     "documented search from the first vertex exactly, a self-loop the cycle of one vertex and two "
     "parallel (antiparallel) edges that of two; checked here as genuine (every vertex once, no edge twice, "
     "`Cycle(vertices:edges:in:)` accepting it); on up to 8 vertices, brute force over every ordering for "
     "existence."),
    ("NearestNeighborTourTests.swift", ("NearestNeighborTour",), "nearestNeighborTour", "NearestNeighborTourTests",
     "`nearestNeighborTour(weight:)` and `(from:weight:)` (catalog §NearestNeighborTour): the tour exactly, "
     "its edges each pair's lightest copy and its weight; `weight` called once per non-loop edge in "
     "position order; checked here as a Hamiltonian cycle through the lightest copies, against the "
     "definition step by step (the nearest unvisited vertex, the first on ties), and on up to 9 vertices "
     "against the brute-force optimum; nil below three vertices."),
    ("ChristofidesTourTests.swift", ("ChristofidesTour",), "christofidesTour", "ChristofidesTourTests",
     "`christofidesTour(weight:)` (catalog §ChristofidesTour): the pinned composition's tour exactly; "
     "`weight` called once per non-loop edge; checked here as a Hamiltonian cycle through the lightest "
     "copies from the first vertex, and on up to 9 vertices against the brute-force optimum, within 3/2 "
     "of it where the weights are a metric; nil below three vertices."),
    ("TwoOptTourTests.swift", ("TwoOptTour", "TwoOptTourImproving"), "twoOptTour", "TwoOptTourTests",
     "`twoOptTour(weight:)` and `twoOptTour(improving:weight:)` (catalog §TwoOptTour, §TwoOptTourImproving): "
     "the best-improvement procedure's tour exactly; checked here as 2-optimal (no improving exchange, "
     "by an O(n²) loop), no heavier than its start tour, starting where that tour does, a Hamiltonian cycle "
     "through the lightest copies; on up to 9 vertices against the brute-force optimum."),
    ("ShortestTourTests.swift", ("ShortestTour", "ShortestTourDirected"), "shortestTour", "ShortestTourTests",
     "`shortestTour(weight:)` on `Graph` and `DirectedGraph` (catalog §ShortestTour, §ShortestTourDirected): "
     "Held–Karp's tour exactly; on up to 9 vertices the brute-force optimum and the lexicographically least "
     "optimal tour from the first vertex, checked in the test; graphs need not be complete (nil exactly when "
     "there is no Hamiltonian cycle, also checked with `hamiltonianCycle()`); directed tours step along arcs "
     "and read each ordered pair's lightest arc; nil below three vertices."),
]


COUNTS = {}
for fname_, groups, suite, struct, intro in FILES:
    body = []
    count = 0
    for row in ROWS:
        if row.kind != "trap" and row.group in groups:
            lines = unused_cleanup(body_row(row))
            throws = any("try #require" in l for l in lines)
            body += emit_test(row.cid, title(row.cid), lines, throws=throws)
            count += 1
    L = header(wrap(intro + " " + COMMON), used_imports(body), suite, struct) + body
    write(fname_, L)
    COUNTS[fname_] = count

# Traps
body = []
for row in ROWS:
    if row.kind == "trap":
        body += trap_test(row.cid)
EXTRA = open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n")
body += EXTRA
intro = ("Preconditions, as exit tests (catalog trap rows): a start or end that is not a vertex of the graph, "
         "the empty graph included; a tour heuristic on a graph that is not complete; a tour to improve that "
         "does not list every vertex once; a NaN or infinite weight; a Held–Karp table past 4 GiB. Then the "
         "preconditions the catalog does not list (extra_traps.swift): each on the other entry points and kinds "
         "of graph, a vertex not in a graph without indices, a NaN weight in every tour, an infinite weight and "
         "the matching's bound in Christofides, a missing pair beside parallel edges and self-loops. Each exit "
         "test builds its inputs inside the closure. Generated from cases.md by swiftgen.py; see README.md.")
L = header(wrap(intro), sorted(set(used_imports(body)) | {"AdjacencyListModule", "Multigraphs", "Walks"}, key=str.lower),
           "Tours preconditions", "ToursPreconditionTests", tags=".precondition", conformers=True, lines=body) + body
write("ToursPreconditionTests.swift", L)
COUNTS["ToursPreconditionTests.swift"] = sum(1 for l in body if l.strip().startswith("@Test("))

# Representations
REP_INTRO = ("The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or "
             "`ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or "
             "edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the vertex "
             "indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and, without a "
             "repeated edge, `AdjacencyList.undirectedView` (each edge an arc as written; a vertex's row its out-edges, "
             "then its in-edges) and `AdjacencyMatrix.undirectedView` (rows by neighbour). CompressedSparseRow and "
             "AdjacencyMatrix number edges by row-major cell, so there each catalog edge's position is looked up. "
             "The walks follow each vertex's row, and Christofides' ties follow positions: where ref.py's models, "
             "run by swiftgen.py on the representation's rows and positions, give the catalog's result, it is "
             "pinned exactly; otherwise (a comment says so) the result is checked as genuine, with the "
             "documented start, and existing exactly when the catalog's does. See README.md.")
REP_FILES = [(f.replace("Tests.swift", "RepresentationTests.swift"), groups, f"{suite} on every representation",
              struct.replace("Tests", "RepresentationTests")) for f, groups, suite, struct, _ in FILES]
VALIDITY = []
for fname_, groups, suite, struct in REP_FILES:
    body = []
    count = 0
    for row in ROWS:
        if row.kind != "trap" and row.group in groups:
            lines, exact_all = rep_test(row)
            if not exact_all:
                VALIDITY.append(row.cid)
            body += lines
            count += 1
    L = header(wrap(REP_INTRO), used_imports(body), suite, struct, conformers=True, lines=body) + body
    write(fname_, L)
    COUNTS[fname_] = count

for k, v in COUNTS.items():
    print(f"{k}: {v}")
print("total", sum(COUNTS.values()))
print(f"representation blocks {STATS['rep_blocks']}; rows with a block checked for validity only: {len(VALIDITY)}")
