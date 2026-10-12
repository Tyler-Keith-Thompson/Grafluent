"""Writes the catalog-row test files of Tests/ImplicitGraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/ImplicitGraphs/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/ImplicitGraphsTests

First checks that ref.py's model reproduces cases.md byte for byte. Every row's calls are evaluated
once on the model (ref.py's port of the type, which counts closure calls, checked against the
DirectedGraph laws and NetworkX); the generator asserts that each value, formatted, is the catalog
cell, and writes one @Test per row. The test counts calls in its own closure, so `calls()` is
public behavior. A row over a graph then writes out the whole state from the model, with the calls
each read makes: the edge count and the edges iterated (one call per vertex), every row by vertex
and by index with its positions (one call each), the edges stepped by `index(after:)`, which must
equal iteration, every position's ends, and `contains(edge:)` for every edge. A trap row runs its
call in a child process (an exit test), then the same setup without the fault in this process.
Hand-written exit tests spliced into the precondition file: extra_traps.swift.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "ImplicitGraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and every row's calls with their values on the model
# ---------------------------------------------------------------------------------------------
RECORD = {}      # row number -> (input text, [(call text, value or Trap)])
GRAPH = {}       # row number -> (closure name, n, Python closure)
_row, _graph_row = ref.row, ref.graph_row
_current = [None]


def _rec_row(group, title, input_text, thunks):
    n = len(ref.ROWS) + 1
    done, memo = [], []
    for text, fn in thunks:
        try:
            v = fn()
        except ref.Trap as t:
            done.append((text, t))
            memo.append((text, (lambda t: lambda: (_ for _ in ()).throw(t))(t)))
            break
        done.append((text, v))
        memo.append((text, (lambda v: lambda: v)(v)))
    RECORD[n] = (input_text, done)
    if _current[0] is not None:
        GRAPH[n] = _current[0]
    _row(group, title, input_text, memo)


def _rec_graph_row(group, title, name, n_vertices, fn, calls, checked=True):
    n = len(ref.ROWS) + 1
    _current[0] = (name, n_vertices, fn)
    try:
        _graph_row(group, title, name, n_vertices, fn, calls, checked)
    finally:
        _current[0] = None
    assert n in RECORD


ref.row, ref.graph_row = _rec_row, _rec_graph_row
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| IG-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 46 and sorted(RECORD) == list(range(1, N + 1))


def group(n): return CELLS[n][1]
def title(n): return CELLS[n][2]
def inp(n): return CELLS[n][3]
def cell(n): return CELLS[n][4]
def is_trap(n): return "**trap**" in cell(n)


for n in range(1, N + 1):
    shown = ["**trap** (%s)" % v if isinstance(v, ref.Trap) else ref.fmt(v) for _, v in RECORD[n][1]]
    assert "; ".join(shown) == cell(n), (n, shown, cell(n))

# ---------------------------------------------------------------------------------------------
# Swift literals and the graphs
# ---------------------------------------------------------------------------------------------


def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]" if xs else "[] as [Int]"
def int_rows(rs): return "[" + ", ".join(ints(r) for r in rs) + "]" if rs else "[] as [[Int]]"
def opts(xs): return "[" + ", ".join("nil" if x is None else str(x) for x in xs) + "] as [Int?]"
def pos(p): return ints(list(p))


# The catalog's named closures, spelled in Swift with a call counter. The grid returns a lazy
# filter, so the generic row type is exercised with something other than an Array.
CLOSURES = {
    "ring5": ("[Int]", ["return [(v + 1) % 5]"]),
    "diamond": ("[Int]", ["return [[1, 2], [3], [3], []][v]"]),
    "parallel": ("[Int]", ["return [[1, 1, 0], []][v]"]),
    "twoCycles": ("[Int]", ["return [[1], [0, 2], [3], [2], []][v]"]),
    "grid": ("LazyFilterSequence<[Int]>", [
        "// 4 × 3 cells r * 4 + c, walls at 5 and 6; up, left, right, down.",
        "let walls: Set<Int> = [5, 6]",
        "let (r, c) = (v / 4, v % 4)",
        "let up = r > 0 ? v - 4 : -1, left = c > 0 ? v - 1 : -1, right = c < 3 ? v + 1 : -1, down = r < 2 ? v + 4 : -1",
        "return [up, left, right, down].lazy.filter { $0 >= 0 && !walls.contains($0) && !walls.contains(v) }"]),
    "{ _ in [] }": ("[Int]", ["return []"]),
    "{ _ in [0, 2] }": ("[Int]", ["return [0, 2]"]),
    "{ _ in [-1] }": ("[Int]", ["return [-1]"]),
}


def parse_name(name):
    m = re.fullmatch(r"\((\d+), (.*)\)", name)
    return int(m.group(1)), m.group(2)


def construct(n, cname, ind="        ", var="graph", counter="calls"):
    row_type, body = CLOSURES[cname]
    lines = ["let %s = ImplicitDirectedGraph(vertexCount: %d, successors: { (v: Int) -> %s in" % (var, n, row_type),
             "    %s += 1" % counter]
    lines += ["    " + b for b in body]
    lines.append("})")
    return [ind + l for l in lines]


def state(n, fn, ind="        ", var="graph"):
    """The whole graph from the model, with the closure calls each read makes."""
    g = ref.IG(n, fn)
    ref.check(ref.IG(n, fn))
    rows = [g.successors(v) for v in range(n)]
    oe = [g.out_edges(v) for v in range(n)]
    E = g.edges()
    out = ["// The whole graph, from the model, with the closure calls each read makes.",
           "calls = 0",
           "#expect(%s.vertexCount == %d && %s.vertexIndexBound == %d && %s.edgeIndexBound == nil)" % (var, n, var, n, var),
           "#expect(Array(%s.vertices) == %s && !%s.contains(-1) && !%s.contains(%d))" % (var, ints(list(range(n))), var, var, n),
           "#expect(%s.edgeCount == %d)" % (var, len(E)),
           "#expect(calls == %d)" % n,
           "calls = 0",
           "var iterated: [[Int]] = []",
           "for edge in %s.edges { iterated.append([edge.source, edge.target]) }" % var,
           "#expect(iterated == %s)" % int_rows([[s, t] for s, _, t in E]),
           "#expect(calls == %d)" % n,
           "calls = 0",
           "#expect(%s.vertices.map { Array(%s.successors(of: $0)) } == %s)" % (var, var, int_rows(rows)),
           "#expect(calls == %d)" % n,
           "#expect(%s.vertices.map { Array(%s.successorIndices(ofIndex: $0)) } == %s)" % (var, var, int_rows(rows)),
           "#expect(%s.vertices.map { %s.outDegree(of: $0) } == %s)" % (var, var, ints([len(r) for r in rows])),
           "#expect(%s.vertices.map { %s.outDegree(ofIndex: $0) } == %s)" % (var, var, ints([len(r) for r in rows])),
           "#expect(%s.vertices.map { [%s.vertexIndex(of: $0), %s.vertex(atIndex: $0)] } == %s)" % (var, var, var, int_rows([[v, v] for v in range(n)])),
           "calls = 0",
           "let positions = %s.vertices.flatMap { Array(%s.outEdges(of: $0)) }" % (var, var),
           "#expect(calls == %d)" % n,
           "#expect(positions.map { [$0.source, $0.rank, $0.target] } == %s)" % int_rows([list(p) for p in E]),
           "#expect(%s.vertices.flatMap { Array(%s.outEdges(ofIndex: $0)) } == positions)" % (var, var),
           "calls = 0",
           "#expect(positions.map { [%s.source(ofEdgeAt: $0), %s.target(ofEdgeAt: $0)] } == positions.map { [$0.source, $0.target] })" % (var, var),
           "#expect(positions.map { %s.edges[$0] } == positions.map { DirectedEdge(from: $0.source, to: $0.target) })" % var,
           "#expect(calls == 0)",
           "// Stepping by index(after:) visits the positions iteration lists, in order.",
           "var stepped: [ImplicitDirectedGraph<%s>.Edges.Index] = []" % ROW_TYPE[0],
           "var position = %s.edges.startIndex" % var,
           "while position != %s.edges.endIndex {" % var,
           "    stepped.append(position)",
           "    position = %s.edges.index(after: position)" % var,
           "}",
           "#expect(stepped == positions && stepped.map(\\.target) == positions.map(\\.target))",
           "#expect(Set(positions).count == %d && positions == positions.sorted())" % len(E)]
    if E:
        out += ["calls = 0",
                "#expect(positions.allSatisfy { %s.contains(edge: DirectedEdge(from: $0.source, to: $0.target)) })" % var,
                "#expect(calls == %d)" % len(E)]
    return [ind + l for l in out]


ROW_TYPE = ["[Int]"]

# ---------------------------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------------------------
POS = re.compile(r"(\d+)\.(\d+)→(\d+)")


def pos_var(p): return "p%d%d" % (p[0], p[1])


def call_lines(n, text, v):
    """The Swift lines checking `text` (a catalog call) returns the model's value v."""
    if text == "calls()":
        return ["#expect(calls == %d)" % v, "calls = 0"]
    m = re.fullmatch(r"(successors|outEdges|outDegree|vertexIndex)\(checked: (-?\d+)\)", text)
    if m:
        if v is ref.THROWS:
            return ["#expect(throws: VertexNotFound.self) { try graph.%s }" % text,
                    "#expect((try? graph.%s) == nil)" % text]
        if m.group(1) == "successors":
            return ["#expect(try Array(graph.%s) == %s)" % (text, ints(v))]
        if m.group(1) == "outEdges":
            return ["#expect(try Array(graph.%s).map { [$0.source, $0.rank, $0.target] } == %s)" % (text, int_rows([list(p) for p in v]))]
        return ["#expect(try graph.%s == %d)" % (text, v)]
    if text in ("vertexCount", "vertexIndexBound", "edgeIndexBound", "edgeCount"):
        return ["#expect(graph.%s == %s)" % (text, "nil" if v is None else v)]
    if text == "edges.isEmpty":
        return ["#expect(graph.edges.isEmpty == %s)" % ("true" if v else "false")]
    if text == "edges.first":
        assert v is None
        return ["#expect(graph.edges.first == nil)"]
    if text == "vertices":
        return ["#expect(Array(graph.vertices) == %s)" % ints(v)]
    if text == "Array(edges)":
        # One pass: Edges reports no count up front, so Array.init does not read `count` first.
        return ["#expect(Array(graph.edges).map { [$0.source, $0.target] } == %s)" % int_rows([[s, t] for s, _, t in v])]
    if text == "edges":
        return ["var listed: [[Int]] = []",
                "for edge in graph.edges { listed.append([edge.source, edge.target]) }",
                "#expect(listed == %s)" % int_rows([[s, t] for s, _, t in v])]
    m = re.fullmatch(r"successors\(of: (-?\d+)\)|successorIndices\(ofIndex: (\d+)\)", text)
    if m:
        return ["#expect(Array(graph.%s) == %s)" % (text, ints(v))]
    m = re.fullmatch(r"outEdges\(of: (\d+)\)", text)
    if m:
        return ["#expect(Array(graph.outEdges(of: %s)).map { [$0.source, $0.rank, $0.target] } == %s)" % (m.group(1), int_rows([list(p) for p in v]))]
    m = re.fullmatch(r"(outDegree|vertexIndex)\(of: (-?\d+)\)|vertex\(atIndex: (\d+)\)", text)
    if m:
        return ["#expect(graph.%s == %d)" % (text, v)]
    if text == "let p = outEdges(of: 0)[1]":
        return ["let p = Array(graph.outEdges(of: 0))[1]", "#expect([p.source, p.rank, p.target] == %s)" % pos(v)]
    m = re.fullmatch(r"(source|target)\(ofEdgeAt: p\)", text)
    if m:
        return ["#expect(graph.%s == %d)" % (text, v)]
    m = re.fullmatch(r"edges\.index\(after: (.*)\)", text)
    if m:
        p = tuple(map(int, POS.fullmatch(m.group(1)).groups()))
        if v == "endIndex":
            return ["#expect(graph.edges.index(after: %s) == graph.edges.endIndex)" % pos_var(p)]
        return ["let after%s = graph.edges.index(after: %s)" % (pos_var(p)[1:], pos_var(p)),
                "#expect([after%s.source, after%s.rank, after%s.target] == %s)" % (pos_var(p)[1:], pos_var(p)[1:], pos_var(p)[1:], pos(v))]
    m = re.fullmatch(r"contains\((-?\d+)\)", text)
    if m:
        return ["#expect(%sgraph.contains(%s))" % ("" if v else "!", m.group(1))]
    m = re.fullmatch(r"contains\(edge: (-?\d+)→(-?\d+)\)", text)
    if m:
        return ["#expect(%sgraph.contains(edge: DirectedEdge(from: %s, to: %s)))" % ("" if v else "!", m.group(1), m.group(2))]
    m = re.fullmatch(r"breadthFirstLayers\(from: (\d+)\)", text)
    if m:
        return ["#expect(graph.breadthFirstLayers(from: %s) == %s)" % (m.group(1), int_rows(v))]
    if text.startswith("shortestPaths(from: 0)"):
        return ["let hops = graph.shortestPaths(from: 0)", "#expect((0 ..< 12).map { hops.distance(to: $0) } == %s)" % opts(v)]
    if text.startswith("dijkstraShortestPaths"):
        return ["let tree = graph.dijkstraShortestPaths(from: 0, weight: { $0.target / 4 + 1 })",
                "#expect((0 ..< 12).map { tree.distance(to: $0) } == %s)" % opts(v),
                "// The paths cost what they say: each step into row r costs r + 1.",
                "for v in 0 ..< 12 {",
                "    if let path = tree.path(to: v) {",
                "        #expect(path.vertices.first == 0 && path.vertices.last == v)",
                "        #expect(path.vertices.dropFirst().reduce(0) { $0 + $1 / 4 + 1 } == tree.distance(to: v))",
                "        #expect(path.edges.map { [$0.source, $0.target] } == zip(path.vertices, path.vertices.dropFirst()).map { [$0, $1] })",
                "    }",
                "}"]
    if text in ("weaklyConnectedComponents()", "stronglyConnectedComponents()"):
        return ["#expect(Set(graph.%s.map { Set($0) }) == Set(%s.map { Set($0) }))" % (text, int_rows(v))]
    if text == "topologicalSort() is a topological order":
        assert v is True
        return ["let order = graph.topologicalSort()!",
                "#expect(order.sorted() == Array(graph.vertices))",
                "let place = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })",
                "#expect(graph.edges.allSatisfy { place[$0.source]! < place[$0.target]! })"]
    if text == "IG(5, twoCycles).topologicalSort()":
        assert v is None
        return construct(5, "twoCycles", ind="", var="cyclic", counter="otherCalls") + ["#expect(cyclic.topologicalSort() == nil)"]
    if text == "findCycle()!.count":
        return ["let cycle = graph.findCycle()!",
                "#expect(cycle.count == %d)" % v,
                "#expect(zip(cycle.vertices, cycle.vertices.dropFirst() + cycle.vertices.prefix(1)).allSatisfy { graph.contains(edge: DirectedEdge(from: $0, to: $1)) })"]
    raise ValueError((n, text))


def header(n, tags=()):
    return ['    @Test("IG-%03d %s"%s)' % (n, title(n), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


def graph_test(n):
    name, nv, fn = GRAPH[n]
    count, cname = parse_name(name)
    ROW_TYPE[0] = CLOSURES[cname][0]
    calls = RECORD[n][1]
    throws = any("(checked:" in t for t, _ in calls)
    lines = header(n) + ["    func ig%03d()%s {" % (n, " throws" if throws else ""), "        // %s → %s" % (inp(n), cell(n)), "        var calls = 0"]
    if any(t == "IG(5, twoCycles).topologicalSort()" for t, _ in calls):
        lines.append("        var otherCalls = 0")
    lines += construct(count, cname)
    # Positions passed as arguments are taken from outEdges(of:) first; the calls they make are reset.
    wanted = []
    for t, _ in calls:
        for p in POS.findall(t):
            p = tuple(map(int, p))
            if p not in wanted:
                wanted.append(p)
    if wanted:
        lines.append("        // The positions the calls take, read from outEdges(of:) before counting.")
        for p in wanted:
            lines.append("        let %s = Array(graph.outEdges(of: %d))[%d]" % (pos_var(p), p[0], p[1]))
            lines.append("        #expect([%s.source, %s.rank, %s.target] == %s)" % (pos_var(p), pos_var(p), pos_var(p), pos(p)))
        lines.append("        calls = 0")
    for t, v in calls:
        lines += ["        " + l for l in call_lines(n, t, v)]
    if "otherCalls" in "\n".join(lines):
        lines.append("        #expect(otherCalls > 0)")
    lines.append("        do {")
    lines += state(nv, fn, ind="            ")
    lines.append("        }")
    lines.append("    }")
    return lines


TRAPS = {
    3: (["_ = ImplicitDirectedGraph(vertexCount: -1, successors: { _ in [] as [Int] })"],
        ["// The nearest accepted input: no vertices.",
         "let graph = ImplicitDirectedGraph(vertexCount: 0, successors: { _ in [] as [Int] })",
         "#expect(graph.vertexCount == 0 && graph.edgeCount == 0 && graph.vertices.isEmpty)"]),
    14: (["_ = Array(graph.successors(of: 0))"],
         ["// Without reading past the good successor, nothing traps: the check is lazy.",
          "#expect(graph.successors(of: 0).first(where: { _ in true }) == 0)",
          "#expect(calls == 1)",
          "#expect(graph.vertexCount == 2 && graph.contains(1) && !graph.contains(2))"]),
    15: (["_ = graph.edgeCount"],
         ["// Without reading the row, nothing traps.",
          "_ = graph.successors(of: 0)",
          "#expect(calls == 1 && graph.vertexCount == 2)"]),
    39: (["_ = dijkstraShortestPath(from: 0, successors: { _ in [(1, -1)] }, success: { $0 == 1 })"],
         ["// Without the fault: a zero cost is allowed.",
          "#expect(dijkstraShortestPath(from: 0, successors: { _ in [(1, 0)] }, success: { $0 == 1 })?.distance == 0)"]),
    40: (["_ = dijkstraShortestPath(from: 0, cutoff: 0, successors: { _ in [(1, -1)] }, success: { $0 == 1 })"],
         ["// Without the fault: the cutoff drops a step of cost 1, and nothing else is reachable.",
          "#expect(dijkstraShortestPath(from: 0, cutoff: 0, successors: { _ in [(1, 1)] }, success: { $0 == 1 }) == nil)"]),
    41: (["_ = dijkstraShortestPath(from: 0, successors: { _ in [(1, Double.nan)] }, success: { $0 == 1 })"],
         ["// Without the fault: an infinite cost is a cost.",
          "#expect(dijkstraShortestPath(from: 0, successors: { _ in [(1, Double.infinity)] }, success: { $0 == 1 })?.distance == .infinity)"]),
    42: (["_ = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Double)] in v == 0 ? [(1, 1.0)] : [] }, heuristic: { $0 == 1 ? .nan : 0 }, success: { $0 == 1 })"],
         ["// Without the fault: a zero estimate.",
          "let result = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Double)] in v == 0 ? [(1, 1.0)] : [] }, heuristic: { _ in 0 }, success: { $0 == 1 })",
          "#expect(result?.distance == 1 && result?.path == [0, 1])"]),
    43: (["_ = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Double)] in v == 0 ? [(1, .infinity), (3, 5)] : [] }, heuristic: { $0 == 1 ? -.infinity : 0 }, success: { $0 == 1 || $0 == 3 })"],
         ["// Without the fault: with a finite estimate at 1, the nearer goal 3 is found. (Before the",
          "// check, the NaN priority broke the heap's order.)",
          "let result = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Double)] in v == 0 ? [(1, .infinity), (3, 5)] : [] }, heuristic: { _ in 0 }, success: { $0 == 1 || $0 == 3 })",
          "#expect(result?.distance == 5 && result?.path == [0, 3])"]),
    44: (["_ = dijkstraShortestPath(from: 0, cutoff: .nan, successors: { _ in [(1, 1.0)] }, success: { $0 == 1 })"],
         ["// Without the fault: an infinite cutoff drops nothing.",
          "#expect(dijkstraShortestPath(from: 0, cutoff: .infinity, successors: { _ in [(1, 1.0)] }, success: { $0 == 1 })?.distance == 1)"]),
}


def trap_test(n):
    lines = header(n) + ["    func ig%03d() async {" % n, "        // %s → %s" % (inp(n), cell(n))]
    if n in GRAPH:
        name, nv, fn = GRAPH[n]
        count, cname = parse_name(name)
        ROW_TYPE[0] = CLOSURES[cname][0]
        (ctext, trap), = RECORD[n][1]
        assert isinstance(trap, ref.Trap) and cell(n) == "**trap** (%s)" % trap
        child = TRAPS[n][0] if n in TRAPS else ["_ = graph.%s" % ctext]
        lines += ["        await #expect(processExitsWith: .failure) {", "            var calls = 0"]
        lines += construct(count, cname, ind="            ")
        lines += ["            " + c for c in child] + ["            _ = calls", "        }"]
        lines += ["        // Without the call: the setup, in this process.", "        var calls = 0"]
        lines += construct(count, cname)
        if n in TRAPS:
            lines += ["        " + l for l in TRAPS[n][1]]
        else:
            lines += state(nv, fn)
    else:
        child, near = TRAPS[n]
        lines += ["        await #expect(processExitsWith: .failure) {"] + ["            " + c for c in child] + ["        }"]
        lines += ["        " + l for l in near]
    lines.append("    }")
    return lines


# The closure rows: Traversal's existing search and ShortestPaths D19.
P_DECL = ["struct P: Hashable {", "    var x, y: Int", "}"]
GRID4 = "let grid4 = { (p: P) -> [P] in [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)] }"
KNIGHT1 = ["let knight1 = { (p: P) -> [(P, Int)] in",
           "    [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)].map { (P(x: p.x + $0.0, y: p.y + $0.1), 1) }",
           "}"]
COSTLY = ["// Entering (x, y) costs 1 + (x² + y) mod 3, the mod taken non-negative.",
          "let costly = { (p: P) -> [(P, Int)] in",
          "    [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)].map { q in",
          "        (q, 1 + ((q.x * q.x + q.y) % 3 + 3) % 3)",
          "    }",
          "}"]
TWO_ENDED = ["// A step from p to q costs 1 + (p.x · q.y) mod 3, the mod taken non-negative: the cost",
             "// depends on both ends, so the goal's first push is not its distance.",
             "let twoEnded = { (p: P) -> [(P, Int)] in",
             "    [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)].map { q in",
             "        (q, 1 + ((p.x * q.y) % 3 + 3) % 3)",
             "    }",
             "}"]


def path_checks(succ, start, goal, dist, count=None):
    """The path starts at start, ends at goal, steps along successors, and costs dist."""
    out = ["#expect(result?.distance == %s)" % dist]
    if count is not None:
        out.append("#expect(result?.path.count == %d)" % count)
    out += ["let path = result!.path",
            "#expect(path.first == %s && path.last == %s)" % (start, goal),
            "var cost = 0",
            "for (a, b) in zip(path, path.dropFirst()) {",
            "    let step = %s(a).first { $0.0 == b }" % succ,
            "    #expect(step != nil)",
            "    cost += step?.1 ?? 0",
            "}",
            "#expect(cost == %s)" % dist]
    return out


def closure_test(n):
    text, calls = RECORD[n]
    v = calls[-1][1]
    if n <= 31:
        (_, v), = calls
    lines = header(n) + ["    func ig%03d() {" % n, "        // %s → %s" % (inp(n), cell(n))]
    body = []
    if n == 23:
        body = P_DECL + [GRID4,
                         "var discovered: [P] = []",
                         "for event in breadthFirstSearch(from: [P(x: 0, y: 0)], depthLimit: 2, successors: grid4) {",
                         "    if case .discover(let p) = event { discovered.append(p) }",
                         "}",
                         "#expect(discovered.count == %d)" % v,
                         "#expect(Set(discovered) == Set((-2 ... 2).flatMap { x in (-2 ... 2).map { y in P(x: x, y: y) } }.filter { abs($0.x) + abs($0.y) <= 2 }))",
                         "#expect(discovered.first == P(x: 0, y: 0))"]
    elif n in (24, 25):
        d, c = map(int, re.fullmatch(r"\((\d+), (\d+)\)", v).groups())
        body = P_DECL + KNIGHT1
        if n == 24:
            body.append("let result = dijkstraShortestPath(from: P(x: 0, y: 0), successors: knight1, success: { $0 == P(x: 7, y: 7) })")
        else:
            body += ["// Admissible: a knight move changes one coordinate by at most 2 and the sum by at most 3.",
                     "let knightBound = { (p: P) -> Int in",
                     "    max((abs(7 - p.x) + 1) / 2, (abs(7 - p.y) + 1) / 2, (abs(7 - p.x) + abs(7 - p.y) + 2) / 3)",
                     "}",
                     "let result = aStarShortestPath(from: P(x: 0, y: 0), successors: knight1, heuristic: knightBound, success: { $0 == P(x: 7, y: 7) })"]
        body += path_checks("knight1", "P(x: 0, y: 0)", "P(x: 7, y: 7)", d, c)
    elif n in (26, 27):
        body = P_DECL + COSTLY
        if n == 26:
            body.append("let result = dijkstraShortestPath(from: P(x: 0, y: 0), successors: costly, success: { $0 == P(x: 4, y: -3) })")
        else:
            body += ["let manhattan = { (p: P) -> Int in abs(4 - p.x) + abs(-3 - p.y) }",
                     "let result = aStarShortestPath(from: P(x: 0, y: 0), successors: costly, heuristic: manhattan, success: { $0 == P(x: 4, y: -3) })"]
        body += path_checks("costly", "P(x: 0, y: 0)", "P(x: 4, y: -3)", int(v))
    elif n in (30, 31):
        body = P_DECL + TWO_ENDED
        if n == 30:
            body.append("let result = dijkstraShortestPath(from: P(x: 0, y: 0), successors: twoEnded, success: { $0 == P(x: -4, y: 4) })")
        else:
            body += ["let manhattan = { (p: P) -> Int in abs(-4 - p.x) + abs(4 - p.y) }",
                     "let result = aStarShortestPath(from: P(x: 0, y: 0), successors: twoEnded, heuristic: manhattan, success: { $0 == P(x: -4, y: 4) })"]
        body += path_checks("twoEnded", "P(x: 0, y: 0)", "P(x: -4, y: 4)", int(v))
    elif n == 28:
        body = ["var calls = 0",
                "let result = dijkstraShortestPath(from: 3, successors: { (v: Int) -> [(Int, Int)] in",
                "    calls += 1",
                "    return [(v + 1, 1)]",
                "}, success: { $0 == 3 })",
                "#expect(result?.distance == 0 && result?.path == [3])",
                "// The start is tested before it is expanded.",
                "#expect(calls == 0)"]
        assert v == "(0, 1)"
    elif n == 29:
        assert v is None
        body = ["var expanded: [Int] = []",
                "let result = dijkstraShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in",
                "    expanded.append(v)",
                "    return v < 10 ? [(v + 1, 1)] : []",
                "}, success: { $0 == 20 })",
                "#expect(result == nil)",
                "// Every reachable state is expanded once, nearest first.",
                "#expect(expanded == Array(0 ... 10))"]
    elif n in (32, 33):
        body = ["let line2 = { (v: Int) -> [(Int, Int)] in [(v + 1, 2)] }"]
        if n == 32:
            assert v == [0, 1, 2] and calls[0][1] == "(6, 4)" and calls[1][1] is None
            body += ["let result = dijkstraShortestPath(from: 0, cutoff: 6, successors: line2, success: { $0 == 3 })",
                     "// Inclusive: the goal at exactly the cutoff is found.",
                     "#expect(result?.distance == 6 && result?.path == [0, 1, 2, 3])",
                     "var expanded: [Int] = []",
                     "let beyond = dijkstraShortestPath(from: 0, cutoff: 5, successors: { (v: Int) -> [(Int, Int)] in",
                     "    expanded.append(v)",
                     "    return line2(v)",
                     "}, success: { $0 == 3 })",
                     "#expect(beyond == nil)",
                     "// The infinite line ends at the cutoff: 3, at 6, is dropped when 2 is expanded.",
                     "#expect(expanded == %s)" % ints(v)]
        else:
            assert v == 1 and calls[0][1] == "(0, 1)" and calls[1][1] is None
            body += ["let atStart = dijkstraShortestPath(from: 0, cutoff: -1, successors: line2, success: { $0 == 0 })",
                     "#expect(atStart?.distance == 0 && atStart?.path == [0])",
                     "var calls = 0",
                     "let result = dijkstraShortestPath(from: 0, cutoff: -1, successors: { (v: Int) -> [(Int, Int)] in",
                     "    calls += 1",
                     "    return line2(v)",
                     "}, success: { $0 == 1 })",
                     "#expect(result == nil)",
                     "// The start is reached at zero and expanded; every step is beyond the cutoff.",
                     "#expect(calls == %d)" % v]
    elif n == 34:
        assert [c[1] for c in calls] == [12, None, None]
        body = P_DECL + COSTLY + [
            "let manhattan = { (p: P) -> Int in abs(4 - p.x) + abs(-3 - p.y) }",
            "let result = aStarShortestPath(from: P(x: 0, y: 0), cutoff: 12, successors: costly, heuristic: manhattan, success: { $0 == P(x: 4, y: -3) })"]
        body += path_checks("costly", "P(x: 0, y: 0)", "P(x: 4, y: -3)", 12)
        body += ["// The cutoff bounds the distance, not the distance plus the estimate: A* and Dijkstra agree.",
                 "#expect(aStarShortestPath(from: P(x: 0, y: 0), cutoff: 11, successors: costly, heuristic: manhattan, success: { $0 == P(x: 4, y: -3) }) == nil)",
                 "#expect(dijkstraShortestPath(from: P(x: 0, y: 0), cutoff: 11, successors: costly, success: { $0 == P(x: 4, y: -3) }) == nil)"]
    elif n == 35:
        assert [c[1] for c in calls] == ["(6, [0, 2, 3, 4])", [0, 1, 3, 2, 3], [0, 1, 2, 3, 4, 3, 4], [0, 1, 2, 3]]
        body = ["// S→A 1, S→B 2, A→C 3, B→C 1, C→G 3 on states 0…4 (S, A, B, C, G).",
                "let reopen = { (v: Int) -> [(Int, Int)] in [[(1, 1), (2, 2)], [(3, 3)], [(3, 1)], [(4, 3)], []][v] }",
                "var expanded: [Int] = []",
                "var estimated: [Int] = []",
                "let result = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in",
                "    expanded.append(v)",
                "    return reopen(v)",
                "}, heuristic: { (v: Int) -> Int in",
                "    estimated.append(v)",
                "    return [0, 0, 4, 0, 0][v]",
                "}, success: { $0 == 4 })",
                "#expect(result?.distance == 6 && result?.path == [0, 2, 3, 4])",
                "// h(B) = 4 is more than cost(B, C) + h(C) = 1, so C is expanded at 4 (through A) before B,",
                "// then again at 3 (through B): one successors call per expansion.",
                "#expect(expanded == [0, 1, 3, 2, 3])",
                "// One estimate per push: the start, A, B, C, G, then C and G again, shorter.",
                "#expect(estimated == [0, 1, 2, 3, 4, 3, 4])",
                "var settled: [Int] = []",
                "let plain = dijkstraShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in",
                "    settled.append(v)",
                "    return reopen(v)",
                "}, success: { $0 == 4 })",
                "#expect(plain?.distance == 6 && plain?.path == [0, 2, 3, 4])",
                "#expect(settled == [0, 1, 2, 3])"]
    elif n == 36:
        assert [c[1] for c in calls] == ["(1.5, 4)", "(1.5, 4)"]
        body = ["let halves = { (v: Int) -> [(Int, Double)] in v < 3 ? [(v + 1, 0.5), (v + 2, 1.25)] : [] }",
                "let result = dijkstraShortestPath(from: 0, successors: halves, success: { $0 == 3 })",
                "#expect(result?.distance == 1.5 && result?.path == [0, 1, 2, 3])",
                "let guided = aStarShortestPath(from: 0, successors: halves, heuristic: { Double(3 - $0) * 0.5 }, success: { $0 == 3 })",
                "#expect(guided?.distance == 1.5 && guided?.path == [0, 1, 2, 3])"]
    elif n == 37:
        assert [c[1] for c in calls] == ["(1, [0, 1, 2, 3, 9])", [0, 1, 2, 3]]
        body = ["// 0→1→2→3→0 at cost 0, with 0→9 at 2 and 3→9 at 1.",
                "let zeroCycle = { (v: Int) -> [(Int, Int)] in [0: [(1, 0), (9, 2)], 1: [(2, 0)], 2: [(3, 0)], 3: [(0, 0), (9, 1)], 9: []][v]! }",
                "var expanded: [Int] = []",
                "let result = dijkstraShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in",
                "    expanded.append(v)",
                "    return zeroCycle(v)",
                "}, success: { $0 == 9 })",
                "#expect(result?.distance == 1 && result?.path == [0, 1, 2, 3, 9])",
                "// Coming back to 0 at cost 0 is no improvement, so nothing is expanded twice.",
                "#expect(expanded == [0, 1, 2, 3])"]
    elif n == 38:
        assert [c[1] for c in calls] == ["(5, [0, 1, 2, 3, 4, 5])"] * 2
        body = ["let both = { (v: Int) -> [(Int, Int)] in [(v + 1, 1), (v - 1, 2)] }",
                "let result = dijkstraShortestPath(from: 0, successors: both, success: { $0 == 5 || $0 == -3 })",
                "#expect(result?.distance == 5 && result?.path == [0, 1, 2, 3, 4, 5])",
                "let guided = aStarShortestPath(from: 0, successors: both, heuristic: { min(abs(5 - $0), abs(-3 - $0)) }, success: { $0 == 5 || $0 == -3 })",
                "#expect(guided?.distance == 5 && guided?.path == [0, 1, 2, 3, 4, 5])"]
    lines += ["        " + l for l in body]
    lines.append("    }")
    return lines


def test_for(n):
    if is_trap(n):
        return trap_test(n)
    if group(n) == "Closures":
        return closure_test(n)
    return graph_test(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, N + 1) if group(n) in groups and not is_trap(n)]


PRECONDITIONS = [n for n in range(1, N + 1) if is_trap(n)]
FILES = [
    ("ImplicitGraphConstructionTests.swift", "ImplicitGraphs construction", ids("Construction"),
     "Construction (catalog IG-001, IG-002): the closure is never called to build the graph, and an\n"
     "// empty graph never calls it at all."),
    ("ImplicitGraphReadTests.swift", "ImplicitGraphs reads", ids("Reads"),
     "Reads (catalog IG-004 – IG-011, IG-045, IG-046): one closure call per row read, positions\n"
     "// (source, rank, target) that read their ends without a call, edges in row order with one call per\n"
     "// vertex, index(after:) re-reading the row, parallel edges and self-loops as distinct positions,\n"
     "// contains, isEmpty and first reading every empty row, and the checked: spellings, which throw\n"
     "// VertexNotFound for a non-vertex without calling the closure."),
    ("ImplicitGraphGenericTests.swift", "ImplicitGraphs generic algorithms", ids("Generic"),
     "Generic algorithms on the implicit graph (catalog IG-016 – IG-022): Traversal's layers with one\n"
     "// call per discovered vertex, ShortestPaths with the weight read from the position's target,\n"
     "// Connectivity's components (as sets), topological order and findCycle."),
    ("ImplicitGraphClosureSearchTests.swift", "ImplicitGraphs closure searches", ids("Closures"),
     "Searches over successor closures on unbounded spaces (catalog IG-023 – IG-038): Traversal's\n"
     "// breadthFirstSearch(from:depthLimit:successors:), and ShortestPaths D19's\n"
     "// dijkstraShortestPath(from:cutoff:successors:success:) and aStarShortestPath(from:cutoff:\n"
     "// successors:heuristic:success:), pinning distances and, with unit costs, path vertex counts;\n"
     "// each path is checked step by step against the closure, since ties between equal paths are not\n"
     "// pinned. Then the cutoff, reopening under an inconsistent heuristic, the closures' call counts,\n"
     "// Double costs, zero costs and several goals, where paths are unique."),
    ("ImplicitGraphPreconditionTests.swift", "ImplicitGraphs preconditions", PRECONDITIONS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the fault. Then the preconditions the catalog\n"
     "// does not list (extra_traps.swift)."),
]


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "ImplicitGraphPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphProtocols", "ImplicitGraphs", "Testing"]
    if "breadthFirst" in text or "topologicalSort" in text or "findCycle" in text:
        imports.append("Traversal")
    if "shortestPaths(" in text or "dijkstraShortestPath" in text or "aStarShortestPath" in text:
        imports.append("ShortestPaths")
    if "ConnectedComponents()" in text:
        imports.append("Connectivity")
    if ".tags(" in text or fname == "ImplicitGraphPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "ImplicitGraphPreconditionTests.swift" else ""
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
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
