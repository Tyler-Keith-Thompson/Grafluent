"""Writes the catalog-row test files of Tests/GraphProductsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphProducts/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/GraphProductsTests

First checks that ref.py's model reproduces cases.md byte for byte. Then it rebuilds every row's
product on the model (checked against the definitions, NetworkX and the laws, as ref.py does),
asserts that the recomputed cell equals the catalog's, and writes one @Test per row. Each test
writes the product's whole state out: the vertices and their indices both ways, the counts and
bounds, every edge in `edges` order by value and by index (`sourceIndex`/`targetIndex`, or
`endpointIndices`), the edge indices, and every row by vertex and by index, with each row's
positions given as their offsets in `edges`; then membership and `contains(edge:)` for every
ordered pair of vertices. Positions are pinned through that order and those endpoints, never by
naming the position type's cases, which api.md leaves open. Rows that read `hashes` also run on a
vertex type whose `hash(into:)` counts. Hand-written exit tests spliced into the precondition
file: extra_traps.swift.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "GraphProductsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every row
# ---------------------------------------------------------------------------------------------
SPEC = {}
_case = ref.case


def _rec_case(group, title, kind, gf, hf, rows=True, edges=True, extra=None):
    SPEC[len(ref.ROWS) + 1] = (kind, gf[0], hf[0], rows, edges, extra)
    _case(group, title, kind, gf, hf, rows, edges, extra)


ref.case = _rec_case
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| GP-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 71
assert sorted(SPEC) == list(range(1, 69)), sorted(SPEC)


def title(n): return CELLS[n][2]
def inp(n): return CELLS[n][3]
def cell(n): return CELLS[n][4]
def is_trap(n): return "**trap**" in cell(n)


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------
FUNC = {"cartesian": "cartesianProductView", "tensor": "tensorProductView", "strong": "strongProductView",
        "lexicographic": "lexicographicProductView"}


def s(x): return json.dumps(x, ensure_ascii=False)
def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]" if xs else "[]"
def pair(l): return "Pair(%s, %s)" % (s(l[0]), s(l[1]))
def pairs(ls): return "[" + ", ".join(pair(l) for l in ls) + "]" if ls else "[] as [Pair<String, String>]"
def pair_rows(rows): return "[" + ", ".join("[" + ", ".join(pair(l) for l in r) + "]" for r in rows) + "]" if rows else "[] as [[Pair<String, String>]]"
def int_rows(rows): return "[" + ", ".join(ints(r) for r in rows) + "]" if rows else "[] as [[Int]]"
def bools(xs): return "[" + ", ".join("true" if x else "false" for x in xs) + "]" if xs else "[] as [Bool]"
def opt(x): return "nil" if x is None else str(x)


def factor_type(f):
    pairs_ = [(u, v) if f.directed else tuple(sorted((u, v))) for u, v in f.es]
    simple = len(set(pairs_)) == len(pairs_) and all(u != v for u, v in f.es)
    if f.directed:
        return "AdjacencyList<String>" if simple else "DirectedPseudograph<String>"
    return "UndirectedAdjacencyList<String>" if simple else "Pseudograph<String>"


def factor_edges(f):
    L = f._labels
    if f.directed:
        es = ["DirectedEdge(from: %s, to: %s)" % (s(L[u]), s(L[v])) for u, v in f.es]
        return "[" + ", ".join(es) + "]" if es else "[] as [DirectedEdge<String>]"
    es = ["UndirectedEdge(%s, %s)" % (s(L[u]), s(L[v])) for u, v in f.es]
    return "[" + ", ".join(es) + "]" if es else "[] as [UndirectedEdge<String>]"


def factor_decl(var, f):
    L = f._labels
    vs = "[" + ", ".join(s(l) for l in L) + "]" if L else "[] as [String]"
    return "let %s = %s(vertices: %s, edges: %s)" % (var, factor_type(f), vs, factor_edges(f))


def uses(text):
    out = []
    if "AdjacencyList<" in text:
        out.append("AdjacencyListModule")
    if "Pseudograph<" in text:
        out.append("Multigraphs")
    if "StableDirectedGraph" in text:
        out.append("StableGraphs")
    if ".grid(" in text:
        out.append("NamedGraphs")
    return out


# ---------------------------------------------------------------------------------------------
# State: everything the model knows, written out
# ---------------------------------------------------------------------------------------------

def state(p, var="product", ind="        "):
    n = p.n()
    ps = p.positions()
    off = {q: k for k, q in enumerate(ps)}
    L = [p.label(i) for i in range(n)]
    m = len(ps)
    b = p.edge_bound()
    out = ["let positions = Array(%s.edges.indices)" % var,
           "#expect(Array(%s.vertices) == %s)" % (var, pairs(L)),
           "#expect(%s.vertices.map { %s.vertexIndex(of: $0) } == %s)" % (var, var, ints(list(range(n)))),
           "#expect((0 ..< %d).map { %s.vertex(atIndex: $0) } == %s)" % (n, var, pairs(L)),
           "#expect(%s.vertexCount == %d && %s.edgeCount == %d && %s.edges.count == %d)" % (var, n, var, m, var, m),
           "#expect(%s.vertexIndexBound == %d && %s.edgeIndexBound == %s)" % (var, n, var, opt(b)),
           "#expect(Set(positions).count == %d && positions == positions.sorted())" % m]
    ends = [p.ends(q) for q in ps]
    if p.directed:
        out.append("#expect(%s.edges.map { [$0.source, $0.target] } == %s)" % (var, pair_rows([[L[u], L[v]] for u, v in ends])))
        out.append("#expect(positions.map { [%s.source(ofEdgeAt: $0), %s.target(ofEdgeAt: $0)] } == %s)" % (var, var, pair_rows([[L[u], L[v]] for u, v in ends])))
        out.append("#expect(positions.map { [%s.sourceIndex(ofEdgeAt: $0), %s.targetIndex(ofEdgeAt: $0)] } == %s)" % (var, var, int_rows([list(e) for e in ends])))
    else:
        out.append("#expect(%s.edges.map { [$0.u, $0.v] } == %s)" % (var, pair_rows([[L[u], L[v]] for u, v in ends])))
        out.append("#expect(positions.map { [%s.endpointIndices(ofEdgeAt: $0).u, %s.endpointIndices(ofEdgeAt: $0).v] } == %s)" % (var, var, int_rows([list(e) for e in ends])))
        out.append("#expect(positions.map { %s.oppositeVertex(to: %s.edges[$0].u, acrossEdgeAt: $0) } == %s)" % (var, var, pairs([L[v] for _, v in ends])))
        out.append("#expect(positions.map { %s.oppositeVertex(to: %s.edges[$0].v, acrossEdgeAt: $0) } == %s)" % (var, var, pairs([L[u] for u, _ in ends])))
    if b is not None:
        out.append("#expect(positions.map { %s.edgeIndex(of: $0) } == %s)" % (var, ints([p.edge_index(q) for q in ps])))
        assert [p.edge_index(q) for q in ps] == list(range(m))
    for i in range(n):
        l = pair(L[i])
        if p.directed:
            o, inn = p.out_edges(i), p.in_edges(i)
            succ = [p.tgt(q) for q in o]
            pred = [p.src(q) for q in inn]
            out += [
                "// %s" % ref.fmt_label(L[i]),
                "#expect(Array(%s.successors(of: %s)) == %s)" % (var, l, pairs([L[j] for j in succ])),
                "#expect(Array(%s.successorIndices(ofIndex: %d)) == %s)" % (var, i, ints(succ)),
                "#expect(%s.outEdges(of: %s).map { positions.firstIndex(of: $0) ?? -1 } == %s)" % (var, l, ints([off[q] for q in o])),
                "#expect(%s.outEdges(ofIndex: %d).map { positions.firstIndex(of: $0) ?? -1 } == %s)" % (var, i, ints([off[q] for q in o])),
                "#expect(%s.outDegree(of: %s) == %d && %s.outDegree(ofIndex: %d) == %d)" % (var, l, len(o), var, i, len(o)),
                "#expect(Array(%s.predecessors(of: %s)) == %s)" % (var, l, pairs([L[j] for j in pred])),
                "#expect(Array(%s.predecessorIndices(ofIndex: %d)) == %s)" % (var, i, ints(pred)),
                "#expect(%s.inEdges(of: %s).map { positions.firstIndex(of: $0) ?? -1 } == %s)" % (var, l, ints([off[q] for q in inn])),
                "#expect(%s.inEdges(ofIndex: %d).map { positions.firstIndex(of: $0) ?? -1 } == %s)" % (var, i, ints([off[q] for q in inn])),
                "#expect(%s.inDegree(of: %s) == %d && %s.inDegree(ofIndex: %d) == %d && %s.degree(of: %s) == %d)" % (
                    var, l, len(inn), var, i, len(inn), var, l, len(o) + len(inn)),
            ]
        else:
            inc = p.incident(i)
            nb = [(lambda u, v: v if u == i else u)(*p.ends(q)) for q in inc]
            out += [
                "// %s" % ref.fmt_label(L[i]),
                "#expect(Array(%s.neighbors(of: %s)) == %s)" % (var, l, pairs([L[j] for j in nb])),
                "#expect(Array(%s.neighborIndices(ofIndex: %d)) == %s)" % (var, i, ints(nb)),
                "#expect(%s.incidentEdges(of: %s).map { positions.firstIndex(of: $0) ?? -1 } == %s)" % (var, l, ints([off[q] for q in inc])),
                "#expect(%s.incidentEdges(ofIndex: %d).map { positions.firstIndex(of: $0) ?? -1 } == %s)" % (var, i, ints([off[q] for q in inc])),
                "#expect(%s.degree(of: %s) == %d && %s.degree(ofIndex: %d) == %d)" % (var, l, len(inc), var, i, len(inc)),
            ]
            if b is not None:
                out.append("#expect(Array(%s.incidentEdgeIndices(ofIndex: %d)) == %s)" % (var, i, ints([off[q] for q in inc])))
    if n:
        out.append("#expect(%s.vertices.allSatisfy { %s.contains($0) })" % (var, var))
        if p.directed:
            arcs = {p.ends(q) for q in ps}
            out.append("// contains(edge:) for every ordered pair, row-major by index.")
            out.append("#expect(%s.vertices.flatMap { u in %s.vertices.map { v in %s.contains(edge: DirectedEdge(from: u, to: v)) } } == %s)" % (
                var, var, var, bools([(i, j) in arcs for i in range(n) for j in range(n)])))
        else:
            es = {frozenset(p.ends(q)) for q in ps}
            out.append("// contains(edge:) for every ordered pair, row-major by index.")
            out.append("#expect(%s.vertices.flatMap { u in %s.vertices.map { v in %s.contains(edge: UndirectedEdge(u, v)) } } == %s)" % (
                var, var, var, bools([frozenset((i, j)) in es for i in range(n) for j in range(n)])))
    return [ind + x for x in out]


COUNTED = [
    "// Factor label hashes, counted by a vertex type whose hash(into:) counts.",
    "final class Tally {",
    "    var hashes = 0",
    "}",
    "struct Counted: Hashable {",
    "    let name: String",
    "    let tally: Tally",
    "    static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }",
    "    func hash(into hasher: inout Hasher) {",
    "        tally.hashes += 1",
    "        hasher.combine(name)",
    "    }",
    "}",
    "let tally = Tally()",
]


def counted_lines(kind, g, h, ind="        "):
    def decl(var, f):
        L = f._labels
        es = ", ".join("UndirectedEdge(Counted(name: %s, tally: tally), Counted(name: %s, tally: tally))" % (s(L[u]), s(L[v])) for u, v in f.es)
        return "let %s = UndirectedAdjacencyList<Counted>(vertices: %s.map { Counted(name: $0, tally: tally) }, edges: %s)" % (
            var, "[" + ", ".join(s(l) for l in L) + "]", "[" + es + "]" if es else "[] as [UndirectedEdge<Counted>]")
    p = ref.Product(kind, g, h)
    lines = list(COUNTED) + [
        decl("countedG", g), decl("countedH", h),
        "let counted = %s(countedG, countedH)" % FUNC[kind],
        "tally.hashes = 0",
        "// Every index-space row, over every vertex.",
        "for i in 0 ..< %d {" % p.n(),
        "    _ = Array(counted.neighborIndices(ofIndex: i))",
        "    _ = Array(counted.incidentEdges(ofIndex: i))",
        "    _ = counted.vertex(atIndex: i)",
        "}",
        "// The edges by value: each is built from the factors' edges and vertices, with no lookup.",
        "for position in counted.edges.indices {",
        "    _ = counted.edges[position]",
        "}",
        "#expect(counted.vertexIndexBound == %d && counted.edgeCount == %d)" % (p.n(), p.edge_count()),
        "#expect(tally.hashes == 0)",
        "// A pair lookup: one lookup in each factor.",
        "let index = counted.vertexIndex(of: Pair(Counted(name: \"b\", tally: tally), Counted(name: \"y\", tally: tally)))",
        "#expect(index == 3)",
        "#expect(tally.hashes == 2)",
    ]
    return [ind + x for x in lines]


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def header(n):
    return ['    @Test("GP-%03d %s")' % (n, title(n))]


def recompute_cell(n):
    kind, g, h, rows, edges, extra = SPEC[n]
    g.hashes = h.hashes = 0
    p = ref.Product(kind, g, h)
    ref.check(p)
    ref.spec(p)
    exp = ref.fmt_state(p, edges) + ref.nx_multi_note(p)
    if rows:
        exp += "; " + ref.fmt_rows(p)
    if extra:
        exp += "; " + extra(p)
    assert exp == cell(n), (n, exp, cell(n))
    return p


def row_test(n):
    kind, g, h, rows, edges, extra = SPEC[n]
    p = recompute_cell(n)
    lines = header(n) + ["    func gp%03d() {" % n, "        // %s" % inp(n), "        // → %s" % cell(n)]
    lines.append("        " + factor_decl("g", g))
    lines.append("        " + factor_decl("h", h))
    lines.append("        let product = %s(g, h)" % FUNC[kind])
    lines.append("        #expect(Array(product.first.vertices) == Array(g.vertices) && Array(product.second.vertices) == Array(h.vertices))")
    if "NetworkX MultiGraph" in cell(n):
        lines.append("        // NetworkX's MultiGraph merges coincident loop products; here each generating tuple is its own edge.")
    lines += state(p)
    if "hashes" in cell(n):
        lines += counted_lines(kind, g, h)
    if "grid(dimensions" in cell(n):
        lines += [
            "        // NamedGraphs' grid numbers vertex (i, j) as i·3 + j: the same index-space edges.",
            "        let grid = UndirectedAdjacencyList<Int>.grid(dimensions: [2, 3])",
            "        #expect(Set(positions.map { [product.endpointIndices(ofEdgeAt: $0).u, product.endpointIndices(ofEdgeAt: $0).v].sorted() })",
            "                == Set(grid.edges.map { [$0.u, $0.v].sorted() }))",
            "        #expect(product.vertexIndexBound == grid.vertexCount && product.edgeCount == grid.edgeCount)",
            "        for i in 0 ..< 6 {",
            "            #expect(Array(product.neighborIndices(ofIndex: i)).sorted() == Array(grid.neighborIndices(ofIndex: i)).sorted())",
            "        }",
        ]
    if "nested with K2" in cell(n):
        nested = ref.Product("cartesian", ref._Mat(p), ref.Factor(["0", "1"], [("0", "1")], False))
        assert nested.edge_count() == 12
        vs = ["Pair(%s, %s)" % (pair(p.label(i // 2)), s(str(i % 2))) for i in range(8)]
        lines += [
            "        // Nesting: vertex ((i, j), k) has index (i·|H| + j)·2 + k.",
            "        let k2 = UndirectedAdjacencyList<String>(vertices: [\"0\", \"1\"], edges: [UndirectedEdge(\"0\", \"1\")])",
            "        let cube = cartesianProductView(product, k2)",
            "        #expect(cube.edgeCount == 12 && cube.vertexIndexBound == 8 && cube.edges.count == 12)",
            "        #expect(Array(cube.vertices) == [%s])" % ", ".join(vs),
            "        #expect(cube.vertices.map { cube.vertexIndex(of: $0) } == [0, 1, 2, 3, 4, 5, 6, 7])",
            "        #expect(cube.vertexIndex(of: Pair(Pair(\"b\", \"x\"), \"1\")) == 5)",
            "        #expect((0 ..< 8).allSatisfy { cube.degree(ofIndex: $0) == 3 })",
        ]
    if "swapped edgeCount" in cell(n):
        sw = ref.Product("lexicographic", h, g).edge_count()
        lines += ["        // Swapped: K2 ∘ P3.",
                  "        let swapped = lexicographicProductView(h, g)",
                  "        #expect(swapped.edgeCount == %d && swapped.edges.count == %d)" % (sw, sw)]
    if "vertex(atIndex: 5)" in cell(n):
        lines += ["        #expect(product.vertex(atIndex: 5) == Pair(\"c\", \"y\"))",
                  "        #expect(product.vertexIndex(of: Pair(\"b\", \"x\")) == 2)"]
    if "predecessors(of: (b,y))" in cell(n):
        lines.append("        // The catalog's call.")
        pred = [p.label(p.src(q)) for q in p.in_edges(3)]
        lines.append("        #expect(Array(product.predecessors(of: Pair(\"b\", \"y\"))) == %s)" % pairs(pred))
    lines.append("    }")
    return lines


def trap_test(n):
    lines = header(n) + ["    func gp%03d() async {" % n, "        // %s → %s" % (inp(n), cell(n))]
    if n == 69:
        lines += [
            "        await #expect(processExitsWith: .failure) {",
            "            var g = StableDirectedGraph<String>(vertices: [\"a\", \"removed\"])",
            "            _ = g.remove(\"removed\")",
            "            let h = AdjacencyList<String>(vertices: [\"x\"])",
            "            _ = cartesianProductView(g, h)",
            "        }",
            "        // The factor has a hole, so no vertex indices.",
            "        var holed = StableDirectedGraph<String>(vertices: [\"a\", \"removed\"])",
            "        _ = holed.remove(\"removed\")",
            "        #expect(holed.vertexIndexBound == nil)",
            "        // Without the removal: dense, and accepted.",
            "        let g = StableDirectedGraph<String>(vertices: [\"a\"])",
            "        let h = AdjacencyList<String>(vertices: [\"x\"])",
            "        let product = cartesianProductView(g, h)",
            "        #expect(Array(product.vertices) == [Pair(\"a\", \"x\")])",
            "        #expect(product.vertexIndexBound == 1 && product.edgeCount == 0)",
        ]
    elif n == 70:
        def huge(ind):
            return [ind + x for x in [
                "struct Huge: Graph {",
                "    let count: Int",
                "    var vertices: Range<Int> { 0 ..< count }",
                "    var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }",
                "    func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }",
                "    func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }",
                "    var vertexIndexBound: Int? { count }",
                "    func vertexIndex(of vertex: Int) -> Int { vertex }",
                "    func vertex(atIndex index: Int) -> Int { index }",
                "}"]]
        lines += ["        await #expect(processExitsWith: .failure) {",
                  "            // An edgeless graph on 0..<count, stored as its count."]
        lines += huge("            ")
        lines += ["            _ = cartesianProductView(Huge(count: 1 << 32), Huge(count: 1 << 32))",
                  "        }",
                  "        // 2^32 · 2^30 = 2^62 fits: accepted, and the last vertex is found by one division."]
        lines += huge("        ")
        lines += ["        let product = cartesianProductView(Huge(count: 1 << 32), Huge(count: 1 << 30))",
                  "        #expect(product.vertexIndexBound == 1 << 62 && product.edgeCount == 0)",
                  "        #expect(product.vertex(atIndex: (1 << 62) - 1) == Pair((1 << 32) - 1, (1 << 30) - 1))",
                  "        #expect(product.vertexIndex(of: Pair(5, 7)) == (5 << 30) + 7)"]
    elif n == 71:
        lines += [
            "        await #expect(processExitsWith: .failure) {",
            "            let g = UndirectedAdjacencyList<String>(vertices: [\"a\", \"b\"], edges: [UndirectedEdge(\"a\", \"b\")])",
            "            let h = UndirectedAdjacencyList<String>(vertices: [\"x\"], edges: [] as [UndirectedEdge<String>])",
            "            _ = cartesianProductView(g, h).vertexIndex(of: Pair(\"a\", \"q\"))",
            "        }",
            "        // Without the call: the pair is not a vertex, and contains(_:) says so without trapping.",
            "        let g = UndirectedAdjacencyList<String>(vertices: [\"a\", \"b\"], edges: [UndirectedEdge(\"a\", \"b\")])",
            "        let h = UndirectedAdjacencyList<String>(vertices: [\"x\"], edges: [] as [UndirectedEdge<String>])",
            "        let product = cartesianProductView(g, h)",
            "        #expect(!product.contains(Pair(\"a\", \"q\")) && !product.contains(Pair(\"q\", \"x\")))",
            "        #expect(product.contains(Pair(\"a\", \"x\")) && product.vertexIndex(of: Pair(\"b\", \"x\")) == 1)",
        ]
    else:
        raise AssertionError(n)
    lines.append("    }")
    return lines


def test_for(n):
    return trap_test(n) if is_trap(n) else row_test(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, N + 1) if CELLS[n][1] in groups and not is_trap(n)]


TRAPS = [n for n in range(1, N + 1) if is_trap(n)]
assert TRAPS == [69, 70, 71], TRAPS
FILES = [
    ("CartesianProductTests.swift", "GraphProducts Cartesian product", ids("Cartesian"),
     "Cartesian product G □ H (catalog GP-001 – GP-014): G-moves then H-moves in every row, positions\n"
     "// G-edge by H-vertex then G-vertex by H-edge, edge index eG·nH + h then mG·nH + g·mH + eH, a loop\n"
     "// in either factor a product loop (twice in its row), rows hashing nothing."),
    ("TensorProductTests.swift", "GraphProducts tensor product", ids("Tensor"),
     "Tensor product G × H (catalog GP-015 – GP-028): an edge for each pair of factor edges, two in an\n"
     "// undirected product (straight, then crossed) unless either is a self-loop; directed edge index\n"
     "// eG·mH + eH, no edge indices undirected."),
    ("StrongProductTests.swift", "GraphProducts strong product", ids("Strong"),
     "Strong product G ⊠ H (catalog GP-029 – GP-042): the Cartesian edges, then the tensor edges, in\n"
     "// positions and in every row."),
    ("LexicographicProductTests.swift", "GraphProducts lexicographic product", ids("Lexicographic"),
     "Lexicographic product G ∘ H (catalog GP-043 – GP-056): each G-edge to every H-vertex pair (h ≤ h′\n"
     "// over an undirected loop), then the H-moves."),
    ("ProductIdentityTests.swift", "GraphProducts identities", ids("Identities"),
     "Identities (catalog GP-057 – GP-064): P2 □ P3 is NamedGraphs' grid, nesting, K2 × C3 = C6,\n"
     "// K2 ⊠ K2 = K4, the lexicographic product's non-commutativity."),
    ("ProductIndexTests.swift", "GraphProducts indices", ids("Indices"),
     "Indices (catalog GP-065 – GP-068): vertex (g, h) at index(g)·|V(H)| + index(h), the edge-index\n"
     "// formulas, and no edge indices for undirected ×."),
    ("ProductPreconditionTests.swift", "GraphProducts preconditions", TRAPS,
     "Preconditions (catalog trap rows GP-069 – GP-071): each trapping call runs in a child process (an exit\n"
     "// test). The same setup then runs in this process without the fault. Then the preconditions the\n"
     "// catalog does not list (extra_traps.swift)."),
]


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "ProductPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphProducts", "GraphProtocols", "Testing"] + uses(text)
    if fname == "ProductPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports = sorted(set(imports), key=str.lower)
    tags = ", .tags(.precondition)" if fname == "ProductPreconditionTests.swift" else ""
    out = ["// " + comment, "// Generated from cases.md by Tests/Catalogs/GraphProducts/swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname, suite, rows, comment in FILES:
    k = write(fname, suite, rows, comment)
    print(fname, k)
    total += k
    rows_total += len(rows)
assert rows_total == N, rows_total
print("catalog rows", rows_total, "tests", total)
