"""Writes the catalog-row test files of Tests/FunctionalGraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/FunctionalGraphs/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/FunctionalGraphsTests

First checks that ref.py's model reproduces cases.md byte for byte. Every row's calls are evaluated
once on the model (ref.py's port of the storage and the algorithms, checked against NetworkX and the
brute-force oracles); the generator asserts that each value, formatted, is the catalog cell, and
writes one @Test per row that checks each call's result. A row over a stored graph then writes out
the whole state from the model: every successor, edge and position, every row and index member, and
the full cycle decomposition (cycles, component, root, tail and cycle lengths, preimages, in-degrees),
with successor(of:steps:) on the graph and on the decomposition for steps 0, 1, 2, n, n + 1, 2n + 2
and Int.max. A trap row runs its call in a child process (an exit test), then runs the same setup,
or the nearest accepted input, in this process. Hand-written exit tests spliced into the
precondition file: extra_traps.swift.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "FunctionalGraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and every row's calls with their values on the model
# ---------------------------------------------------------------------------------------------
RECORD = {}      # row number -> (input text, [(call text, value or Trap)])
SUCC = {}        # row number -> the successor array of a graph row
_row, _graph_row = ref.row, ref.graph_row
_current = [None]


def _rec_row(group, title, input_text, thunks):
    n = len(ref.ROWS) + 1
    done = []
    memo = []
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
        SUCC[n] = _current[0]
    _row(group, title, input_text, memo)


def _rec_graph_row(group, title, succ, calls):
    _current[0] = list(succ)
    n = len(ref.ROWS) + 1
    try:
        _graph_row(group, title, succ, calls)
    finally:
        _current[0] = None
    if n not in RECORD:  # the construction trapped
        RECORD[n] = ("FG %s" % ref.fmt(succ), [])
        SUCC[n] = list(succ)


ref.row, ref.graph_row = _rec_row, _rec_graph_row
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| FG-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 62 and sorted(RECORD) == list(range(1, N + 1))


def group(n): return CELLS[n][1]
def title(n): return CELLS[n][2]
def inp(n): return CELLS[n][3]
def cell(n): return CELLS[n][4]
def is_trap(n): return "**trap**" in cell(n)


# Every recorded value, formatted, is its catalog cell.
for n in range(1, N + 1):
    shown = []
    for _, v in RECORD[n][1]:
        shown.append("**trap** (%s)" % v if isinstance(v, ref.Trap) else ref.fmt(v))
    if not RECORD[n][1]:
        shown = [cell(n)]
    assert "; ".join(shown) == cell(n), (n, shown, cell(n))

# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------
INT_MAX = ref.INT_MAX


def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]" if xs else "[] as [Int]"
def int_rows(rs): return "[" + ", ".join(ints(r) for r in rs) + "]" if rs else "[] as [[Int]]"
def b(x): return "true" if x else "false"
def opt(x): return "nil" if x is None else str(x)
def steps_lit(k): return "Int.max" if k == INT_MAX else ("1_000_000" if k == 1_000_000 else str(k))


def construct(succ, var="graph"):
    return "let %s = FunctionalGraph(successors: %s)" % (var, ints(succ))


def state(succ, ind="        ", var="graph"):
    """The whole stored graph and its decomposition, from the model."""
    g = ref.FG(succ)
    ref.check(g)
    d = g.decomposition()
    n = g.n
    V = list(range(n))
    out = ["// The whole graph, from the model.",
           "#expect(%s.vertexCount == %d && %s.edgeCount == %d && %s.edges.count == %d)" % (var, n, var, n, var, n),
           "#expect(%s.vertexIndexBound == %d && %s.edgeIndexBound == %d)" % (var, n, var, n),
           "#expect(Array(%s.vertices) == %s)" % (var, ints(V)),
           "#expect(%s.vertices.map { %s.successor(of: $0) } == %s)" % (var, var, ints(succ)),
           "#expect(%s.edges.map { [$0.source, $0.target] } == %s)" % (var, int_rows([[v, succ[v]] for v in V])),
           "#expect(Array(%s.edges.indices) == %s)" % (var, ints(V)),
           "#expect(%s.edges.indices.map { [%s.source(ofEdgeAt: $0), %s.target(ofEdgeAt: $0), %s.edgeIndex(of: $0)] } == %s)"
           % (var, var, var, var, int_rows([[v, succ[v], v] for v in V])),
           "#expect(%s.vertices.map { Array(%s.successors(of: $0)) } == %s)" % (var, var, int_rows([[succ[v]] for v in V])),
           "#expect(%s.vertices.map { Array(%s.successorIndices(ofIndex: $0)) } == %s)" % (var, var, int_rows([[succ[v]] for v in V])),
           "#expect(%s.vertices.map { Array(%s.outEdges(of: $0)) } == %s)" % (var, var, int_rows([[v] for v in V])),
           "#expect(%s.vertices.map { Array(%s.outEdges(ofIndex: $0)) } == %s)" % (var, var, int_rows([[v] for v in V])),
           "#expect(%s.vertices.map { %s.outDegree(of: $0) } == %s)" % (var, var, ints([1] * n)),
           "#expect(%s.vertices.map { [%s.vertexIndex(of: $0), %s.vertex(atIndex: $0)] } == %s)" % (var, var, var, int_rows([[v, v] for v in V])),
           "#expect(%s.vertices.allSatisfy { %s.contains($0) && %s.contains(edge: DirectedEdge(from: $0, to: %s.successor(of: $0))) })" % (var, var, var, var),
           "#expect(!%s.contains(-1) && !%s.contains(%d))" % (var, var, n)]
    out += ["// The cycle decomposition, from the model.",
            "let whole = %s.cycleDecomposition()" % var,
            "#expect(whole.cycles.map { Array($0) } == %s)" % int_rows(d.cycles),
            "#expect(whole.cycles.count == %d)" % len(d.cycles)]
    for name, fn in [("component", d.component), ("root", d.root_of), ("tailLength", d.tail_length),
                     ("cycleLength", d.cycle_length), ("inDegree", d.in_degree)]:
        out.append("#expect(%s.vertices.map { whole.%s(of: $0) } == %s)" % (var, name, ints([fn(v) for v in V])))
    out.append("#expect(%s.vertices.map { Array(whole.preimages(of: $0)) } == %s)" % (var, int_rows([d.preimages_of(v) for v in V])))
    for k in sorted({0, 1, 2, n, n + 1, 2 * n + 2, INT_MAX}):
        want = [d.successor_steps(v, k) for v in V]
        assert want == [g.successor_steps(v, k) for v in V]
        out.append("#expect(%s.vertices.map { %s.successor(of: $0, steps: %s) } == %s)" % (var, var, steps_lit(k), ints(want)))
        out.append("#expect(%s.vertices.map { whole.successor(of: $0, steps: %s) } == %s)" % (var, steps_lit(k), ints(want)))
    return [ind + l for l in out]


# ---------------------------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------------------------
EDGE = re.compile(r"(\d+):(\d+)→(\d+)")


def edge_arg(text):
    m = re.search(r"(-?\d+)→(-?\d+)", text)
    return "DirectedEdge(from: %s, to: %s)" % (m.group(1), m.group(2))


def call_line(n, text, v, ind="        "):
    """The Swift line checking `text` (a catalog call) returns the model's value v."""
    on_whole = group(n) == "Decomposition" or text.startswith("cycleDecomposition()")
    obj = "whole" if on_whole else "graph"
    if text in ("vertexCount", "edgeCount", "edgeIndexBound", "vertexIndexBound"):
        return "#expect(graph.%s == %s)" % (text, opt(v))
    if text == "vertices":
        return "#expect(Array(graph.vertices) == %s)" % ints(v)
    if text == "edges":
        es = [list(map(int, m)) for m in EDGE.findall(v)]
        return "#expect(graph.edges.indices.map { [$0, graph.edges[$0].source, graph.edges[$0].target] } == %s)" % int_rows(es)
    m = re.fullmatch(r"(successors|outEdges)\(of: (-?\d+)\)", text)
    if m:
        return "#expect(Array(graph.%s(of: %s)) == %s)" % (m.group(1), m.group(2), ints(v))
    m = re.fullmatch(r"successorIndices\(ofIndex: (\d+)\)", text)
    if m:
        return "#expect(Array(graph.successorIndices(ofIndex: %s)) == %s)" % (m.group(1), ints(v))
    m = re.fullmatch(r"contains\((-?\d+)\)", text)
    if m:
        return "#expect(%sgraph.contains(%s))" % ("" if v else "!", m.group(1))
    if text.startswith("contains(edge:"):
        return "#expect(%sgraph.contains(edge: %s))" % ("" if v else "!", edge_arg(text))
    m = re.fullmatch(r"successor\(of: (-?\d+), steps: ([\w_.]+)\)", text)
    if m:
        return "#expect(%s.successor(of: %s, steps: %s) == %d)" % (obj, m.group(1), m.group(2), v)
    m = re.fullmatch(r"(successor|outDegree|vertexIndex|edgeIndex|root)\(of: (-?\d+)\)", text)
    if m:
        o = "whole" if m.group(1) == "root" else "graph"
        return "#expect(%s.%s(of: %s) == %d)" % (o, m.group(1), m.group(2), v)
    m = re.fullmatch(r"(vertex)\(atIndex: (\d+)\)|(source|target)\(ofEdgeAt: (\d+)\)", text)
    if m:
        return "#expect(graph.%s == %d)" % (text, v)
    if text == "cycles":
        return "#expect(whole.cycles.map { Array($0) } == %s)" % int_rows(v)
    if text == "cycles.count":
        return "#expect(whole.cycles.count == %d)" % v
    m = re.fullmatch(r"(\w+)\(of:\) for 0\.\.<(\d+)", text)
    if m:
        return "#expect((0 ..< %s).map { whole.%s(of: $0) } == %s)" % (m.group(2), m.group(1), ints(v))
    m = re.fullmatch(r"preimages\(of: (\d+)\)", text)
    if m:
        return "#expect(Array(whole.preimages(of: %s)) == %s)" % (m.group(1), ints(v))
    if text == "weaklyConnectedComponents() as sets":
        return "#expect(Set(graph.weaklyConnectedComponents().map { Set($0) }) == Set(%s.map { Set($0) }))" % int_rows(v)
    if text == "nontrivial or looped components":
        return ("#expect(Set(graph.stronglyConnectedComponents().filter { $0.count > 1 || graph.successor(of: $0.first!) == $0.first! }"
                ".map { Set($0) }) == Set(%s.map { Set($0) }))" % int_rows(v))
    raise ValueError((n, text))


def header(n, tags=()):
    return ['    @Test("FG-%03d %s"%s)' % (n, title(n), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


def graph_test(n):
    succ = SUCC[n]
    calls = RECORD[n][1]
    lines = header(n) + ["    func fg%03d() {" % n, "        // %s → %s" % (inp(n), cell(n)), "        " + construct(succ)]
    if any(group(n) == "Decomposition" or t.startswith("cycleDecomposition()") or t.startswith("root(") for t, _ in calls):
        lines.append("        let whole = graph.cycleDecomposition()")
    for text, v in calls:
        lines.append("        " + call_line(n, text, v))
    lines += _scoped_state(succ)
    lines.append("    }")
    return lines


def _scoped_state(succ):
    return ["        do {"] + state(succ, ind="            ") + ["        }"]


def closure_test(n):
    """init(vertexCount:successor:): the successors and the order of the calls."""
    text, calls = RECORD[n]
    m = re.fullmatch(r"FunctionalGraph\(vertexCount: (\d+), successor: (\{.*\})\)", text)
    count, body = m.group(1), m.group(2)
    succ, log = calls[0][1], calls[1][1]
    lines = header(n) + ["    func fg%03d() {" % n, "        // %s → %s" % (inp(n), cell(n)),
                         "        let f: (Int) -> Int = %s" % body,
                         "        var log: [Int] = []",
                         "        let graph = FunctionalGraph(vertexCount: %s, successor: { (v: Int) -> Int in" % count,
                         "            log.append(v)",
                         "            return f(v)",
                         "        })",
                         "        #expect(graph.vertices.map { graph.successor(of: $0) } == %s)" % ints(succ),
                         "        #expect(log == %s)" % ints(log),
                         "        #expect(graph == FunctionalGraph(successors: %s))" % ints(succ)]
    lines += _scoped_state(succ)
    lines.append("    }")
    return lines


def pseudo(text):
    m = re.fullmatch(r"FunctionalGraph\(DirectedPseudograph\(vertices: \[(.*)\], edges: \[(.*)\]\)\)", text)
    vs = [x for x in m.group(1).split(", ") if x]
    es = [tuple(e.split("→")) for e in m.group(2).split(", ") if e]
    lit_v = "[" + ", ".join(json.dumps(x) for x in vs) + "]" if vs else "[] as [String]"
    lit_e = "[" + ", ".join("DirectedEdge(from: %s, to: %s)" % (json.dumps(a), json.dumps(c)) for a, c in es) + "]" if es else "[] as [DirectedEdge<String>]"
    return vs, "DirectedPseudograph<String>(vertices: %s, edges: %s)" % (lit_v, lit_e)


def from_graph_test(n):
    text, calls = RECORD[n]
    vs, lit = pseudo(text)
    succ = calls[0][1]
    lines = header(n) + ["    func fg%03d() {" % n, "        // %s → %s" % (inp(n), cell(n)),
                         "        let pseudograph = " + lit,
                         "        let graph = FunctionalGraph(pseudograph)"]
    if succ is None:
        lines.append("        #expect(graph == nil)")
    else:
        lines += ["        #expect(graph.map { g in g.vertices.map { g.successor(of: $0) } } == %s)" % ints(succ),
                  "        #expect(graph == FunctionalGraph(successors: %s))" % ints(succ),
                  "        // Labeled by the graph's vertices, it gives the labels and the edges back.",
                  "        let labeled = LabeledGraph(graph!, labels: pseudograph.vertices)",
                  "        #expect(Array(labeled.vertices) == Array(pseudograph.vertices))",
                  "        #expect(labeled.edges.map { [$0.source, $0.target] } == pseudograph.edges.map { [$0.source, $0.target] })"]
    lines.append("    }")
    return lines


def floyd_brent_test(n):
    text, calls = RECORD[n]
    lines = header(n) + ["    func fg%03d() {" % n, "        // %s" % inp(n), "        // → %s" % cell(n)]
    if text.startswith("struct Pair"):
        lines += ["        struct Pair: Equatable {", "            var a, b: Int", "        }",
                  "        let f: (Pair) -> Pair = { Pair(a: $0.b, b: ($0.a + $0.b) % 10) }"]
        vtype, start = "Pair", "Pair(a: 0, b: 1)"
    else:
        lines.append("        let f: (Int) -> Int = %s" % text[len("f = "):])
        vtype = "Int"
        start = re.search(r"floydCycleDetection\(from: (\d+)", inp(n)).group(1)
    (ft, fa), (ct, ca), (bt, bb), (dt, db) = calls
    lines.append("        var calls = 0")
    for name, res, cnt in (("floyd", fa, ca), ("brent", bb, db)):
        mu, lam, root = res
        rlit = "Pair(a: %d, b: %d)" % root if isinstance(root, tuple) else str(root)
        lines += ([] if name == "floyd" else ["        calls = 0"]) + [
                  "        let %s = %sCycleDetection(from: %s, successor: { (x: %s) -> %s in" % (name, name, start, vtype, vtype),
                  "            calls += 1",
                  "            return f(x)",
                  "        })",
                  "        #expect(%s.tailLength == %d && %s.cycleLength == %d && %s.root == %s)" % (name, mu, name, lam, name, rlit),
                  "        #expect(calls == %d)" % cnt]
    # The definition: tailLength steps reach root, cycleLength more steps return to it, and no
    # earlier vertex of the walk is on the cycle.
    lines += ["        // The definition, by walking f: the root is tailLength steps out and on a cycle of",
              "        // cycleLength; the vertex before it is not on the cycle.",
              "        var x = %s" % start,
              "        for _ in 0 ..< floyd.tailLength { x = f(x) }",
              "        #expect(x == floyd.root)",
              "        var y = f(x)",
              "        var length = 1",
              "        while y != x {",
              "            y = f(y)",
              "            length += 1",
              "        }",
              "        #expect(length == floyd.cycleLength)",
              "        if floyd.tailLength > 0 {",
              "            var before = %s" % start,
              "            for _ in 1 ..< floyd.tailLength { before = f(before) }",
              "            var after = before",
              "            for _ in 0 ..< floyd.cycleLength { after = f(after) }",
              "            #expect(after != before)",
              "        }"]
    lines.append("    }")
    return lines


def conformance_test(n):
    lines = header(n, [".conformance"]) + ["    func fg%03d() throws {" % n if n == 62 else "    func fg%03d() {" % n,
                                          "        // %s → %s" % (inp(n), cell(n))]
    if n == 60:
        lines += ["        #expect(FunctionalGraph(successors: [1, 0]) == FunctionalGraph(successors: [1, 0]))",
                  "        #expect(FunctionalGraph(successors: [1, 0]) != FunctionalGraph(successors: [0, 1]))",
                  "        #expect(FunctionalGraph(successors: [1, 0]).hashValue == FunctionalGraph(successors: [1, 0]).hashValue)",
                  "        #expect(Set([FunctionalGraph(successors: [1, 0]), FunctionalGraph(successors: [1, 0]), FunctionalGraph(successors: [0, 1])]).count == 2)",
                  "        #expect(FunctionalGraph(successors: [0]) != FunctionalGraph(successors: [0, 0]))"]
    elif n == 61:
        lines += ['        #expect(FunctionalGraph(successors: [1, 2, 0]).description == "FunctionalGraph([1, 2, 0])")',
                  '        #expect(FunctionalGraph(successors: []).description == "FunctionalGraph([])")',
                  '        #expect("\\(FunctionalGraph(successors: [0]))" == "FunctionalGraph([0])")']
    else:
        lines += ["        let data = try JSONEncoder().encode(FunctionalGraph(successors: [1, 2, 0]))",
                  '        #expect(String(decoding: data, as: UTF8.self) == "[1,2,0]")',
                  "        #expect(try JSONDecoder().decode(FunctionalGraph.self, from: data) == FunctionalGraph(successors: [1, 2, 0]))",
                  '        for corrupt in ["[0,3]", "[-1]", "[1]"] {',
                  "            do {",
                  "                _ = try JSONDecoder().decode(FunctionalGraph.self, from: Data(corrupt.utf8))",
                  '                Issue.record("decoded \\(corrupt)")',
                  "            } catch DecodingError.dataCorrupted {",
                  "            } catch {",
                  '                Issue.record("\\(corrupt): \\(error)")',
                  "            }",
                  "        }",
                  '        #expect(try JSONDecoder().decode(FunctionalGraph.self, from: Data("[]".utf8)) == FunctionalGraph(successors: []))']
    lines.append("    }")
    return lines


# Trap rows: the call in a child process, then the setup (or the nearest accepted input) here.
TRAP_CHILD = {
    7: ("_ = FunctionalGraph(vertexCount: 2, successor: { _ in 2 })", "FunctionalGraph(vertexCount: 2, successor: { _ in 1 })", [1, 1]),
    8: ("_ = FunctionalGraph(vertexCount: -1, successor: { $0 })", "FunctionalGraph(vertexCount: 0, successor: { $0 })", []),
    9: ("_ = FunctionalGraph(successors: [0, 3])", "FunctionalGraph(successors: [0, 1])", [0, 1]),
    10: ("_ = FunctionalGraph(successors: [-1])", "FunctionalGraph(successors: [0])", [0]),
}


def trap_test(n):
    text, calls = RECORD[n]
    lines = header(n) + ["    func fg%03d() async {" % n, "        // %s → %s" % (inp(n), cell(n))]
    if n in TRAP_CHILD:
        child, near, succ = TRAP_CHILD[n]
        lines += ["        await #expect(processExitsWith: .failure) {", "            " + child, "        }",
                  "        // The nearest accepted input.",
                  "        let graph = " + near]
        lines += state(succ)
        lines.append("    }")
        return lines
    succ = SUCC[n]
    (ctext, trap), = calls
    assert isinstance(trap, ref.Trap) and cell(n) == "**trap** (%s)" % trap
    child = "_ = graph.%s" % ctext
    lines += ["        await #expect(processExitsWith: .failure) {", "            " + construct(succ), "            " + child, "        }",
              "        // Without the call: the state the call would apply to.", "        " + construct(succ)]
    lines += state(succ)
    lines.append("    }")
    return lines


def test_for(n):
    if is_trap(n):
        return trap_test(n)
    g = group(n)
    if g == "Closures":
        return floyd_brent_test(n)
    if g == "Conformances":
        return conformance_test(n)
    text = RECORD[n][0]
    if text.startswith("FunctionalGraph(vertexCount:"):
        return closure_test(n)
    if text.startswith("FunctionalGraph(DirectedPseudograph"):
        return from_graph_test(n)
    return graph_test(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, N + 1) if group(n) in groups and not is_trap(n)]


TRAPS = [n for n in range(1, N + 1) if is_trap(n)]
FILES = [
    ("FunctionalGraphConstructionTests.swift", "FunctionalGraphs construction", ids("Construction"),
     "Construction (catalog FG-001 – FG-006, FG-011 – FG-015): `init(successors:)`, edge position p\n"
     "// leaving p, `init(vertexCount:successor:)` calling once per vertex in ascending order, and\n"
     "// `init?(_ graph:)` numbering the graph's vertices in order, nil unless every out-degree is 1."),
    ("FunctionalGraphReadTests.swift", "FunctionalGraphs reads", ids("Reads"),
     "Reads (catalog FG-016 – FG-018): the one-element rows, membership false off 0..<n, and the\n"
     "// dense indices, which are the vertices and the edge positions."),
    ("FunctionalGraphStepTests.swift", "FunctionalGraphs successor(of:steps:)", ids("Steps"),
     "f^k on the stored graph (catalog FG-021 – FG-024): a walk for k <= n, and past n the tail and\n"
     "// cycle by Brent's algorithm, up to Int.max steps."),
    ("FunctionalGraphDecompositionTests.swift", "FunctionalGraphs cycle decomposition", ids("Decomposition"),
     "The cycle decomposition (catalog FG-026 – FG-042): cycles from their least vertex and in order\n"
     "// of least vertex, component, root, tail and cycle lengths, ascending preimages, and f^k by\n"
     "// level ancestor in the trees and by position on the cycle."),
    ("FunctionalGraphGenericTests.swift", "FunctionalGraphs generic algorithms", ids("Generic"),
     "Generic algorithms (catalog FG-045, FG-046): Connectivity's components agree with the\n"
     "// decomposition, compared as sets since their order is Connectivity's rule."),
    ("FunctionalGraphCycleDetectionTests.swift", "FunctionalGraphs Floyd and Brent", ids("Closures"),
     "Cycle detection over a closure (catalog FG-047 – FG-059): the tail length, cycle length and root,\n"
     "// and the exact closure call counts of the formulations api.md pins."),
    ("FunctionalGraphEqualityTests.swift", "FunctionalGraphs equality, description and Codable", ids("Conformances"),
     "Conformances (catalog FG-060 – FG-062): equality and hashing of the successor arrays, the\n"
     "// description, and Codable as the bare array, with decoding re-checking the range."),
    ("FunctionalGraphPreconditionTests.swift", "FunctionalGraphs preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup, or the nearest accepted input, then runs in this process without the fault. Then\n"
     "// the preconditions the catalog does not list (extra_traps.swift)."),
]


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "FunctionalGraphPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["FunctionalGraphs", "GraphProtocols", "Testing"]
    if "DirectedPseudograph" in text:
        imports.append("Multigraphs")
    if "LabeledGraph(" in text:
        imports.append("LabeledGraphs")
    if "ConnectedComponents()" in text:
        imports.append("Connectivity")
    if "JSONEncoder" in text:
        imports.append("Foundation")
    if ".tags(" in text or fname == "FunctionalGraphPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "FunctionalGraphPreconditionTests.swift" else ""
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
