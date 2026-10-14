"""Writes the catalog-row test files of Tests/NamedGraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/NamedGraphs/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/NamedGraphsTests

First checks that ref.py reproduces cases.md byte for byte. Then it parses each row's call (the
catalog writes valid Swift), rebuilds the row on ref.py's model, asserts that the model's summary is
the row's cell, and writes one @Test per row. A row runs its family on every conformer api.md lists:
the undirected form on UndirectedAdjacencyList, Pseudograph and Multigraph, the directed form on
CompressedSparseRow, AdjacencyMatrix, AdjacencyList, DirectedPseudograph, DirectedMultigraph and
StableDirectedGraph. Both forms come from ref.py's model, which checks them against NetworkX and
igraph. Tree and BipartiteGraph rows run on their own type. A trap row runs its call as an exit
test on every conformer the rule covers, then runs a valid neighbour of the call in this process.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "NamedGraphsTests")

ref.build_rows()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| NG-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 236


def group(n): return CELLS[n][1]
def title(n): return CELLS[n][2]
def call(n): return CELLS[n][3].strip("`")
def cell(n): return CELLS[n][4]
def is_trap(n): return cell(n).startswith("**trap**")


UNDIRECTED = ["UndirectedAdjacencyList<Int>", "Pseudograph<Int>", "Multigraph<Int>"]
DIRECTED = ["CompressedSparseRow", "AdjacencyMatrix", "AdjacencyList<Int>", "DirectedPseudograph<Int>",
            "DirectedMultigraph<Int>", "StableDirectedGraph<Int>"]
FAMILIES = {
    "complete": lambda d, vertexCount: ref.complete(vertexCount, d),
    "completeBipartite": lambda d, leftCount, rightCount: ref.complete_bipartite(leftCount, rightCount, d),
    "path": lambda d, vertexCount: ref.path(vertexCount, d),
    "cycle": lambda d, vertexCount: ref.cycle(vertexCount, d),
    "star": lambda d, vertexCount: ref.star(vertexCount, d),
    "wheel": lambda d, vertexCount: ref.wheel(vertexCount, d),
    "grid": lambda d, dimensions, periodic=False: ref.grid(dimensions, periodic, d),
    "hypercube": lambda d, dimension: ref.hypercube(dimension, d),
    "petersen": lambda d: ref.petersen(d),
    "empty": lambda d, vertexCount: ref.empty(vertexCount, d),
    "ladder": lambda d, rungCount: ref.ladder(rungCount, d),
    "circularLadder": lambda d, rungCount: ref.circular_ladder(rungCount, d),
    "barbell": lambda d, cliqueVertexCount, pathVertexCount: ref.barbell(cliqueVertexCount, pathVertexCount, d),
    "lollipop": lambda d, cliqueVertexCount, pathVertexCount: ref.lollipop(cliqueVertexCount, pathVertexCount, d),
    "completeMultipartite": lambda d, partSizes: ref.complete_multipartite(partSizes, d),
    "turan": lambda d, vertexCount, partCount: ref.turan(vertexCount, partCount, d),
    "balancedTree": lambda d, branchingFactor, height: ref.balanced_tree(branchingFactor, height, d),
    "circulant": lambda d, vertexCount, offsets: ref.circulant(vertexCount, offsets, d),
    "generalizedPetersen": lambda d, outerCycleLength, step: ref.generalized_petersen(outerCycleLength, step, d),
    "kneser": lambda d, setSize, subsetSize: ref.kneser(setSize, subsetSize, d),
    "windmill": lambda d, cliqueCount, cliqueVertexCount: ref.windmill(cliqueCount, cliqueVertexCount, d),
    "binomialTree": lambda d, order: ref.binomial_tree(order, d),
    "fullRaryTree": lambda d, branchingFactor, vertexCount: ref.full_rary_tree(branchingFactor, vertexCount, d),
    "deBruijn": lambda d, alphabetSize, wordLength: ref.de_bruijn(alphabetSize, wordLength),
    "kautz": lambda d, alphabetSize, wordLength: ref.kautz(alphabetSize, wordLength),
    "triangularLattice": lambda d, rowCount, columnCount: ref.triangular_lattice(rowCount, columnCount, d),
    "hexagonalLattice": lambda d, rowCount, columnCount: ref.hexagonal_lattice(rowCount, columnCount, d),
    "lcf": lambda d, vertexCount, shifts, repeatCount: ref.lcf(vertexCount, shifts, repeatCount, d),
    **{name: (lambda name: lambda d: ref.lcf_named(name, d))(name) for name in ref.LCF_NAMED},
    "icosahedral": lambda d: ref.icosahedral(d),
    "tutte": lambda d: ref.tutte(d),
    "chvatal": lambda d: ref.chvatal(d),
    "hoffmanSingleton": lambda d: ref.hoffman_singleton(d),
}
# The conformers of each kind a family is built on, when not every one: de Bruijn graphs have
# self-loops, and Kautz graphs are directed only.
KINDS = {"deBruijn": ([], ["AdjacencyList<Int>", "DirectedPseudograph<Int>"]), "kautz": ([], None)}
ORIENTATION = {
    "complete": "both arcs", "completeBipartite": "both arcs", "path": "i → i + 1",
    "cycle": "i → (i + 1) mod n", "star": "hub → leaf", "wheel": "hub → rim, rim i → i + 1 and n − 1 → 1",
    "grid": "both arcs", "hypercube": "both arcs", "petersen": "both arcs", "empty": "no arcs",
    "ladder": "both arcs", "circularLadder": "both arcs", "barbell": "both arcs", "lollipop": "both arcs",
    "completeMultipartite": "both arcs", "turan": "both arcs",
    "balancedTree": "parent → child",
    "binomialTree": "parent → child", "fullRaryTree": "parent → child",
    "deBruijn": "word → its shifts", "kautz": "word → its shifts",
    **{name: "both arcs" for name in ("circulant", "generalizedPetersen", "kneser", "windmill", "triangularLattice",
                                      "hexagonalLattice", "lcf", "heawood", "moebiusKantor", "pappus", "desargues",
                                      "dodecahedral", "frucht", "icosahedral", "tutte", "chvatal", "hoffmanSingleton")},
}


def parse(text):
    """`Type.family(label: value, …)` → (type, family, argument text, keyword arguments)."""
    m = re.fullmatch(r"(.+?)\.(\w+)\((.*)\)", text)
    assert m, text
    typ, fam, args = m.groups()
    py = re.sub(r"(\w+): ", r"\1=", args).replace("true", "True").replace("false", "False")
    kwargs = eval("dict(%s)" % py)
    return typ, fam, args, kwargs


def model(fam, directed, kwargs):
    try:
        return FAMILIES[fam](directed, **kwargs)
    except ref.Trap as t:
        return t


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "] as [Int]"
def pairs(es): return "[" + ", ".join("[%d, %d]" % e for e in es) + "] as [[Int]]"
def rows(rs): return "[" + ", ".join("[" + ", ".join(str(x) for x in r) + "]" for r in rs) + "] as [[Int]]"


def adjacency(g):
    nb = [[] for _ in range(g.n)]
    for u, v in g.edges:
        nb[u].append(v)
        if not g.directed:
            nb[v].append(u)
    return [sorted(r) for r in nb]


def first_non_edge(g):
    es = set(g.edges)
    for u in range(g.n):
        for v in range(g.n):
            if u != v and (u, v) not in es and (g.directed or (min(u, v), max(u, v)) not in es):
                return (u, v)
    return None


LITERAL_LIMIT = 200  # edges; above it, the edges are checked by the family's rule instead


def big_rule(fam, kwargs, directed):
    """The family's adjacency rule for rows too large to write out (K60, 100×100, Q10)."""
    pair = "e.source, e.target" if directed else "e.u, e.v"
    if fam in ref.NEW_FAMILIES:
        return None  # the named graphs: sorted, in range, regular and m fixed; the properties check the rest
    if fam == "complete":
        return None  # sorted, no repeats, in range and m = n(n − 1)/2 (or n(n − 1)) leave only every pair
    if fam == "grid":
        c = kwargs["dimensions"][-1]
        return "{ let (a, b) = (min(%s), max(%s)); return (b - a == 1 && a %% %d != %d) || b - a == %d }()" % (
            pair, pair, c, c - 1, c)
    if fam == "hypercube":
        return "(%s).nonzeroBitCount == 1" % pair.replace(", ", " ^ ")
    raise AssertionError(fam)


def undirected_check(g, fam, kwargs, ind):
    n, m = g.n, len(g.edges)
    d = ref.degrees(g)
    L = [ind + "func check(_ graph: some Graph<Int>, _ type: String) {"]
    i = ind + "    "
    L.append(i + "#expect(graph.vertexCount == %d && graph.edgeCount == %d && graph.edges.count == %d, \"\\(type)\")" % (n, m, m))
    L.append(i + "#expect(Array(graph.vertices) == Array(0 ..< %d), \"\\(type)\")" % n)
    L.append(i + "#expect((0 ..< %d).map { graph.vertexIndex(of: $0) } == Array(0 ..< %d), \"\\(type)\")" % (n, n))
    if m <= LITERAL_LIMIT:
        L.append(i + "#expect(graph.edges.map { [$0.u, $0.v] } == %s, \"\\(type)\")" % pairs(g.edges))
        L.append(i + "#expect((0 ..< %d).map { graph.degree(of: $0) } == %s, \"\\(type)\")" % (n, ints(d)))
        L.append(i + "#expect((0 ..< %d).map { graph.neighbors(of: $0).sorted() } == %s, \"\\(type)\")" % (n, rows(adjacency(g))))
    else:
        L.append(i + "// Sorted, u < v, no repeats, and each edge by the family's rule.")
        L.append(i + "let ends = graph.edges.map { [$0.u, $0.v] }")
        L.append(i + "#expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, \"\\(type)\")")
        rule = big_rule(fam, kwargs, False)
        L.append(i + "#expect(graph.edges.allSatisfy { e in e.u < e.v && e.v < %d%s }, \"\\(type)\")" % (n, " && " + rule if rule else ""))
        if min(d) == max(d):
            L.append(i + "#expect((0 ..< %d).allSatisfy { graph.degree(of: $0) == %d }, \"\\(type)\")" % (n, d[0]))
        else:
            assert fam == "grid" and len(kwargs["dimensions"]) == 2
            r, c = kwargs["dimensions"]
            L.append(i + "#expect((0 ..< %d).allSatisfy { v in graph.degree(of: v) == [v / %d > 0, v / %d < %d, v %% %d > 0, v %% %d < %d].filter { $0 }.count }, \"\\(type)\")"
                     % (n, c, c, r - 1, c, c, c - 1))
            assert all(d[v] == sum([v // c > 0, v // c < r - 1, v % c > 0, v % c < c - 1]) for v in range(n))
    L.append(i + "#expect(graph.edges.allSatisfy { graph.contains(edge: $0) && graph.contains(edge: UndirectedEdge($0.v, $0.u)) }, \"\\(type)\")")
    if n <= 64:
        L.append(i + "#expect((0 ..< %d).allSatisfy { v in graph.incidentEdges(of: v).allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v } }, \"\\(type)\")" % n)
    ne = first_non_edge(g)
    if ne:
        L.append(i + "#expect(!graph.contains(edge: UndirectedEdge(%d, %d)), \"\\(type)\")" % ne)
    L.append(ind + "}")
    return L


def directed_check(g, fam, kwargs, ind):
    n, m = g.n, len(g.edges)
    out, inn = ref.degrees(g)
    L = [ind + "func checkDirected(_ graph: some DirectedGraph<Int>, _ type: String) {"]
    i = ind + "    "
    L.append(i + "#expect(graph.vertexCount == %d && graph.edgeCount == %d && graph.edges.count == %d, \"\\(type)\")" % (n, m, m))
    L.append(i + "#expect(Array(graph.vertices) == Array(0 ..< %d), \"\\(type)\")" % n)
    L.append(i + "#expect((0 ..< %d).map { graph.vertexIndex(of: $0) } == Array(0 ..< %d), \"\\(type)\")" % (n, n))
    L.append(i + "var inDegrees = [Int](repeating: 0, count: %d)" % n)
    L.append(i + "for edge in graph.edges { inDegrees[edge.target] += 1 }")
    if m <= LITERAL_LIMIT:
        L.append(i + "#expect(graph.edges.map { [$0.source, $0.target] } == %s, \"\\(type)\")" % pairs(g.edges))
        L.append(i + "#expect((0 ..< %d).map { graph.outDegree(of: $0) } == %s, \"\\(type)\")" % (n, ints(out)))
        L.append(i + "#expect(inDegrees == %s, \"\\(type)\")" % ints(inn))
        L.append(i + "#expect((0 ..< %d).map { graph.successors(of: $0).sorted() } == %s, \"\\(type)\")" % (n, rows(adjacency(g))))
    else:
        L.append(i + "// Row-major, no repeats, no self-loops, and each arc by the family's rule.")
        L.append(i + "let ends = graph.edges.map { [$0.source, $0.target] }")
        L.append(i + "#expect(zip(ends, ends.dropFirst()).allSatisfy { $0.lexicographicallyPrecedes($1) }, \"\\(type)\")")
        rule = big_rule(fam, kwargs, True)
        L.append(i + "#expect(graph.edges.allSatisfy { e in e.source != e.target && e.source < %d && e.target < %d%s }, \"\\(type)\")"
                 % (n, n, " && " + rule if rule else ""))
        if min(out) == max(out) and min(inn) == max(inn):
            L.append(i + "#expect((0 ..< %d).allSatisfy { graph.outDegree(of: $0) == %d } && inDegrees.allSatisfy { $0 == %d }, \"\\(type)\")" % (n, out[0], inn[0]))
        else:
            assert fam == "grid" and len(kwargs["dimensions"]) == 2
            r, c = kwargs["dimensions"]
            L.append(i + "#expect((0 ..< %d).allSatisfy { v in graph.outDegree(of: v) == [v / %d > 0, v / %d < %d, v %% %d > 0, v %% %d < %d].filter { $0 }.count && inDegrees[v] == graph.outDegree(of: v) }, \"\\(type)\")"
                     % (n, c, c, r - 1, c, c, c - 1))
    L.append(i + "#expect(graph.edges.allSatisfy { graph.contains(edge: $0) }, \"\\(type)\")")
    if n <= 64:
        L.append(i + "#expect((0 ..< %d).allSatisfy { v in graph.outEdges(of: v).allSatisfy { graph.source(ofEdgeAt: $0) == v } }, \"\\(type)\")" % n)
    ne = first_non_edge(g)
    if ne:
        L.append(i + "#expect(!graph.contains(edge: DirectedEdge(from: %d, to: %d)), \"\\(type)\")" % ne)
    L.append(ind + "}")
    return L


def header(n, is_async=False):
    return ['    @Test("NG-%03d %s")' % (n, title(n)),
            "    func ng%03d()%s {" % (n, " async" if is_async else ""),
            "        // %s → %s" % (call(n), cell(n))]


# ---------------------------------------------------------------------------------------------
# Rows
# ---------------------------------------------------------------------------------------------

def family_row(n):
    typ, fam, args, kwargs = parse(call(n).split(" == ")[0])
    row_directed = typ in DIRECTED
    g = model(fam, row_directed, kwargs)
    full = "; E [" in cell(n)
    text = ref.summary(g, full)
    if n == 48:
        text += "; equal true"
    assert text == cell(n), (n, text, cell(n))
    undirected_types, directed_types = KINDS.get(fam, (UNDIRECTED, DIRECTED))
    directed_types = directed_types or DIRECTED
    gu = model(fam, False, kwargs) if undirected_types else None
    gd = model(fam, True, kwargs)
    L = header(n)
    if gu is not None and not isinstance(gu, ref.Trap):
        L += undirected_check(gu, fam, kwargs, "        ")
        for t in undirected_types:
            L.append("        check(%s.%s(%s), %s)" % (t, fam, args, '"%s"' % t))
    if n == 48:
        L.append("        // W4 is K4 on every undirected conformer.")
        for t in UNDIRECTED:
            L.append("        #expect(%s.wheel(vertexCount: 4) == %s.complete(vertexCount: 4))" % (t, t))
    if not isinstance(gd, ref.Trap):
        L.append("        // The directed form: %s." % ORIENTATION[fam])
        L += directed_check(gd, fam, kwargs, "        ")
        for t in directed_types:
            L.append("        checkDirected(%s.%s(%s), %s)" % (t, fam, args, '"%s"' % t))
    L.append("    }")
    return L


def structure_row(n):
    typ, fam, args, kwargs = parse(call(n))
    if typ == "Tree<Int>":
        g = TREE[fam](**kwargs)
        assert ref.summary(g) == cell(n), n
    else:
        g = ref.bipartite_complete(kwargs["leftCount"], kwargs["rightCount"])
        assert ref.summary(g) + "; left %s; right %s" % (g.left, g.right) == cell(n), n
    L = header(n)
    L.append("        let graph = %s" % call(n))
    L += undirected_check(g, fam, kwargs, "        ")
    L.append('        check(graph, "%s")' % typ)
    if typ != "Tree<Int>":
        L.append("        #expect(Array(graph.left) == %s && Array(graph.right) == %s)" % (ints(g.left), ints(g.right)))
        L.append("        #expect((0 ..< %d).map { graph.side(of: $0) } == %s)" % (
            g.n, "[" + ", ".join(".left" if v in g.left else ".right" for v in range(g.n)) + "] as [BipartiteSide]"))
    L.append("    }")
    return L


# Trap rows: (calls run as exit tests, the valid neighbour run in this process, its expected n and m).
def every(fam, args, kinds=("U", "D")):
    undirected_types, directed_types = KINDS.get(fam, (UNDIRECTED, DIRECTED))
    out = []
    if "U" in kinds:
        out += ["%s.%s(%s)" % (t, fam, args) for t in undirected_types]
    if "D" in kinds:
        out += ["%s.%s(%s)" % (t, fam, args) for t in directed_types or DIRECTED]
    return out


TRAPS = {
    10: (every("complete", "vertexCount: -1"), "UndirectedAdjacencyList<Int>.complete(vertexCount: 0)", (0, 0)),
    11: (every("complete", "vertexCount: 1 << 32", "D"), "CompressedSparseRow.complete(vertexCount: 3)", (3, 6)),
    20: (every("completeBipartite", "leftCount: 2, rightCount: -1") + every("completeBipartite", "leftCount: -1, rightCount: 2")
         + ["BipartiteGraph<Int>.completeBipartite(leftCount: 2, rightCount: -1)"],
         "UndirectedAdjacencyList<Int>.completeBipartite(leftCount: 2, rightCount: 0)", (2, 0)),
    28: (["Tree<Int>.path(vertexCount: 0)", "Tree<Int>.path(vertexCount: -1)"], "Tree<Int>.path(vertexCount: 1)", (1, 0)),
    29: (every("path", "vertexCount: -2"), "UndirectedAdjacencyList<Int>.path(vertexCount: 0)", (0, 0)),
    34: (every("cycle", "vertexCount: 0"), "UndirectedAdjacencyList<Int>.cycle(vertexCount: 3)", (3, 3)),
    35: (every("cycle", "vertexCount: 1"), "UndirectedAdjacencyList<Int>.cycle(vertexCount: 3)", (3, 3)),
    36: (every("cycle", "vertexCount: 2"), "UndirectedAdjacencyList<Int>.cycle(vertexCount: 3)", (3, 3)),
    37: (every("cycle", "vertexCount: 2", "D"), "CompressedSparseRow.cycle(vertexCount: 3)", (3, 3)),
    43: (every("star", "vertexCount: 0") + ["Tree<Int>.star(vertexCount: 0)"], "UndirectedAdjacencyList<Int>.star(vertexCount: 1)", (1, 0)),
    50: (every("wheel", "vertexCount: 0"), "UndirectedAdjacencyList<Int>.wheel(vertexCount: 4)", (4, 6)),
    51: (every("wheel", "vertexCount: 3"), "UndirectedAdjacencyList<Int>.wheel(vertexCount: 4)", (4, 6)),
    66: (every("grid", "dimensions: []") + every("grid", "dimensions: [], periodic: true", "U"),
         "UndirectedAdjacencyList<Int>.grid(dimensions: [1])", (1, 0)),
    67: (every("grid", "dimensions: [3, -1]"), "UndirectedAdjacencyList<Int>.grid(dimensions: [3, 0])", (0, 0)),
    68: (every("grid", "dimensions: [1 << 32, 1 << 32]"), "UndirectedAdjacencyList<Int>.grid(dimensions: [1 << 32, 0])", (0, 0)),
    75: (every("hypercube", "dimension: -1"), "UndirectedAdjacencyList<Int>.hypercube(dimension: 0)", (1, 0)),
    76: (every("hypercube", "dimension: 63"), "UndirectedAdjacencyList<Int>.hypercube(dimension: 4)", (16, 32)),
    83: (every("empty", "vertexCount: -1"), "UndirectedAdjacencyList<Int>.empty(vertexCount: 0)", (0, 0)),
    95: (every("ladder", "rungCount: -1"), "UndirectedAdjacencyList<Int>.ladder(rungCount: 0)", (0, 0)),
    99: (every("circularLadder", "rungCount: 2") + every("circularLadder", "rungCount: 0", "U"),
         "UndirectedAdjacencyList<Int>.circularLadder(rungCount: 3)", (6, 9)),
    104: (every("barbell", "cliqueVertexCount: 1, pathVertexCount: 2"),
          "UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 2, pathVertexCount: 2)", (6, 5)),
    105: (every("barbell", "cliqueVertexCount: 3, pathVertexCount: -1"),
          "UndirectedAdjacencyList<Int>.barbell(cliqueVertexCount: 3, pathVertexCount: 0)", (6, 7)),
    110: (every("lollipop", "cliqueVertexCount: 1, pathVertexCount: 2"),
          "UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 2, pathVertexCount: 2)", (4, 3)),
    111: (every("lollipop", "cliqueVertexCount: 3, pathVertexCount: -1"),
          "UndirectedAdjacencyList<Int>.lollipop(cliqueVertexCount: 3, pathVertexCount: 0)", (3, 3)),
    117: (every("completeMultipartite", "partSizes: [2, -1]"),
          "UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [2, 0])", (2, 0)),
    118: (every("completeMultipartite", "partSizes: [1 << 32, 1 << 32]"),
          "UndirectedAdjacencyList<Int>.completeMultipartite(partSizes: [1 << 4, 1 << 4])", (32, 256)),
    124: (every("turan", "vertexCount: 5, partCount: 0"), "UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 1)", (5, 0)),
    125: (every("turan", "vertexCount: 5, partCount: 6") + every("turan", "vertexCount: 0, partCount: 0", "U"),
          "UndirectedAdjacencyList<Int>.turan(vertexCount: 5, partCount: 5)", (5, 10)),
    133: (every("balancedTree", "branchingFactor: 2, height: -1") + ["Tree<Int>.balancedTree(branchingFactor: 2, height: -1)"],
          "UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 2, height: 0)", (1, 0)),
    134: (every("balancedTree", "branchingFactor: -1, height: 2") + ["Tree<Int>.balancedTree(branchingFactor: -1, height: 2)"],
          "UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 0, height: 2)", (1, 0)),
    135: (every("balancedTree", "branchingFactor: 2, height: 63") + ["Tree<Int>.balancedTree(branchingFactor: 2, height: 63)"],
          "UndirectedAdjacencyList<Int>.balancedTree(branchingFactor: 1, height: 63)", (64, 63)),
}
TRAPS.update({
    143: (every("circulant", "vertexCount: 6, offsets: [1, 6]"), "UndirectedAdjacencyList<Int>.circulant(vertexCount: 6, offsets: [1, 5])", (6, 6)),
    144: (every("circulant", "vertexCount: 0, offsets: []"), "UndirectedAdjacencyList<Int>.circulant(vertexCount: 1, offsets: [])", (1, 0)),
    150: (every("generalizedPetersen", "outerCycleLength: 5, step: 0"),
          "UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 1)", (10, 15)),
    151: (every("generalizedPetersen", "outerCycleLength: 6, step: 3"),
          "UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 6, step: 2)", (12, 18)),
    152: (every("generalizedPetersen", "outerCycleLength: 2, step: 1"),
          "UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 3, step: 1)", (6, 9)),
    159: (every("kneser", "setSize: 4, subsetSize: 0"), "UndirectedAdjacencyList<Int>.kneser(setSize: 4, subsetSize: 1)", (4, 6)),
    160: (every("kneser", "setSize: 3, subsetSize: 4"), "UndirectedAdjacencyList<Int>.kneser(setSize: 3, subsetSize: 3)", (1, 0)),
    166: (every("windmill", "cliqueCount: 1, cliqueVertexCount: 3"),
          "UndirectedAdjacencyList<Int>.windmill(cliqueCount: 2, cliqueVertexCount: 3)", (5, 6)),
    167: (every("windmill", "cliqueCount: 3, cliqueVertexCount: 1"),
          "UndirectedAdjacencyList<Int>.windmill(cliqueCount: 3, cliqueVertexCount: 2)", (4, 3)),
    174: (every("binomialTree", "order: -1") + ["Tree<Int>.binomialTree(order: -1)"],
          "UndirectedAdjacencyList<Int>.binomialTree(order: 0)", (1, 0)),
    175: (every("binomialTree", "order: 63") + ["Tree<Int>.binomialTree(order: 63)"],
          "UndirectedAdjacencyList<Int>.binomialTree(order: 4)", (16, 15)),
    183: (every("fullRaryTree", "branchingFactor: 0, vertexCount: 3") + every("fullRaryTree", "branchingFactor: 0, vertexCount: 1")
          + ["Tree<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 3)", "Tree<Int>.fullRaryTree(branchingFactor: 0, vertexCount: 1)"],
          "UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 1, vertexCount: 3)", (3, 2)),
    184: (every("fullRaryTree", "branchingFactor: 2, vertexCount: -1"),
          "UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0)", (0, 0)),
    185: (["Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 0)", "Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: -1)"],
          "Tree<Int>.fullRaryTree(branchingFactor: 2, vertexCount: 1)", (1, 0)),
    191: (every("deBruijn", "alphabetSize: 0, wordLength: 2", "D"), "AdjacencyList<Int>.deBruijn(alphabetSize: 1, wordLength: 2)", (1, 1)),
    192: (every("deBruijn", "alphabetSize: 2, wordLength: 0", "D") + every("deBruijn", "alphabetSize: 1, wordLength: 0", "D"), "AdjacencyList<Int>.deBruijn(alphabetSize: 2, wordLength: 1)", (2, 4)),
    197: (every("kautz", "alphabetSize: 1, wordLength: 2", "D") + every("kautz", "alphabetSize: 1, wordLength: 1", "D"), "CompressedSparseRow.kautz(alphabetSize: 2, wordLength: 2)", (2, 2)),
    198: (every("kautz", "alphabetSize: 3, wordLength: 0", "D"), "CompressedSparseRow.kautz(alphabetSize: 3, wordLength: 1)", (3, 6)),
    206: (every("triangularLattice", "rowCount: -1, columnCount: 2") + every("triangularLattice", "rowCount: 2, columnCount: -1"),
          "UndirectedAdjacencyList<Int>.triangularLattice(rowCount: 0, columnCount: 2)", (0, 0)),
    214: (every("hexagonalLattice", "rowCount: 1, columnCount: -1") + every("hexagonalLattice", "rowCount: -1, columnCount: 1"),
          "UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: 1, columnCount: 0)", (0, 0)),
    221: (every("lcf", "vertexCount: 2, shifts: [1], repeatCount: 1"),
          "UndirectedAdjacencyList<Int>.lcf(vertexCount: 3, shifts: [1], repeatCount: 1)", (3, 3)),
    222: (every("lcf", "vertexCount: 6, shifts: [3, 6], repeatCount: 3"),
          "UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3, -3], repeatCount: 3)", (6, 9)),
    236: (every("kneser", "setSize: 70, subsetSize: 35"), "UndirectedAdjacencyList<Int>.kneser(setSize: 70, subsetSize: 69)", (70, 0)),
    223: (every("lcf", "vertexCount: 6, shifts: [3], repeatCount: -1"),
          "UndirectedAdjacencyList<Int>.lcf(vertexCount: 6, shifts: [3], repeatCount: 0)", (6, 6)),
})
TREE = {"path": lambda vertexCount: ref.tree_path(vertexCount), "star": lambda vertexCount: ref.tree_star(vertexCount),
        "balancedTree": lambda branchingFactor, height: ref.tree_balanced(branchingFactor, height),
        "binomialTree": lambda order: ref.tree_binomial(order),
        "fullRaryTree": lambda branchingFactor, vertexCount: ref.tree_full_rary(branchingFactor, vertexCount)}


def trap_test(n):
    calls, valid, (vn, vm) = TRAPS[n]
    assert call(n) in calls, n
    for c in calls:
        typ, fam, args, kwargs = parse(c)
        if typ == "Tree<Int>":
            fn = lambda: TREE[fam](**kwargs)
        elif typ.startswith("BipartiteGraph"):
            fn = lambda: ref.bipartite_complete(kwargs["leftCount"], kwargs["rightCount"])
        else:
            fn = lambda: FAMILIES[fam](typ in DIRECTED, **kwargs)
        try:
            fn()
            raise AssertionError("no trap: %s" % c)
        except ref.Trap as t:
            if c == call(n):
                assert cell(n) == "**trap**: %s" % t, (n, t)
    typ, fam, args, kwargs = parse(valid)
    g = (TREE[fam](**kwargs) if typ == "Tree<Int>" else FAMILIES[fam](typ in DIRECTED, **kwargs))
    assert (g.n, len(g.edges)) == (vn, vm), (n, g.n, len(g.edges))
    L = header(n, True)
    for c in calls:
        L.append("        await #expect(processExitsWith: .failure) {")
        L.append("            _ = %s" % c)
        L.append("        }")
    L.append("        // Without the fault: accepted.")
    L.append("        let graph = %s" % valid)
    L.append("        #expect(graph.vertexCount == %d && graph.edgeCount == %d)" % (vn, vm))
    L.append("    }")
    return L


def test_for(n):
    if is_trap(n):
        return trap_test(n)
    if call(n).startswith(("Tree<", "BipartiteGraph<")):
        return structure_row(n)
    return family_row(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, N + 1) if group(n) in groups and not is_trap(n)]


FILES = [
    ("CompleteGraphTests.swift", "NamedGraphs complete and complete bipartite graphs", ids("Complete", "CompleteBipartite"),
     "Complete and complete bipartite graphs (catalog NG-001 – NG-019): K_n on 0..<n with every pair, both\n"
     "// arcs when directed; K_{a,b} with left 0..<a and right a..<a+b, both arcs when directed; and\n"
     "// BipartiteGraph.completeBipartite with its sides."),
    ("PathCycleStarWheelTests.swift", "NamedGraphs paths, cycles, stars and wheels", ids("Path", "Cycle", "Star", "Wheel"),
     "Paths, cycles, stars and wheels (catalog NG-021 – NG-049): i – i+1; the cycle's closing edge stored\n"
     "// as 0 – (n − 1); hub 0; the wheel as a star and a rim cycle composed. Directed forms follow the\n"
     "// natural orientation. Tree.path and Tree.star."),
    ("GridHypercubePetersenTests.swift", "NamedGraphs grids, hypercubes, Petersen and empty graphs", ids("Grid", "Hypercube", "Petersen", "Empty"),
     "Grids, hypercubes, the Petersen graph and empty graphs (catalog NG-052 – NG-082): grids row-major\n"
     "// with the last dimension fastest, periodic wraps only in dimensions of length ≥ 3; Q_d by bits;\n"
     "// Petersen as outer 0–4, spokes i – i+5, inner pentagram; both arcs when directed."),
    ("RepresentationTests.swift", "NamedGraphs on every conformer", ids("Representations"),
     "Representations (catalog NG-084 – NG-090): one family on every conformer reads the same vertices\n"
     "// and the same edges in the same order."),
    ("LadderBarbellLollipopTests.swift", "NamedGraphs ladders, barbells and lollipops",
     ids("Ladder", "CircularLadder", "Barbell", "Lollipop"),
     "Ladders, circular ladders, barbells and lollipops (catalog NG-091 – NG-109): rails 0..<n and\n"
     "// n..<2n with rungs i – (i + n); cliques joined by a path. Both arcs when directed."),
    ("MultipartiteBalancedTreeTests.swift", "NamedGraphs complete multipartite, Turán and balanced tree graphs",
     ids("CompleteMultipartite", "Turan", "BalancedTree"),
     "Complete multipartite and Turán graphs and balanced trees (catalog NG-112 – NG-135): parts as\n"
     "// consecutive ranges, both arcs when directed; the balanced tree in breadth-first\n"
     "// order, parent → child when directed, and as a Tree."),
    ("CirculantKneserWindmillTests.swift", "NamedGraphs circulant, generalized Petersen, Kneser and windmill graphs",
     ids("Circulant", "GeneralizedPetersen", "Kneser", "Windmill"),
     "Circulant, generalized Petersen, Kneser and windmill graphs (catalog NG-136 – NG-165): offsets mod n,\n"
     "// each edge once; GP(n, k) as outer cycle, spokes and inner star polygon; k-subsets in lexicographic\n"
     "// order, adjacent when disjoint; cliques sharing hub 0. Both arcs when directed."),
    ("BinomialFullRaryTreeTests.swift", "NamedGraphs binomial and full r-ary trees", ids("BinomialTree", "FullRaryTree"),
     "Binomial and full r-ary trees (catalog NG-168 – NG-182): the parent of v is v & (v − 1), or (v − 1)/r;\n"
     "// parent → child when directed, and as a Tree."),
    ("DeBruijnKautzTests.swift", "NamedGraphs de Bruijn and Kautz graphs", ids("DeBruijn", "Kautz"),
     "De Bruijn and Kautz graphs (catalog NG-186 – NG-196): words in lexicographic order, each joined to the\n"
     "// words it shifts into; de Bruijn on the representations that allow self-loops."),
    ("TriangularHexagonalLatticeTests.swift", "NamedGraphs triangular and hexagonal lattices",
     ids("TriangularLattice", "HexagonalLattice"),
     "Triangular and hexagonal lattices (catalog NG-199 – NG-213): sized by triangles and hexagons, nodes\n"
     "// numbered row by row (triangular) or column by column (hexagonal). Both arcs when directed."),
    ("LCFNamedGraphTests.swift", "NamedGraphs LCF notation and the named cubic and other graphs",
     ids("LCF", "NamedLCF", "NamedConstructions"),
     "LCF notation and named graphs (catalog NG-215 – NG-235): the n-cycle and its chords; Heawood,\n"
     "// Möbius–Kantor, Pappus, Desargues, dodecahedral and Frucht in LCF; icosahedral, Tutte, Chvátal and\n"
     "// Hoffman–Singleton from their constructions. Both arcs when directed."),
    ("NamedGraphPreconditionTests.swift", "NamedGraphs preconditions", [n for n in range(1, N + 1) if is_trap(n)],
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test), on every\n"
     "// conformer the rule covers. A valid neighbour of the call then runs in this process."),
]
IMPORTS = {"AdjacencyListModule": ("AdjacencyList<", "UndirectedAdjacencyList<"), "AdjacencyMatrixModule": ("AdjacencyMatrix",),
           "CompressedSparseRowModule": ("CompressedSparseRow",), "Multigraphs": ("Pseudograph<", "Multigraph<"),
           "StableGraphs": ("StableDirectedGraph",), "Trees": ("Tree<",), "BipartiteGraphs": ("BipartiteGraph<",)}


def write(fname, suite, rws, comment):
    body = []
    for i, n in enumerate(rws):
        if i:
            body.append("")
        body += test_for(n)
    text = "\n".join(body)
    imports = ["GraphProtocols", "NamedGraphs", "Testing"]
    for module, needles in IMPORTS.items():
        if any(x in text for x in needles):
            imports.append(module)
    pre = fname == "NamedGraphPreconditionTests.swift"
    if pre:
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, ", .tags(.precondition)" if pre else ""), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname, suite, rws, comment in FILES:
    k = write(fname, suite, rws, comment)
    print(fname, k)
    total += k
    rows_total += len(rws)
assert rows_total == N == total, (rows_total, total)
print("catalog rows", rows_total, "tests", total)
