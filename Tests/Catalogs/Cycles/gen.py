"""Generate the catalog-row tests (sections A-G) of Tests/CyclesTests from cases.md, with every
expected value recomputed by ref.py and required to equal the catalog cell, and then
CycleRepresentationTests.swift (asm_rep.py).

Run (from the repository root; OUTDIR defaults to Tests/CyclesTests):
    uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/Cycles/gen.py [OUTDIR]
"""

import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ref  # noqa: E402

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE.parent.parent / "CyclesTests"
ROW = re.compile(r"^\| (CY-\d+) \|(.*)\|\s*$")

SECTIONS = {
    "A": (1, 49), "B": (100, 149), "C": (200, 269), "D": (300, 349), "E": (400, 439),
    "F": (450, 499), "G": (500, 549),
}


def rows():
    text = (Path(ref.HERE) / "cases.md").read_text()
    for line in text.splitlines():
        m = ROW.match(line)
        if not m:
            continue
        cells = [c.strip() for c in m.group(2).split("|")]
        if len(cells) < 4 or not cells[1].startswith("`"):
            continue
        yield m.group(1), cells[0], cells[1].strip("`"), cells[2].strip("`"), cells[3].strip("`"), (cells[4] if len(cells) > 4 else "")


def lit(v, as_string):
    if as_string:
        return '"%s"' % v
    return str(v)


def is_range(vs):
    return all(isinstance(v, int) for v in vs) and len(vs) >= 3 and vs == list(range(vs[0], vs[0] + len(vs)))


def vlist(vs, as_string):
    if not as_string and is_range(vs):
        return "%d ... %d" % (vs[0], vs[-1])
    return "[" + ", ".join(lit(v, as_string) for v in vs) + "]"


def wrap(items, indent, width=104):
    """Comma-separated items wrapped onto lines of at most `width` columns."""
    lines, cur = [], ""
    for it in items:
        piece = it + ", "
        if cur and len(indent) + len(cur) + len(piece) > width:
            lines.append(indent + cur.rstrip())
            cur = ""
        cur += piece
    if cur:
        lines.append(indent + cur.rstrip().rstrip(","))
    if lines:
        lines[-1] = lines[-1].rstrip(",")
    return lines


def first_appearance(edges):
    out = []
    for e in edges:
        for x in e:
            if x not in out:
                out.append(x)
    return out


SINGLE = re.compile(r"^(K|DK|DKL|TT)\((\d+)\)$")


def graph_code(spec, g, as_string, ind):
    """Lines building `graph` exactly as the catalog writes it."""
    reorder = None
    mo = re.search(r"\s*~(rev|rot)$", spec)
    core = spec
    if mo:
        reorder = mo.group(1)
        core = spec[:mo.start()]
    core = core[2:].strip() if core.startswith("D:") else core.strip()
    T = "String" if as_string else "Int"
    edge = "DirectedEdge(from: $0.0, to: $0.1)" if g.directed else "UndirectedEdge($0.0, $0.1)"
    lines = []
    m = SINGLE.match(core)
    if m and reorder is None and int(m.group(2)) >= 5:
        f, n = m.group(1), int(m.group(2))
        lines.append(ind + "// %s: %s" % (core, {
            "K": "every pair u < v, lexicographic",
            "DK": "every arc a>b, a != b, row-major",
            "DKL": "every arc a>b including loops, row-major",
            "TT": "every arc x>y for y < x, row-major"}[f]))
        lines.append(ind + "let n = %d" % n)
        lines.append(ind + "var pairs: [(Int, Int)] = []")
        if f == "K":
            lines.append(ind + "for u in 0 ..< n { for v in u + 1 ..< n { pairs.append((u, v)) } }")
        elif f == "DK":
            lines.append(ind + "for a in 0 ..< n { for b in 0 ..< n where a != b { pairs.append((a, b)) } }")
        elif f == "DKL":
            lines.append(ind + "for a in 0 ..< n { for b in 0 ..< n { pairs.append((a, b)) } }")
        else:
            lines.append(ind + "for x in 0 ..< n { for y in 0 ..< x { pairs.append((x, y)) } }")
        typ = "ReferenceDirectedMultigraph" if g.directed else "ReferencePseudograph"
        lines.append(ind + "let graph = %s(vertices: 0 ..< n, edges: pairs.map { %s })" % (typ, edge))
        # sanity: same as the parser
        assert g.vertices == list(range(n))
        return lines
    lines.append(ind + "// " + spec)
    pairs = ["(%s, %s)" % (lit(a, as_string), lit(b, as_string)) for a, b in g.edges]
    vs = [str(v) if as_string else v for v in g.vertices]
    need_vertices = first_appearance([(str(a), str(b)) if as_string else (a, b) for a, b in g.edges]) != vs
    if reorder:
        typ = "ReorderedDirectedMultigraph" if g.directed else "ReorderedPseudograph"
    else:
        typ = "ReferenceDirectedMultigraph" if g.directed else "ReferencePseudograph"
    if not g.edges:
        generic = "%s<%s>" % (typ, T)
        if need_vertices:
            lines.append(ind + "let graph = %s(vertices: %s, edges: [])" % (generic, vlist(vs, as_string)))
        else:
            lines.append(ind + "let graph = %s(edges: [])" % generic)
        return lines
    one = "let pairs: [(%s, %s)] = [%s]" % (T, T, ", ".join(pairs))
    if len(ind) + len(one) <= 110:
        lines.append(ind + one)
    else:
        lines.append(ind + "let pairs: [(%s, %s)] = [" % (T, T))
        lines += wrap(pairs, ind + "    ")
        lines.append(ind + "]")
    args = []
    if need_vertices or reorder:
        args.append("vertices: %s" % vlist(vs, as_string))
    args.append("edges: pairs.map { %s }" % edge)
    if reorder:
        args.append("rows: .%s" % {"rev": "reversed", "rot": "rotated"}[reorder])
    lines.append(ind + "let graph = %s(%s)" % (typ, ", ".join(args)))
    return lines


def cycles_code(name, cs, g, as_string, ind):
    T = "String" if as_string else "Int"
    vrows = ["[" + ", ".join(lit(str(g.vertices[v]) if as_string else g.vertices[v], as_string) for v in c[0]) + "]" for c in cs]
    erows = ["[" + ", ".join(str(e) for e in c[1]) + "]" for c in cs]
    lines = []
    for label, typ, items in (("Vertices", T, vrows), ("Edges", "Int", erows)):
        one = "let expected%s: [[%s]] = [%s]" % (label, typ, ", ".join(items))
        if len(ind) + len(one) <= 110:
            lines.append(ind + one)
        else:
            lines.append(ind + "let expected%s: [[%s]] = [" % (label, typ))
            lines += wrap(items, ind + "    ")
            lines.append(ind + "]")
    lines.append(ind + "#expect(%s.map(\\.vertices) == expectedVertices)" % name)
    lines.append(ind + "#expect(%s.map(\\.edges) == expectedEdges)" % name)
    return lines


def cycle_code(expr, c, g, as_string, ind):
    vs = "[" + ", ".join(lit(str(g.vertices[v]) if as_string else g.vertices[v], as_string) for v in c[0]) + "]"
    es = "[" + ", ".join(str(e) for e in c[1]) + "]"
    return [ind + "let cycle = try #require(%s)" % expr,
            ind + "#expect(cycle.vertices == %s)" % vs,
            ind + "#expect(cycle.edges == %s)" % es]


def short(v):
    return v if len(v) <= 48 else None


def claim_for(op, value, g, as_string):
    base = re.sub(r"\(from:.*\)", "(from:)", op)
    if op == "isAcyclic":
        return "isAcyclic is %s" % ("true" if value == "T" else "false")
    if op.startswith("findCycle"):
        return "%s is %s" % ("findCycle()" if op == "findCycle" else base, "nil" if value == "nil" else (short(value) or "a %d-cycle" % value.split("/")[0].count(",")))
    if op == "cycleBasis":
        k = 0 if value == "none" else value.count(";") + 1
        return "cycleBasis() is empty" if k == 0 else ("cycleBasis() is %s" % value if k == 1 and short(value) else "cycleBasis() has %d cycles" % k)
    if op == "basisCount":
        return "cycleBasis() has %s cycles" % value[1:]
    if op.startswith("simpleCycles"):
        call = op if "(" in op else "simpleCycles()"
        k = 0 if value == "none" else value.count(";") + 1
        if k == 0:
            return "%s is empty" % call
        if k == 1 and short(value):
            return "%s is %s" % (call, value)
        return "%s: %d cycles in order" % (call, k)
    if op.startswith("count"):
        call = "simpleCycles(" + op[len("count("):] if "(" in op else "simpleCycles()"
        return "%s emits %s" % (call, value[1:])
    if op.startswith("directedCount"):
        call = "directed.simpleCycles(" + op[len("directedCount("):] if "(" in op else "directed.simpleCycles()"
        return "%s emits %s" % (call, value[1:])
    if op == "girth":
        return "girth() is %s" % value
    raise ValueError(op)


def swift_string(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def clean(s):
    s = s.replace("`", "")
    s = re.sub(r"\s+", " ", s).strip()
    return s


def test_for(cid, src, spec, op, expected, note):
    g = ref.parse(spec)
    as_string = not all(isinstance(v, int) for v in g.vertices)
    value = ref.compute(g, op)
    assert value == expected, (cid, value, expected)
    num = cid.split("-")[1]
    ind = "        "
    body = graph_code(spec, g, as_string, ind)
    throws = False
    m_bound = re.search(r"maxLength:\s*(\d+)", op)
    L = int(m_bound.group(1)) if m_bound else None
    if op == "isAcyclic":
        fname = "isAcyclic"
        body.append(ind + ("#expect(graph.isAcyclic)" if value == "T" else "#expect(!graph.isAcyclic)"))
    elif op == "findCycle" or op.startswith("findCycle(from:"):
        if op == "findCycle":
            fname, call, roots = "findCycle", "graph.findCycle()", None
        else:
            fname = "findCycleFromRoots"
            inner = re.fullmatch(r"findCycle\(from:\s*\[([^\]]*)\]\)", op).group(1)
            rs = [ref._atom(x.strip()) for x in inner.split(",") if x.strip()]
            call = "graph.findCycle(from: [%s])" % ", ".join(lit(str(r) if as_string else r, as_string) for r in rs)
            roots = [g.num[r] for r in rs]
        c = ref.find_cycle(g, roots)
        if c is None:
            body.append(ind + "#expect(%s == nil)" % call)
        else:
            throws = True
            body += cycle_code(call, c, g, as_string, ind)
    elif op == "cycleBasis":
        fname = "cycleBasis"
        b = ref.cycle_basis(g)
        body.append(ind + "let basis = graph.cycleBasis()")
        if not b:
            body.append(ind + "#expect(basis.isEmpty)")
        else:
            body += cycles_code("basis", b, g, as_string, ind)
    elif op == "basisCount":
        fname = "basisCount"
        body.append(ind + "#expect(graph.cycleBasis().count == %d)" % len(ref.cycle_basis(g)))
    elif op.startswith("simpleCycles"):
        fname = "simpleCycles" if L is None else "boundedSimpleCycles"
        cs = ref.brute_cycles(g, L)
        call = "graph.simpleCycles()" if L is None else "graph.simpleCycles(maxLength: %d)" % L
        if not cs:
            body.append(ind + "#expect(Array(%s).isEmpty)" % call)
        else:
            body.append(ind + "let cycles = Array(%s)" % call)
            body += cycles_code("cycles", cs, g, as_string, ind)
    elif op.startswith("count"):
        fname = "count" if L is None else "boundedCount"
        k = len(ref.brute_cycles(g, L))
        call = "graph.simpleCycles()" if L is None else "graph.simpleCycles(maxLength: %d)" % L
        body.append(ind + "#expect(Array(%s).count == %d)" % (call, k))
    elif op.startswith("directedCount"):
        fname = "directedViewCount"
        k = len(ref.brute_cycles(g.directed_view(), L))
        call = "graph.directed.simpleCycles()" if L is None else "graph.directed.simpleCycles(maxLength: %d)" % L
        body.append(ind + "#expect(Array(%s).count == %d)" % (call, k))
    elif op == "girth":
        fname = "girth"
        v = ref.girth_edges(g)
        assert v == ref.girth_bfs(g)
        body.append(ind + "#expect(graph.girth() == %s)" % ("nil" if v is None else v))
    else:
        raise ValueError(op)
    claim = claim_for(op, value, g, as_string)
    origin = clean(src) or clean(note)
    title = "%s %s" % (cid, claim) + (": " + origin if origin else "")
    notel = clean(note) if clean(note) and clean(note) != origin else None
    out = ["    @Test(\"%s\")" % swift_string(title),
           "    func %s%s()%s {" % (fname, num, " throws" if throws else "")]
    if notel:
        out.append(ind + "// " + notel)
    out += body
    out.append("    }")
    return "\n".join(out)


def generate(section):
    lo, hi = SECTIONS[section]
    tests = []
    for cid, src, spec, op, expected, note in rows():
        n = int(cid.split("-")[1])
        if not (lo <= n <= hi):
            continue
        if 150 <= n <= 156:
            continue  # deferred (phase 2)
        tests.append(test_for(cid, src, spec, op, expected, note))
    return tests


if __name__ == "__main__" and False:
    for s in sys.argv[1:]:
        print("\n\n".join(generate(s)))


UNDIRECTED_REORDERED = '''
/// An undirected pseudograph whose incidence rows are not in position order, as on an
/// `UndirectedAdjacencyList` after removals: each row is built in position order (a self-loop
/// twice), then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex and edge
/// indices are positions.
private struct ReorderedPseudograph<Vertex: Hashable>: Graph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [UndirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferencePseudograph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.incidentEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
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

DIRECTED_REORDERED = '''
/// A directed multigraph whose out-edge rows are not in position order: each row is built in
/// position order, then reversed or rotated left by one (the catalog's `~rev` and `~rot`). Vertex
/// indices are positions.
private struct ReorderedDirectedMultigraph<Vertex: Hashable>: DirectedGraph {
    enum Reordering { case reversed, rotated }

    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    private let index: [Vertex: Int]
    private let rows: [[Int]]

    init(vertices listed: some Sequence<Vertex>, edges: [DirectedEdge<Vertex>], rows reordering: Reordering) {
        let inOrder = ReferenceDirectedMultigraph(vertices: listed, edges: edges)
        var index: [Vertex: Int] = [:]
        for (i, v) in inOrder.vertices.enumerated() { index[v] = i }
        self.vertices = inOrder.vertices
        self.edges = edges
        self.index = index
        self.rows = inOrder.vertices.map { v in
            let row = inOrder.outEdges(of: v)
            switch reordering {
            case .reversed: return Array(row.reversed())
            case .rotated: return row.isEmpty ? row : Array(row.dropFirst()) + [row[0]]
            }
        }
    }

    func outEdges(of vertex: Vertex) -> [Int] { rows[index[vertex]!] }
    func successors(of vertex: Vertex) -> [Vertex] { outEdges(of: vertex).map { edges[$0].target } }
    func contains(_ vertex: Vertex) -> Bool { index[vertex] != nil }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Vertex) -> Int { index[vertex]! }
    func vertex(atIndex i: Int) -> Vertex { vertices[i] }
}
'''

FILES = {
    "A": ("UndirectedCycleDetectionTests", "Undirected cycle detection",
          "// §A: undirected cycle detection. `isAcyclic` (a self-loop and a parallel pair are cycles, one\n"
          "// edge is not), `findCycle()` (the cycle closed by the first edge of a depth-first search, roots\n"
          "// in `vertices` order, rows in incidence order, skipping the edge it arrived by, returned in\n"
          "// canonical form) and `findCycle(from:)` (only the roots' components, roots in order). Every graph\n"
          "// is written as the catalog writes it, on the `ReferencePseudograph` (listed vertices first, then\n"
          "// endpoints by first appearance; edges in written order, repeats and loops kept), so positions\n"
          "// are exact. Expected values come from the catalog's reference (`ref.py`). Case IDs (CY-nnn)\n"
          "// refer to the catalog; see README.md."),
    "B": ("CycleBasisTests", "Cycle basis",
          "// §B: `cycleBasis()`, the fundamental cycles of the breadth-first spanning forest (roots in\n"
          "// `vertices` order, rows in incidence order): one cycle per non-tree edge, loops and parallel\n"
          "// copies included, in ascending position of that edge, each in canonical form. Every graph is\n"
          "// written as the catalog writes it, on the `ReferencePseudograph`, so positions are exact.\n"
          "// Expected values come from the catalog's reference (`ref.py`). The minimum cycle basis rows\n"
          "// (CY-150 – CY-156) are phase 2 and not tested here. Case IDs (CY-nnn) refer to the catalog;\n"
          "// see README.md."),
    "C": ("DirectedSimpleCycleTests", "Directed simple cycles",
          "// §C: `DirectedGraph.simpleCycles()`: every elementary circuit once, starting at its least vertex\n"
          "// (in `vertices` order), emitted by least vertex and then lexicographically by each arc's offset\n"
          "// in its vertex's `outEdges` row. Parallel arcs give one cycle per copy. Graphs from NetworkX,\n"
          "// rustworkx, JGraphT, igraph and Boost, written as the catalog writes them on the\n"
          "// `ReferenceDirectedMultigraph`, so positions are exact. Expected values come from the catalog's\n"
          "// reference (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md."),
    "D": ("UndirectedSimpleCycleTests", "Undirected simple cycles",
          "// §D: `Graph.simpleCycles()`: every simple cycle once, in canonical form (its least vertex first,\n"
          "// leaving it through the lesser of its two edges there, by position), emitted by least vertex and\n"
          "// then lexicographically by each edge's offset in its vertex's `incidentEdges` row. Graphs from\n"
          "// NetworkX, igraph and Boost and the classic families, written as the catalog writes them on the\n"
          "// `ReferencePseudograph`, so positions are exact. Expected values come from the catalog's\n"
          "// reference (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md."),
    "E": ("CycleMultigraphTests", "Cycles of multigraphs and self-loops",
          "// §E: parallel edges and self-loops. A loop is one 1-cycle per loop edge (though an undirected row\n"
          "// lists it twice), k parallel undirected edges give C(k, 2) 2-cycles, one undirected edge is no\n"
          "// cycle, opposite arcs are one 2-cycle, and parallel arcs give one cycle per copy; `g.directed`\n"
          "// reads every edge as two arcs (Boost's undirected count). Graphs written as the catalog writes\n"
          "// them on the reference conformers, so positions are exact. Expected values come from the\n"
          "// catalog's reference (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md."),
    "F": ("CycleLengthBoundTests", "Simple cycles with a length bound",
          "// §F: `simpleCycles(maxLength:)`, directed and undirected. The bound counts edges: 0 gives\n"
          "// nothing, 1 the loops, 2 adds 2-cycles; the result is the unbounded sequence filtered to\n"
          "// `length <= maxLength`, in the same order. Cases from NetworkX, igraph, Boost (`max_length`) and\n"
          "// JGraphT (`setPathLimit`), plus the planted bounded-search mistake CY-491. Graphs written as the\n"
          "// catalog writes them, so positions are exact. Expected values come from the catalog's reference\n"
          "// (`ref.py`). Case IDs (CY-nnn) refer to the catalog; see README.md."),
    "G": ("GirthTests", "Girth",
          "// §G: `girth()` on `Graph` and `DirectedGraph`: the least length of a cycle, so 1 with a loop and\n"
          "// 2 with a parallel pair (undirected) or opposite arcs (directed); `nil` when acyclic, where\n"
          "// NetworkX and igraph return inf, JGraphT Integer.MAX_VALUE and Boost 0. Named graphs from\n"
          "// NetworkX (edges in NetworkX's order), JGraphT's GraphMetricsTest, igraph and Boost. Expected\n"
          "// values come from the catalog's reference (`ref.py`), two independent computations. Case IDs\n"
          "// (CY-nnn) refer to the catalog; see README.md."),
}


def write_files():
    counts = {}
    for sec, (fname, suite, header) in FILES.items():
        tests = generate(sec)
        text = "\n\n".join(tests)
        conformers = ""
        if "ReorderedPseudograph(" in text:
            conformers += UNDIRECTED_REORDERED
        if "ReorderedDirectedMultigraph(" in text:
            conformers += DIRECTED_REORDERED
        src = (header + "\n\nimport Cycles\nimport GraphProtocols\nimport GrafluentTestSupport\nimport Testing\n"
               + conformers
               + "\n@Suite(\"%s\")\nstruct %s {\n" % (suite, fname) + text + "\n}\n")
        (OUT / (fname + ".swift")).write_text(src)
        counts[fname] = len(tests)
    print(counts)
if __name__ == "__main__":
    write_files()
    import asm_rep
    asm_rep.write(OUT)
