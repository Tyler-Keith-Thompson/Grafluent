"""Generate the catalog-row Swift test files of Tests/CliquesTests from cases.md.

Every Expected literal is the catalog cell, re-evaluated with ref.py's model and required to
equal it. Representation literals are computed with ref.py's model functions on the simple rows
each representation stores.

Run (from the repository root; OUTDIR defaults to Tests/CliquesTests):
    uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/Cliques/gen.py [OUTDIR]
"""

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ref  # noqa: E402

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE.parent.parent / "CliquesTests"
lines_, ROWS, ORDER = ref.read_rows(ref.CASES, "CQ")

PINNED_ORDER = {"CQ-101", "CQ-102"}  # api.md cites these for the sequence order


def lit(v):
    return f'"{v}"' if isinstance(v, str) else str(v)


def vlist(vs):
    return "[" + ", ".join(lit(v) for v in vs) + "]"


def is_str(g):
    return any(isinstance(v, str) for v in g.vertices)


def vtype(g):
    return "String" if is_str(g) else "Int"


def wrap_items(items, indent, width=104):
    """A Swift array literal, on one line if it fits, else wrapped like the Distances suite."""
    one = "[" + ", ".join(items) + "]"
    if len(indent) + len(one) + 30 <= width + 20:
        return one
    out, cur = [], ""
    for it in items:
        piece = it if not cur else cur + ", " + it
        if len(indent) + 4 + len(piece) > width and cur:
            out.append(cur + ",")
            cur = it
        else:
            cur = piece
    out.append(cur)
    inner = indent + "    "
    return "[\n" + "\n".join(inner + l for l in out) + "\n" + indent + "]"


def first_appearance(pairs):
    seen, out = set(), []
    for a, b in pairs:
        for x in (a, b):
            if x not in seen:
                seen.add(x)
                out.append(x)
    return out


def vertices_expr(labels):
    if labels and labels == list(range(len(labels))):
        return f"0 ..< {len(labels)}"
    return vlist(labels)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def graph_desc(cell):
    cell = cell.strip("`")
    kind, rest = cell.split(":", 1)
    return f"{kind.strip()}({rest.strip()})"


def build_graph(cell, indent, ctor="ReferencePseudograph", rev_ctor="ReversedRowsPseudograph"):
    """Lines that bind `graph` to the catalog graph."""
    cell = cell.strip("`")
    g = ref.parse_graph(cell)
    rev = cell.endswith("~rev")
    T = vtype(g)
    labels = g.vertices
    pairs = [(labels[a], labels[b]) for a, b in g.ends]
    out = [f"// {cell}"]
    items = [f"({lit(a)}, {lit(b)})" for a, b in pairs]
    if g.directed:
        out.append(f"let arcs: [({T}, {T})] = {wrap_items(items, indent)}")
        if first_appearance(pairs) == labels:
            out.append("let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected")
        else:
            out.append(f"let graph = ReferenceDirectedMultigraph(vertices: {vertices_expr(labels)}, edges: arcs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected")
        return out
    c = rev_ctor if rev else ctor
    if not pairs:
        vs = vlist(labels)
        out.append(f"let graph = {c}<{T}>(vertices: {vs}, edges: [])")
        return out
    out.append(f"let pairs: [({T}, {T})] = {wrap_items(items, indent)}")
    if first_appearance(pairs) == labels:
        out.append(f"let graph = {c}(edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
    else:
        out.append(f"let graph = {c}(vertices: {vertices_expr(labels)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
    return out


def parse_expected(g, exp):
    """The Expected cell as Python data in vertex labels."""
    exp = exp.strip("`")
    if exp.startswith("#"):
        s = exp[1:]
        return float(s) if ("." in s or "e" in s) else int(s)
    return exp


def label_list(g, s):
    s = s.strip()
    assert s.startswith("[") and s.endswith("]")
    inner = s[1:-1].strip()
    if not inner:
        return []
    return [ref.vtok(x) for x in inner.split(",")]


def clique_list(s):
    s = s.strip()[1:-1].strip()
    if not s:
        return []
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "[":
            depth += 1
            cur = ""
            continue
        if ch == "]":
            depth -= 1
            out.append([ref.vtok(x) for x in cur.split(",") if x.strip()])
            continue
        if depth:
            cur += ch
    return out


def num_list(s):
    s = s.strip()[1:-1].strip()
    if not s:
        return []
    return [float(x) if "." in x else int(x) for x in s.split(",")]


def cliques_lit(cl, indent):
    return wrap_items([vlist(c) for c in cl], indent)


def body_for(rid, row, indent):
    cell, op, exp = row["Graph"].strip("`"), row["Op"].strip("`"), row["Expected"].strip("`")
    got = ref.evaluate(cell, op)
    assert got == exp, (rid, got, exp)
    g = ref.parse_graph(cell)
    T = vtype(g)
    view, name, arg = ref.parse_op(op)
    L = build_graph(cell, indent)
    labels_ok = g.vertices == list(range(len(g.vertices)))
    if name == "maximalCliques":
        cl = clique_list(exp)
        L += [f"let expected: [[{T}]] = {cliques_lit(cl, indent)}",
              "let cliques = Array(graph.maximalCliques())",
              "#expect(Set(cliques) == Set(expected))",
              "#expect(cliques.count == expected.count)"]
        if rid in PINNED_ORDER:
            L.append("#expect(cliques == expected)")
        L += ["for clique in cliques {",
              "    let unjoined = clique.indices.flatMap { i in clique[(i + 1)...].filter { !graph.contains(edge: UndirectedEdge(clique[i], $0)) } }",
              '    #expect(unjoined.isEmpty, "\\(clique) is not a clique")',
              "    let extenders = graph.vertices.filter { w in !clique.contains(w) && clique.allSatisfy { graph.contains(edge: UndirectedEdge(w, $0)) } }",
              '    #expect(extenders.isEmpty, "\\(clique) is not maximal")',
              "}",
              "let viaArcs = Array(graph.directed.undirected.maximalCliques())",
              "#expect(Set(viaArcs) == Set(expected))",
              "#expect(viaArcs.count == expected.count)"]
        return L
    if name == "maximalCliques.count":
        k = parse_expected(g, exp)
        L += ["let cliques = Array(graph.maximalCliques())",
              f"#expect(cliques.count == {k})",
              f"#expect(Set(cliques).count == {k})"]
        if labels_ok:
            L.append("#expect(cliques.allSatisfy { $0 == $0.sorted() })")
        return L
    if name == "maximumClique":
        L += [f"let expected: [{T}] = {vlist(label_list(g, exp))}",
              "#expect(graph.maximumClique() == expected)",
              "#expect(graph.cliqueNumber() == expected.count)",
              "#expect(graph.directed.undirected.maximumClique() == expected)"]
        return L
    if name == "cliqueNumber":
        k = parse_expected(g, exp)
        L += [f"#expect(graph.cliqueNumber() == {k})",
              f"#expect(graph.maximumClique().count == {k})",
              "let degeneracy = graph.coreNumbers().degeneracy",
              f"#expect({k} <= degeneracy + 1)",
              f"#expect(graph.directed.undirected.cliqueNumber() == {k})"]
        return L
    if name == "coreNumbers":
        L += [f"let expected: [Int] = {wrap_items([str(x) for x in num_list(exp)], indent)}",
              "let cores = graph.coreNumbers()",
              "let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }",
              "#expect(byIndex == expected)",
              "let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }",
              "#expect(byVertex == expected)",
              "#expect(cores.degeneracy == (expected.max() ?? 0))",
              "let view = graph.directed.undirected.coreNumbers()",
              "let viaArcs = (0 ..< graph.vertexCount).map { view.coreNumber(ofIndex: $0) }",
              "#expect(viaArcs == expected)"]
        return L
    if name == "degeneracy":
        k = parse_expected(g, exp)
        L += ["let cores = graph.coreNumbers()",
              f"#expect(cores.degeneracy == {k})",
              "let byIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }",
              f"#expect((byIndex.max() ?? 0) == {k})",
              f"#expect(graph.cliqueNumber() <= {k} + 1)",
              f"#expect(graph.directed.undirected.coreNumbers().degeneracy == {k})"]
        return L
    if name == "degeneracyOrdering":
        L += [f"let expected: [{T}] = {wrap_items([lit(x) for x in label_list(g, exp)], indent)}",
              "let cores = graph.coreNumbers()",
              "#expect(cores.degeneracyOrdering == expected)",
              "#expect(graph.directed.undirected.coreNumbers().degeneracyOrdering == expected)",
              "// At most its own core number of neighbours after each vertex, and core numbers never decrease.",
              "for (i, v) in expected.enumerated() {",
              "    let later = expected[(i + 1)...].filter { graph.contains(edge: UndirectedEdge(v, $0)) }",
              '    #expect(later.count <= cores.coreNumber(of: v), "\\(v)")',
              "}",
              "let coresInOrder = expected.map { cores.coreNumber(of: $0) }",
              "#expect(coresInOrder == coresInOrder.sorted())"]
        return L
    if name in ("kCore", "kShell"):
        k = int(arg)
        cmp = ">=" if name == "kCore" else "=="
        L += [f"let expected: [{T}] = {vlist(label_list(g, exp))}",
              "let cores = graph.coreNumbers()",
              f"#expect(cores.{name}({k}) == expected)",
              f"let byCore = graph.vertices.filter {{ cores.coreNumber(of: $0) {cmp} {k} }}",
              "#expect(byCore == expected)",
              f"#expect(graph.directed.undirected.coreNumbers().{name}({k}) == expected)"]
        return L
    if name == "triangleCount" and arg is None:
        k = parse_expected(g, exp)
        L += ["let values = graph.clusteringCoefficients()",
              f"#expect(graph.triangleCount() == {k})",
              f"#expect(values.triangleCount == {k})",
              "let perVertex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }",
              f"#expect(perVertex.reduce(0, +) == 3 * {k})",
              f"#expect(graph.directed.undirected.triangleCount() == {k})"]
        return L
    if name == "triangleCounts":
        L += [f"let expected: [Int] = {wrap_items([str(x) for x in num_list(exp)], indent)}",
              "let values = graph.clusteringCoefficients()",
              "let byIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }",
              "#expect(byIndex == expected)",
              "let byVertex = graph.vertices.map { values.triangleCount(of: $0) }",
              "#expect(byVertex == expected)",
              "let oneByOne = graph.vertices.map { graph.triangleCount(of: $0) }",
              "#expect(oneByOne == expected)",
              "#expect(values.triangleCount * 3 == expected.reduce(0, +))",
              "let view = graph.directed.undirected.clusteringCoefficients()",
              "let viaArcs = (0 ..< graph.vertexCount).map { view.triangleCount(ofIndex: $0) }",
              "#expect(viaArcs == expected)"]
        return L
    if name == "clusteringCoefficients":
        xs = [repr(float(x)) for x in num_list(exp)]
        L += [f"let expected: [Double] = {wrap_items(xs, indent)}",
              "let values = graph.clusteringCoefficients()",
              "let byIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }",
              "#expect(byIndex == expected)",
              "let byVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }",
              "#expect(byVertex == expected)",
              "let oneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }",
              "#expect(oneByOne == expected)",
              "#expect(values.transitivity == graph.transitivity())",
              "#expect(values.averageClustering == graph.averageClustering())",
              "let view = graph.directed.undirected.clusteringCoefficients()",
              "let viaArcs = (0 ..< graph.vertexCount).map { view.clusteringCoefficient(ofIndex: $0) }",
              "#expect(viaArcs == expected)"]
        return L
    if name in ("transitivity", "averageClustering"):
        x = repr(parse_expected(g, exp))
        L += [f"#expect(graph.{name}() == {x})",
              f"#expect(graph.clusteringCoefficients().{name} == {x})",
              f"#expect(graph.directed.undirected.{name}() == {x})"]
        return L
    if name in ("triangleCount", "clusteringCoefficient"):
        v = lit(ref.vtok(arg.split(":", 1)[1]))
        x = parse_expected(g, exp)
        xs = repr(x) if isinstance(x, float) else str(x)
        L += [f"#expect(graph.{name}(of: {v}) == {xs})",
              f"#expect(graph.clusteringCoefficients().{name}(of: {v}) == {xs})",
              f"#expect(graph.directed.undirected.{name}(of: {v}) == {xs})"]
        return L
    raise AssertionError((rid, op))


FUNC = {
    "maximalCliques": "maximalCliques", "maximalCliques.count": "maximalCliqueCount", "maximumClique": "maximumClique",
    "cliqueNumber": "cliqueNumber", "coreNumbers": "coreNumbers", "degeneracy": "degeneracy",
    "degeneracyOrdering": "degeneracyOrdering", "kCore": "kCore", "kShell": "kShell", "triangleCount": "triangleCount",
    "triangleCounts": "triangleCounts", "clusteringCoefficients": "clusteringCoefficients", "transitivity": "transitivity",
    "averageClustering": "averageClustering", "clusteringCoefficient": "clusteringCoefficient",
}


def test_for(rid, row):
    cell, op, exp, notes = row["Graph"].strip("`"), row["Op"].strip("`"), row["Expected"].strip("`"), row.get("Notes", "")
    _, name, arg = ref.parse_op(op)
    fname = FUNC[name]
    if name == "triangleCount" and arg is not None:
        fname = "triangleCountOf"
    if name == "clusteringCoefficient":
        fname = "clusteringCoefficientOf"
    fname += rid.split("-")[1]
    shown = exp if len(exp) <= 90 else "listed below"
    title = f"{rid} {graph_desc(cell)}.{op} is {shown}"
    if notes.strip():
        title += ": " + notes.strip()
    ind = "        "
    body = body_for(rid, row, ind)
    out = [f'    @Test("{esc(title)}")', f"    func {fname}() {{"]
    for l in body:
        for sub in l.split("\n"):
            out.append(ind + sub if not sub.startswith(ind) else sub)
    out.append("    }")
    return "\n".join(out)


REVERSED_CONFORMER = '''
/// An undirected pseudograph whose incidence rows are reversed (the catalog's `~rev`): each row
/// is built in position order (a self-loop twice), then reversed. Vertex and edge indices are
/// positions.
private struct ReversedRowsPseudograph<Vertex: Hashable>: Graph {
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

    init(edges: [UndirectedEdge<Vertex>]) {
        self.init(vertices: [], edges: edges)
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
'''


def section_file(fname, header, imports, suite, struct, ids, skip):
    tests = [test_for(r, ROWS[r]) for r in ids if r not in skip]
    needs_rev = any(ROWS[r]["Graph"].strip("`").endswith("~rev") for r in ids if r not in skip)
    src = header.rstrip() + "\n\n" + "\n".join(f"import {m}" for m in imports) + "\n"
    if needs_rev:
        src += REVERSED_CONFORMER
    src += f'\n@Suite("{suite}")\nstruct {struct} {{\n' + "\n\n".join(tests) + "\n}\n"
    (OUT / fname).write_text(src)
    return len(tests)


def ids_in(lo, hi):
    return [r for r in ORDER if lo <= int(r.split("-")[1]) <= hi]


IMPORTS = ["Cliques", "GrafluentTestSupport", "GraphProtocols", "Testing"]

counts = {}
counts["DegenerateGraphTests.swift"] = section_file(
    "DegenerateGraphTests.swift",
    """// §A: the empty graph, K₁, K₁ with a self-loop, two isolated vertices, K₂ and K₂ as three parallel
// edges, every op on each (CQ-001 – CQ-060), and the 0-core, a loop adding no degree, the 0-shell,
// and one-vertex queries (CQ-061 – CQ-067). The empty graph has no cliques, ω = 0, degeneracy 0,
// transitivity and average clustering 0 (NetworkX raises on the average; igraph gives NaN). An
// isolated vertex is a clique of one; a loop and parallel copies are ignored by every op. Each
// test also checks the one-shot calls against the members of the returned value and the same op on
// `graph.directed.undirected` (every edge as two arcs, read back as two parallel edges). Every
// literal is a catalog cell (`ref.py`: api.md's model, brute force, NetworkX 3.7). CQ-068 and
// CQ-069 (preconditions) are exit tests in `CliquePreconditionTests.swift`. Case IDs (CQ-nnn) refer
// to the catalog; see README.md.""",
    IMPORTS, "Degenerate graphs", "DegenerateGraphTests", ids_in(1, 99), {"CQ-068", "CQ-069"})

counts["MaximalCliqueTests.swift"] = section_file(
    "MaximalCliqueTests.swift",
    """// §B: maximal cliques (CQ-101 – CQ-124). Each test compares the sequence with the catalog as a set
// of arrays, so every clique's members must be in `vertices` order exactly while the sequence order
// is free; no clique may repeat. CQ-101 and CQ-102 also pin the sequence order, as api.md does
// ("Order of maximal cliques": the degeneracy ordering decides it, so the pendant vertex's clique
// comes first). Every listed clique is checked to be a clique (`contains(edge:)` for each pair) and
// maximal (no outside vertex adjacent to all of it), and `graph.directed.undirected` must give the
// same set. Graphs: a triangle with a pendant, K₄, K₅, C₄, C₅, P₅, stars with the centre first and
// last, the bowtie, the diamond, the wheel W₆, K₃,₃ in two numberings, isolated vertices, loops and
// parallel edges, String labels with `vertices` reversed, Petersen, the karate club (36 cliques)
// and moon(4) (81). Every literal is a catalog cell (`ref.py`: api.md's model, brute force over
// vertex subsets, NetworkX 3.7 `find_cliques`). Case IDs (CQ-nnn) refer to the catalog; see
// README.md.""",
    IMPORTS, "Maximal cliques", "MaximalCliqueTests", ids_in(101, 199), set())

counts["MaximumCliqueTests.swift"] = section_file(
    "MaximumCliqueTests.swift",
    """// §C: the maximum clique and the clique number (CQ-201 – CQ-220). `maximumClique()` is the
// lexicographically least largest clique by vertex index: of two disjoint triangles the one with the
// least index, also when `vertices` is reversed (CQ-203) or the edges are written the other way
// round (CQ-205); the first vertex of an edgeless graph (CQ-207, where NetworkX's
// `max_weight_clique` returns the last); [0, 1, 2, 3, 7] over [0, 1, 2, 3, 13] on the karate club
// (CQ-211). Each test also checks `maximumClique().count == cliqueNumber()`, `cliqueNumber() <=
// degeneracy + 1` and `graph.directed.undirected`. Every literal is a catalog cell (`ref.py`:
// brute force over the maximal cliques, NetworkX 3.7). Case IDs (CQ-nnn) refer to the catalog; see
// README.md.""",
    IMPORTS, "Maximum clique and clique number", "MaximumCliqueTests", ids_in(201, 299), set())

counts["CoreNumberTests.swift"] = section_file(
    "CoreNumberTests.swift",
    """// §D: core numbers, degeneracy, the degeneracy ordering, k-cores and k-shells (CQ-301 – CQ-349), all
// on the simple graph: a parallel pair or a loop adds nothing (CQ-328 – CQ-333; igraph counts them,
// NetworkX raises). Core numbers are checked by index, by vertex and on `graph.directed.undirected`;
// the degeneracy ordering exactly (api.md pins Batagelj–Zaversnik's removal order: a stable counting
// sort by degree, neighbours in row order), together with its defining property (at most core(v)
// neighbours after each v, core numbers nondecreasing along it). `~rev` rows use a conformer private
// to this file whose rows are reversed. Every literal is a catalog cell (`ref.py`: api.md's model,
// peeling, NetworkX 3.7 `core_number`). Case IDs (CQ-nnn) refer to the catalog; see README.md.""",
    IMPORTS, "Core numbers and degeneracy", "CoreNumberTests", ids_in(301, 399), set())

counts["TriangleClusteringTests.swift"] = section_file(
    "TriangleClusteringTests.swift",
    """// §E: triangle counts, local clustering, transitivity and average clustering (CQ-401 – CQ-465), on
// the simple graph: a parallel edge and a loop change nothing (CQ-441; JGraphT would count 2). Local
// clustering is 2T/(d(d − 1)) with d the simple degree, 0 when d < 2 (igraph: NaN); transitivity 0
// with no triangle, even with no connected triple (CQ-459; igraph NaN); the average over every
// vertex, zeros included. Doubles are compared exactly: api.md computes each ratio as one integer
// division converted once, and sums the average plainly in `vertices` order, and the catalog pins
// those bits. Per-vertex values are checked by index, by vertex on the value, one vertex at a time
// on the graph, and on `graph.directed.undirected`. Every literal is a catalog cell (`ref.py`:
// marking, Latapy's compact-forward, NetworkX 3.7). CQ-466 (not a vertex) is an exit test in
// `CliquePreconditionTests.swift`. Case IDs (CQ-nnn) refer to the catalog; see README.md.""",
    IMPORTS, "Triangles and clustering", "TriangleClusteringTests", ids_in(401, 499), {"CQ-466"})

counts["DigraphUndirectedTests.swift"] = section_file(
    "DigraphUndirectedTests.swift",
    """// §F: directed graphs through `digraph.undirected` (CQ-501 – CQ-515). The view keeps two opposite
// arcs as two parallel edges; the simple graph merges them, which is igraph's "directions ignored"
// reading (NetworkX raises for cliques and triangles on a DiGraph and counts in + out degree for
// cores). Digraphs are `ReferenceDirectedMultigraph`s with arcs in written order. Every literal is
// a catalog cell (`ref.py`). Case IDs (CQ-nnn) refer to the catalog; see README.md.""",
    IMPORTS, "Directed graphs through undirected", "DigraphUndirectedTests", ids_in(501, 599), set())

# ---------------------------------------------------------------------------------------------
# Representations
# ---------------------------------------------------------------------------------------------


def simple_from_rows(rows):
    out = []
    for v, r in enumerate(rows):
        seen, row = set(), []
        for w in r:
            if w != v and w not in seen:
                seen.add(w)
                row.append(w)
        out.append(row)
    return out


def rows_adjacency_list(g):
    """AdjacencyList(vertices:edges:) of the arcs as written, read through `.undirected`: repeated
    arcs inserted once; each row out-neighbours then in-neighbours, both in insertion order."""
    arcs, seen = [], set()
    for a, b in g.ends:
        if (a, b) not in seen:
            seen.add((a, b))
            arcs.append((a, b))
    rows = [[] for _ in range(g.n)]
    for a, b in arcs:
        rows[a].append(b)
    for a, b in arcs:
        rows[b].append(a)
    return simple_from_rows(rows)


def rows_matrix(g):
    """AdjacencyMatrix of the arcs as written, through `.undirected`: successors ascending, then
    predecessors ascending."""
    arcs = set(g.ends)
    rows = []
    for v in range(g.n):
        rows.append(sorted(b for a, b in arcs if a == v) + sorted(a for a, b in arcs if b == v))
    return simple_from_rows(rows)


def rows_csr(g):
    """The symmetric CSR conformer: neighbours ascending (each twice)."""
    nb = [set() for _ in range(g.n)]
    for a, b in g.ends:
        nb[a].add(b)
        nb[b].add(a)
    rows = [sorted(s) * 2 for s in nb]
    return simple_from_rows(rows)


def values(adj):
    core, order = ref.batagelj_zaversnik(adj)
    cl = ref.maximal_cliques_model(adj)
    if cl:
        w = max(len(c) for c in cl)
        best = min(c for c in cl if len(c) == w)
    else:
        best = []
    tri = ref.compact_forward_total(adj)[1]
    cc = ref.clustering_model(adj, tri)
    return dict(cliques=cl, maximum=best, omega=len(best), core=core, degeneracy=max(core, default=0), order=order,
                tri=tri, total=sum(tri) // 3, cc=cc, transitivity=ref.transitivity_model(adj, tri), average=ref.average_model(cc))


def order_free(v):
    return (sorted(map(tuple, v["cliques"])), v["maximum"], v["core"], v["tri"], v["cc"], v["transitivity"], v["average"])


GRAPH_IDS = {}
for r in ORDER:
    n = int(r.split("-")[1])
    cell = ROWS[r]["Graph"].strip("`")
    if n >= 600 or cell.startswith("D:") or cell.endswith("~rev"):
        continue
    GRAPH_IDS.setdefault(cell, []).append(r)


def ids_label(ids):
    if len(ids) <= 2:
        return ", ".join(ids)
    return f"{ids[0]}, {ids[1]} … {ids[-1]}"


def checks(v, labels, T, indent, onebyone=True):
    lab = lambda xs: [labels[i] for i in xs]
    L = [f"let expectedCliques: [[{T}]] = {wrap_items([vlist(lab(c)) for c in v['cliques']], indent)}",
         "let cliques = Array(graph.maximalCliques())",
         "#expect(Set(cliques) == Set(expectedCliques))",
         "#expect(cliques.count == expectedCliques.count)",
         f"#expect(graph.maximumClique() == {vlist(lab(v['maximum'])) if v['maximum'] else '[]'})",
         f"#expect(graph.cliqueNumber() == {v['omega']})",
         "let cores = graph.coreNumbers()",
         f"let expectedCores: [Int] = {wrap_items([str(x) for x in v['core']], indent)}",
         "let coresByIndex = (0 ..< graph.vertexCount).map { cores.coreNumber(ofIndex: $0) }",
         "#expect(coresByIndex == expectedCores)",
         "let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }",
         "#expect(coresByVertex == expectedCores)",
         f"#expect(cores.degeneracy == {v['degeneracy']})",
         f"let expectedOrdering: [{T}] = {wrap_items([lit(x) for x in lab(v['order'])], indent)}",
         "#expect(cores.degeneracyOrdering == expectedOrdering)"]
    d = v["degeneracy"]
    kc = [labels[i] for i in range(len(labels)) if v["core"][i] >= d]
    L.append(f"#expect(cores.kCore({d}) == {vlist(kc) if kc else '[]'})")
    if v["core"]:
        lo = min(v["core"])
        ks = [labels[i] for i in range(len(labels)) if v["core"][i] == lo]
        L.append(f"#expect(cores.kShell({lo}) == {vlist(ks)})")
    L += ["let values = graph.clusteringCoefficients()",
          f"let expectedTriangles: [Int] = {wrap_items([str(x) for x in v['tri']], indent)}",
          "let trianglesByIndex = (0 ..< graph.vertexCount).map { values.triangleCount(ofIndex: $0) }",
          "#expect(trianglesByIndex == expectedTriangles)"]
    if onebyone:
        L += ["let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }",
              "#expect(trianglesOneByOne == expectedTriangles)"]
    L += [f"let expectedClustering: [Double] = {wrap_items([repr(x) for x in v['cc']], indent)}",
          "let clusteringByIndex = (0 ..< graph.vertexCount).map { values.clusteringCoefficient(ofIndex: $0) }",
          "#expect(clusteringByIndex == expectedClustering)"]
    if onebyone:
        L += ["let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }",
              "#expect(clusteringOneByOne == expectedClustering)"]
    L += [f"#expect(graph.triangleCount() == {v['total']})",
          f"#expect(values.triangleCount == {v['total']})",
          f"#expect(graph.transitivity() == {repr(v['transitivity'])})",
          f"#expect(values.transitivity == {repr(v['transitivity'])})",
          f"#expect(graph.averageClustering() == {repr(v['average'])})",
          f"#expect(values.averageClustering == {repr(v['average'])})"]
    return L


def rep_test(kind, cell, ids, idx):
    g = ref.parse_graph(cell)
    T = vtype(g)
    labels = g.vertices
    pairs = [(labels[a], labels[b]) for a, b in g.ends]
    ind = "        "
    items = [f"({lit(a)}, {lit(b)})" for a, b in pairs]
    base_vals = values(g.simple())
    L = [f"// {cell}"]
    fa = first_appearance(pairs) == labels
    vx = vertices_expr(labels) if labels else "[]"
    if kind == "ual":
        name, title = "undirectedAdjacencyList", "UndirectedAdjacencyList (repeats inserted once)"
        L.append(f"let pairs: [({T}, {T})] = {wrap_items(items, ind)}")
        L.append(f"let graph = UndirectedAdjacencyList(vertices: {vx}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        adj = g.simple()
    elif kind == "al":
        name, title = "adjacencyListUndirected", "AdjacencyList.undirected (arcs as written; rows out-neighbours then in-neighbours)"
        L.append(f"let arcs: [({T}, {T})] = {wrap_items(items, ind)}")
        L.append(f"let graph = AdjacencyList(vertices: {vx}, edges: arcs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected")
        adj = rows_adjacency_list(g)
    elif kind == "csr":
        name, title = "compressedSparseRow", "CompressedSparseRow (each edge as two arcs; rows ascending)"
        L.append(f"let pairs: [(Int, Int)] = {wrap_items(items, ind)}")
        L.append(f"let graph = SymmetricCSRGraph(vertexCount: {len(labels)}, edges: pairs)")
        adj = rows_csr(g)
    elif kind == "matrix":
        name, title = "adjacencyMatrixUndirected", "AdjacencyMatrix.undirected (arcs as written; successors then predecessors, ascending)"
        L.append(f"let arcs: [(Int, Int)] = {wrap_items(items, ind)}")
        L.append(f"let graph = AdjacencyMatrix(vertexCount: {len(labels)}, edges: arcs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected")
        adj = rows_matrix(g)
    else:
        raise AssertionError(kind)
    v = values(adj)
    assert order_free(v) == order_free(base_vals), (kind, cell)
    if kind == "ual":
        assert v == base_vals
    L += checks(v, labels, T, ind)
    head = [f'    @Test("{ids_label(ids)} on {esc(title)}: {esc(cell)}")', f"    func {name}{idx:02d}() {{"]
    body = []
    for l in L:
        for sub in l.split("\n"):
            body.append(sub if sub.startswith(ind) else ind + sub)
    return "\n".join(head + body + ["    }"]), name


def extra_test(kind, cell, ids, idx):
    """Conformers without indices, with vertex indices only, rows reversed, Collider vertices."""
    g = ref.parse_graph(cell)
    T = vtype(g)
    labels = g.vertices
    pairs = [(labels[a], labels[b]) for a, b in g.ends]
    ind = "        "
    items = [f"({lit(a)}, {lit(b)})" for a, b in pairs]
    vx = vlist(labels)
    L = [f"// {cell}", f"let pairs: [({T}, {T})] = {wrap_items(items, ind)}"]
    if kind == "plain":
        name, title = "plainGraph", "a conformer without indices"
        L.append(f"let graph = PlainGraph(vertices: {vx}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        adj = g.simple()
    elif kind == "vertexIndexed":
        name, title = "vertexIndexedGraph", "a conformer with vertex indices only"
        L.append(f"let graph = VertexIndexedGraph(vertices: {vx}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        adj = g.simple()
    elif kind == "reversed":
        name, title = "reversedRows", "rows reversed (~rev)"
        L.append(f"let graph = ReversedRowsPseudograph(vertices: {vx}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        adj = ref.G(False, g.vertices, g.ends, rev=True).simple()
    else:
        raise AssertionError(kind)
    v = values(adj)
    assert order_free(v) == order_free(values(g.simple()))
    L += checks(v, labels, T, ind)
    head = [f'    @Test("{ids_label(ids)} on {esc(title)}: {esc(cell)}")', f"    func {name}{idx:02d}() {{"]
    body = []
    for l in L:
        for sub in l.split("\n"):
            body.append(sub if sub.startswith(ind) else ind + sub)
    return "\n".join(head + body + ["    }"]), name


REP_HEADER = """// The same answers on every representation. Every catalog test already runs on the
// `ReferencePseudograph` as the catalog writes it, and on `graph.directed.undirected`; this file
// runs each undirected catalog graph of §A – §E on `UndirectedAdjacencyList` (repeated edges
// inserted once, which leaves the simple graph and its row order unchanged), on
// `AdjacencyList.undirected` with each edge as one arc as written (rows: out-neighbours, then
// in-neighbours), and, for graphs on 0..<n, on `CompressedSparseRow` holding each edge as two arcs
// (read through a conformer private to this file, rows ascending) and on `AdjacencyMatrix.undirected`
// (successors, then predecessors, each ascending). It also runs a few graphs on conformers private to
// this file: without indices, with vertex indices only, with rows reversed, and with `Collider`
// vertices that all hash alike. Each test checks every entry point. Answers that do not depend on
// row order (the cliques as a set, ω, the maximum clique, core numbers, triangles, clustering) are the
// catalog's; the degeneracy ordering depends on row order (api.md: neighbours in row order), so it
// was computed with `ref.py`'s Batagelj–Zaversnik on the simple rows each representation stores,
// as were all literals here. Case IDs (CQ-nnn) name the catalog rows on each graph; see README.md."""

REP_CONFORMERS = '''
/// An undirected graph stored in a `CompressedSparseRow` that holds each edge `{u, v}` as the arcs
/// `u→v` and `v→u` (a loop as one arc). Each arc is an edge of this graph at the arc's position, so
/// every edge between distinct vertices appears twice (a parallel pair) and the simple graph is the
/// one given. A vertex's incidence row is its out-arcs, then the arcs into it from its successors,
/// both ascending by neighbour, so a loop's arc is listed twice.
private struct SymmetricCSRGraph: Graph {
    let csr: CompressedSparseRow

    init(vertexCount: Int, edges: [(Int, Int)]) {
        let arcs = edges.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] }
        self.csr = CompressedSparseRow(vertexCount: vertexCount, edges: arcs)
    }

    var vertices: Range<Int> { csr.vertices }
    var edges: [UndirectedEdge<Int>] { csr.edges.map { UndirectedEdge($0.source, $0.target) } }

    /// The position of the arc `from → to`.
    private func position(from: Int, to: Int) -> Int {
        let row = csr.offsets[from] ..< csr.offsets[from + 1]
        return row.first { csr.targets[$0] == to }!
    }

    func incidentEdges(of vertex: Int) -> [Int] {
        Array(csr.outEdges(of: vertex)) + csr.successors(of: vertex).map { position(from: $0, to: vertex) }
    }
    func neighbors(of vertex: Int) -> [Int] { Array(csr.successors(of: vertex)) + Array(csr.successors(of: vertex)) }
    func contains(_ vertex: Int) -> Bool { csr.contains(vertex) }
    var vertexIndexBound: Int? { csr.vertexCount }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { csr.edgeCount }
    func edgeIndex(of position: Int) -> Int { position }
}

/// An undirected pseudograph with no vertex or edge indices, rows in position order (a self-loop
/// twice), so the algorithms number vertices through a dictionary.
private struct PlainGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// Vertex indices (the positions in `vertices`) but no edge indices, rows in position order.
private struct VertexIndexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { vertices.firstIndex(of: vertex)! }
    func vertex(atIndex index: Int) -> Vertex { vertices[index] }
}
'''

rep_tests = []
idx = {"ual": 0, "al": 0, "csr": 0, "matrix": 0}
for kind in ("ual", "al", "csr", "matrix"):
    for cell, ids in GRAPH_IDS.items():
        g = ref.parse_graph(cell)
        if kind in ("csr", "matrix") and g.vertices != list(range(g.n)):
            continue
        idx[kind] += 1
        t, _ = rep_test(kind, cell, ids, idx[kind])
        rep_tests.append(t)

EXTRA_GRAPHS = ["U: nx(karate_club)", "U: [e, d, c, b, a] a-b, b-c, c-a, c-d, d-e, e-c", "U: [0] 0-0, 1-1, 1-2",
                "U: 0-1, 1-2, 2-0, 0-1, 2-2", "U: S(0;1..5), C(1..5)", "U: KB(0..2;3..5)", "U: K(4), 3-4, 4-5, 5-6, 6-4"]
for kind in ("plain", "vertexIndexed", "reversed"):
    for i, cell in enumerate(EXTRA_GRAPHS, 1):
        t, _ = extra_test(kind, cell, GRAPH_IDS[cell], i)
        rep_tests.append(t)

# Collider vertices: CQ-121's karate club and CQ-122, every vertex hashing to 0 or 1.
for i, cell in enumerate(["U: nx(karate_club)", "U: K(0..3), K(3..6), 0-6"], 1):
    g = ref.parse_graph(cell)
    labels = g.vertices
    ind = "        "
    v = values(g.simple())
    items = [f"({a}, {b})" for a, b in [(labels[x], labels[y]) for x, y in g.ends]]
    L = [f"// {cell}, each vertex v as Collider(v, hash: v % 2)",
         f"let pairs: [(Int, Int)] = {wrap_items(items, ind)}",
         "let c = { (v: Int) in Collider(v, hash: v % 2) }",
         f"let graph = UndirectedAdjacencyList(vertices: (0 ..< {len(labels)}).map(c), edges: pairs.map {{ UndirectedEdge(c($0.0), c($0.1)) }})",
         f"let expectedCliques: [[Collider]] = {wrap_items([vlist(c) for c in [[labels[i] for i in cl] for cl in v['cliques']]], ind)}.map {{ $0.map(c) }}",
         "let cliques = Array(graph.maximalCliques())",
         "#expect(Set(cliques) == Set(expectedCliques))",
         "#expect(cliques.count == expectedCliques.count)",
         f"#expect(graph.maximumClique() == {vlist([labels[i] for i in v['maximum']])}.map(c))",
         f"#expect(graph.cliqueNumber() == {v['omega']})",
         "let cores = graph.coreNumbers()",
         f"let expectedCores: [Int] = {wrap_items([str(x) for x in v['core']], ind)}",
         "let coresByVertex = graph.vertices.map { cores.coreNumber(of: $0) }",
         "#expect(coresByVertex == expectedCores)",
         f"#expect(cores.degeneracyOrdering == {wrap_items([str(labels[x]) for x in v['order']], ind)}.map(c))",
         "let values = graph.clusteringCoefficients()",
         f"let expectedTriangles: [Int] = {wrap_items([str(x) for x in v['tri']], ind)}",
         "let trianglesByVertex = graph.vertices.map { values.triangleCount(of: $0) }",
         "#expect(trianglesByVertex == expectedTriangles)",
         "let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }",
         "#expect(trianglesOneByOne == expectedTriangles)",
         f"let expectedClustering: [Double] = {wrap_items([repr(x) for x in v['cc']], ind)}",
         "let clusteringByVertex = graph.vertices.map { values.clusteringCoefficient(of: $0) }",
         "#expect(clusteringByVertex == expectedClustering)",
         f"#expect(graph.transitivity() == {repr(v['transitivity'])})",
         f"#expect(graph.averageClustering() == {repr(v['average'])})"]
    body = []
    for l in L:
        for sub in l.split("\n"):
            body.append(sub if sub.startswith(ind) else ind + sub)
    ids = GRAPH_IDS[cell]
    rep_tests.append("\n".join([f'    @Test("{ids_label(ids)} with Collider vertices on UndirectedAdjacencyList: {esc(cell)}")',
                                f"    func colliderVertices{i:02d}() {{"] + body + ["    }"]))

src = REP_HEADER + "\n\n" + "\n".join(f"import {m}" for m in [
    "AdjacencyListModule", "AdjacencyMatrixModule", "Cliques", "CompressedSparseRowModule", "GrafluentTestSupport",
    "GraphProtocols", "Testing"]) + "\n" + REP_CONFORMERS + REVERSED_CONFORMER.replace("\n    init(edges: [UndirectedEdge<Vertex>]) {\n        self.init(vertices: [], edges: edges)\n    }\n", "") + \
    '\n@Suite("Cliques on every representation")\nstruct CliqueRepresentationTests {\n' + "\n\n".join(rep_tests) + "\n}\n"
(OUT / "CliqueRepresentationTests.swift").write_text(src)
counts["CliqueRepresentationTests.swift"] = len(rep_tests)

for k, v in counts.items():
    print(k, v)
