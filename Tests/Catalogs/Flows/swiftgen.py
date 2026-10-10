"""Writes the catalog-row test files of Tests/FlowsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 \
        python3 swiftgen.py [OUT_DIR]          # default: Tests/FlowsTests

First runs ref.py's catalog with every case builder instrumented, so each row's network is kept as
a structured value, and checks that the rendered catalog equals cases.md byte for byte. Then
re-evaluates each row with ref.py's models (Edmonds-Karp, Stoer-Wagner, Gusfield, the
successive-shortest-path min-cost model, the split-network connectivity), asserts that the value
renders to its catalog cell exactly, and writes one @Test per row. The representation tests run the
rows again on other representations; where a representation numbers the edges differently
(CompressedSparseRow, AdjacencyMatrix: row-major cells), the position-dependent values (only
Edmonds-Karp's per-edge flow, and the order of a cut's edges) are recomputed here with the same
models on those positions. Hand-written tests spliced in: extra_traps.swift (preconditions the
catalog does not list).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "FlowsTests")
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


for kind, name in [("flow", "flow_rows"), ("global", "global_rows"), ("gh", "gh_rows"), ("mcf", "mcf_rows"),
                   ("mcmf", "mcmf_rows"), ("conn", "conn_rows"), ("paths", "paths_rows"), ("trap", "trap")]:
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
    if line.startswith("| FL-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[parts[0]] = parts
assert len(CELLS) == TOTAL


def cid_of(i):
    return f"FL-{i + 1:03d}"


# ---------------------------------------------------------------------------------------------
# Literals
# ---------------------------------------------------------------------------------------------


def lit(x):
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, str):
        return json.dumps(x, ensure_ascii=False)
    if isinstance(x, float):
        return repr(x)
    return str(x)


def arr(xs):
    return "[" + ", ".join(lit(x) for x in xs) + "]"


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def vtype(net):
    return "String" if any(isinstance(x, str) for x in net.labels) else "Int"


def ctype(net):
    return net.ctype


def is_float(net):
    return net.ctype == "Double"


def acc(net):
    """The type the tests sum capacities in: Int for integers (sums of UInt8 or Int8 capacities can
    pass the type), Int128 when the capacities' total could pass Int, Double for Double."""
    if is_float(net):
        return "Double"
    return "Int128" if sum(net.caps()) > (1 << 62) else "Int"


def widen(net, expr):
    return expr if is_float(net) else f"{acc(net)}({expr})"


def inexact(net):
    """Double capacities that are not multiples of 1/1024: values and flows within 1e-12."""
    return is_float(net) and any(not (c * 1024).is_integer() for c in net.caps())


def labels(net, idxs):
    return [net.labels[i] for i in idxs]


def vlist(net):
    T = vtype(net)
    return f"{arr(net.labels)} as [{T}]"


def side_lit(net, idxs):
    return f"{arr(labels(net, sorted(idxs)))} as [{vtype(net)}]"


def pairs_line(net, index_form=False):
    T = "Int" if index_form else vtype(net)
    if index_form:
        ps = [(u, v) for u, v in net.E]
    else:
        ps = [(net.labels[u], net.labels[v]) for u, v in net.E]
    return f"let pairs: [({T}, {T})] = [" + ", ".join(f"({lit(u)}, {lit(v)})" for u, v in ps) + "]"


def caps_line(net, name="capacities", values=None):
    vals = net.caps() if values is None else values
    return f"let {name}: [{ctype(net)}] = {arr(vals)}"


def repeated_arc(net):
    return len(set(net.E)) != len(net.E)


def repeated_pair(net):
    """Undirected parallel edges (a repeated unordered pair, loops included)."""
    keys = [frozenset((u, v)) for u, v in net.E]
    return len(set(keys)) != len(keys)


def primary(net):
    if net.directed:
        return "dpseudo" if repeated_arc(net) else "al"
    return "pseudo" if repeated_pair(net) else "ual"


REP_NAMES = {
    "al": "AdjacencyList", "dpseudo": "DirectedPseudograph", "refd": "ReferenceDirectedMultigraph",
    "unidx": "no indices", "csr": "CompressedSparseRow", "am": "AdjacencyMatrix",
    "ual": "UndirectedAdjacencyList", "pseudo": "Pseudograph", "refu": "ReferencePseudograph",
    "unidxu": "no indices", "alu": "AdjacencyList.undirected", "amu": "AdjacencyMatrix.undirected",
}


def reps(net):
    """The representations a row runs on again, after its primary one."""
    if net.directed:
        out = ["refd" if primary(net) == "dpseudo" else "dpseudo", "unidx"]
        if not repeated_arc(net):
            out += ["csr", "am"]
        return out
    out = ["refu" if primary(net) == "pseudo" else "pseudo", "unidxu"]
    if not repeated_arc(net):
        out += ["alu", "amu"]
    return out


def index_form(rep):
    return rep in ("csr", "am", "amu")


def graph_line(net, rep):
    T = vtype(net)
    V = vlist(net)
    n = net.n
    if rep == "al":
        return f"let graph = AdjacencyList<{T}>(vertices: {V}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})"
    if rep == "dpseudo":
        return f"let graph = DirectedPseudograph<{T}>(vertices: {V}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})"
    if rep == "refd":
        return f"let graph = ReferenceDirectedMultigraph<{T}>(vertices: {V}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})"
    if rep == "unidx":
        return f"let graph = UnindexedDirectedGraph<{T}>(vertices: {V}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})"
    if rep == "csr":
        return f"let graph = CompressedSparseRow(vertexCount: {n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})"
    if rep == "am":
        return f"let graph = AdjacencyMatrix(vertexCount: {n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }})"
    if rep == "ual":
        return f"let graph = UndirectedAdjacencyList<{T}>(vertices: {V}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})"
    if rep == "pseudo":
        return f"let graph = Pseudograph<{T}>(vertices: {V}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})"
    if rep == "refu":
        return f"let graph = ReferencePseudograph<{T}>(vertices: {V}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})"
    if rep == "unidxu":
        return f"let graph = UnindexedGraph<{T}>(vertices: {V}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})"
    if rep == "alu":
        return f"let graph = AdjacencyList<{T}>(vertices: {V}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected"
    if rep == "amu":
        return f"let graph = AdjacencyMatrix(vertexCount: {n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected"
    raise ValueError(rep)


def rep_order(net, rep):
    """Catalog edge numbers in the representation's position order."""
    if index_form(rep):
        return sorted(range(net.m), key=lambda k: net.E[k])
    return list(range(net.m))


def permuted(net, rep):
    order = rep_order(net, rep)
    return ref.Net(range(net.n), [net.E[k] for k in order], [net.caps()[k] for k in order],
                   cost=None if net.cost is None else [net.cost[k] for k in order], directed=net.directed, ctype=net.ctype), order


def ek_flows(net, s, t, rep="al"):
    """Edmonds-Karp's per-edge flow (signed along the stored order when undirected), by catalog edge,
    on the representation's positions."""
    pnet, order = permuted(net, rep)
    _, r = ref.edmonds_karp(pnet, s, t)
    fl = ref.edge_flows(pnet, r)
    out = [None] * net.m
    for rank, k in enumerate(order):
        out[k] = fl[rank]
    return out


def cut_strings(net, T, rep="al"):
    """The cut's edges in the representation's position order, as catalog edge numbers (`3r`: the
    arc against the stored order)."""
    out = []
    for k in rep_order(net, rep):
        u, v = net.E[k]
        if u == v:
            continue
        if net.directed:
            if u not in T and v in T:
                out.append(str(k))
        elif (u in T) != (v in T):
            out.append(str(k) if u not in T else f"{k}r")
    return out


def cut_expect(net, T, rep, var="cut"):
    strs = cut_strings(net, T, rep)
    if index_form(rep):
        if net.directed:
            return f"#expect({var}.edges.map {{ edgeOf[$0]! }} == {arr([int(x) for x in strs])} as [Int])"
        return f'#expect({var}.edges.map {{ "\\(edgeOf[$0.position]!)\\($0.reversed ? "r" : "")" }} == {arr(strs)} as [String])'
    if net.directed:
        return f"#expect({var}.edges == {arr([int(x) for x in strs])} as [Int])"
    return f'#expect({var}.edges.map {{ "\\($0.position)\\($0.reversed ? "r" : "")" }} == {arr(strs)} as [String])'


def position_lines(net, rep):
    """For representations that renumber the edges: each catalog edge's position, the reverse map,
    and the capacities by position."""
    if not index_form(rep):
        return []
    if rep == "amu":
        find = "graph.edges.indices.first { graph.edges[$0].u == p.0 && graph.edges[$0].v == p.1 }!"
    else:
        find = "graph.edges.indices.first { graph.edges[$0] == DirectedEdge(from: p.0, to: p.1) }!"
    return [
        "// Positions here are row-major cells: each catalog edge's position, and back.",
        f"let positionOfEdge = pairs.map {{ p in {find} }}",
        "let edgeOf = Dictionary(uniqueKeysWithValues: positionOfEdge.enumerated().map { ($1, $0) })",
    ]


def capacity_closure(rep, name="capacities"):
    if index_form(rep):
        return f"{{ {name}[edgeOf[$0]!] }}"
    return f"{{ {name}[$0] }}"


def vertex_arg(net, rep, i):
    return lit(i) if index_form(rep) else lit(net.labels[i])


def rep_side(net, rep, idxs):
    if index_form(rep):
        return f"{arr(sorted(idxs))} as [Int]"
    return side_lit(net, idxs)


def value_expect(net, expr, value):
    if inexact(net):
        return f"#expect(abs({expr} - {lit(value)}) <= 1e-12)"
    return f"#expect({expr} == {lit(value)})"


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
    return "fl" + cid[3:]


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
            m = re.match(r"^\s*let (\w+) = ", l)
            if not m:
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


def parse_call(call):
    """`maximumFlow(from: s, to: t, capacity:)` -> ('maximumFlow', 's', 't')."""
    m = re.match(r"(\w+)\((?:from: ([^,]+), to: ([^,)]+))?", call)
    return m.group(1), m.group(2), m.group(3)


def label_index(net, label_text):
    for i, x in enumerate(net.labels):
        if str(x) == label_text:
            return i
    raise KeyError(label_text)


# ---------------------------------------------------------------------------------------------
# Shared in-test code
# ---------------------------------------------------------------------------------------------


def prelude(net, rep):
    T = vtype(net)
    L = [pairs_line(net), caps_line(net), graph_line(net, rep),
         "let vertexList = Array(graph.vertices)",
         f"#expect(vertexList == {vlist(net)})"]
    if net.directed:
        L.append("#expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })")
    else:
        L.append("#expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })")
    L += ["let n = vertexList.count",
          "// Edge ends as vertex indices (positions in `vertices`), in position order.",
          "let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }"]
    del T
    return L


ASKED = ["// `capacity` is called once per non-loop edge, in position order; self-loops are never asked.",
         "#expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })"]


def call_with_asked(var, expr, closure_param="position"):
    return ["var asked: [Int] = []",
            f"let {var} = {expr} {{ {closure_param} in",
            f"    asked.append({closure_param})",
            f"    return capacities[{closure_param}]",
            "}"]


def flow_checks_directed(net, value, flows_exact=None):
    CT = ctype(net)
    acc = "Double" if is_float(net) else "Int"
    conv = (lambda e: e) if is_float(net) else (lambda e: f"Int({e})")
    L = [value_expect(net, "flow.value", value),
         "let flows = pairs.indices.map { flow.flow(ofEdgeAt: $0) }"]
    if flows_exact is not None:
        if inexact(net):
            L.append(f"let expectedFlows: [{CT}] = {arr(flows_exact)}")
            L.append("#expect(zip(flows, expectedFlows).allSatisfy { abs($0 - $1) <= 1e-12 }, \"\\(flows)\")")
        else:
            L.append(f"#expect(flows == {arr(flows_exact)} as [{CT}])")
    L += ["// Capacity and conservation, checked here: 0 ≤ flow ≤ capacity and nothing on a self-loop; inflow",
          "// equals outflow at every vertex but the ends; the value is the net flow out of the source.",
          f"var excess = [{acc}](repeating: 0, count: n)",
          "for k in pairs.indices {",
          "    #expect(flows[k] >= 0 && flows[k] <= capacities[k], \"edge \\(k)\")",
          "    if ends[k].0 == ends[k].1 { #expect(flows[k] == 0, \"self-loop \\(k)\") }",
          f"    excess[ends[k].1] += {conv('flows[k]')}",
          f"    excess[ends[k].0] -= {conv('flows[k]')}",
          "}"]
    if is_float(net):
        L += ["for x in 0 ..< n where x != s && x != t { #expect(abs(excess[x]) <= 1e-12, \"at \\(vertexList[x])\") }",
              "#expect(abs(excess[t] - flow.value) <= 1e-12)",
              "#expect(abs(excess[s] + flow.value) <= 1e-12)"]
    else:
        L += ["for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, \"at \\(vertexList[x])\") }",
              "#expect(excess[t] == Int(flow.value))",
              "#expect(excess[s] == -Int(flow.value))"]
    return L


def flow_checks_undirected(net, value, flows_exact=None):
    CT = ctype(net)
    L = [value_expect(net, "flow.value", value),
         "// The flow is over `directed`: an edge's flow along its stored order is on the forward arc, against",
         "// it on the reversed arc; both at least zero, at most one nonzero, each at most the capacity.",
         "let forward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: false)) }",
         "let backward = pairs.indices.map { flow.flow(ofEdgeAt: .init(position: $0, reversed: true)) }",
         "for k in pairs.indices {",
         "    #expect(forward[k] >= 0 && backward[k] >= 0 && (forward[k] == 0 || backward[k] == 0), \"edge \\(k)\")",
         "    #expect(forward[k] <= capacities[k] && backward[k] <= capacities[k], \"edge \\(k)\")",
         "    if ends[k].0 == ends[k].1 { #expect(forward[k] == 0 && backward[k] == 0, \"self-loop \\(k)\") }",
         "}",
         "let signed = pairs.indices.map { forward[$0] - backward[$0] }"]
    if flows_exact is not None:
        if inexact(net):
            L.append(f"let expectedFlows: [{CT}] = {arr(flows_exact)}")
            L.append("#expect(zip(signed, expectedFlows).allSatisfy { abs($0 - $1) <= 1e-12 }, \"\\(signed)\")")
        else:
            L.append(f"#expect(signed == {arr(flows_exact)} as [{CT}])")
    L += ["// Conservation, checked here: inflow equals outflow at every vertex but the ends; the value is the",
          "// net flow out of the source.",
          f"var excess = [{CT}](repeating: 0, count: n)",
          "for k in pairs.indices {",
          "    excess[ends[k].1] += signed[k]",
          "    excess[ends[k].0] -= signed[k]",
          "}"]
    if is_float(net):
        L += ["for x in 0 ..< n where x != s && x != t { #expect(abs(excess[x]) <= 1e-12, \"at \\(vertexList[x])\") }",
              "#expect(abs(excess[t] - flow.value) <= 1e-12)",
              "#expect(abs(excess[s] + flow.value) <= 1e-12)"]
    else:
        L += ["for x in 0 ..< n where x != s && x != t { #expect(excess[x] == 0, \"at \\(vertexList[x])\") }",
              "#expect(excess[t] == flow.value)",
              "#expect(excess[s] == -flow.value)"]
    return L


def residual_reach(net, flowvar):
    """BFS from the sink over residual arcs of the flow in `flowvar` (flows / signed)."""
    if net.directed:
        cond_in = f"{flowvar}[k] < capacities[k]"
        cond_out = f"{flowvar}[k] > 0"
        head = ["// The canonical cut, found here: the sink side is every vertex that can still reach the sink in this",
                "// flow's residual network (u→v while the edge's flow is below its capacity, v→u while it is positive)."]
    else:
        cond_in = f"{flowvar}[k] < capacities[k]"
        cond_out = f"{flowvar}[k] > -capacities[k]"
        head = ["// The canonical cut, found here: the sink side is every vertex that can still reach the sink in this",
                "// flow's residual network (u→v while the signed flow is below the capacity, v→u while it is above",
                "// minus the capacity)."]
    return head + [
        "var reaches = [Bool](repeating: false, count: n)",
        "reaches[t] = true",
        "var queue = [t]",
        "while let y = queue.popLast() {",
        "    for k in pairs.indices where ends[k].0 != ends[k].1 {",
        "        let (a, b) = ends[k]",
        f"        if b == y && !reaches[a] && {cond_in} {{",
        "            reaches[a] = true",
        "            queue.append(a)",
        "        }",
        f"        if a == y && !reaches[b] && {cond_out} {{",
        "            reaches[b] = true",
        "            queue.append(b)",
        "        }",
        "    }",
        "}",
    ]


def cut_definition_lines(net, var="cut", reach="reaches"):
    """The cut's edges are every edge from the source side to the sink side; its value their sum."""
    if net.directed:
        L = [f"#expect({var}.edges == pairs.indices.filter {{ ends[$0].0 != ends[$0].1 && !{reach}[ends[$0].0] && {reach}[ends[$0].1] }})",
             f"#expect({var}.value == {var}.edges.reduce(0) {{ $0 + capacities[$1] }})"]
    else:
        L = [f"let crossing = pairs.indices.filter {{ ends[$0].0 != ends[$0].1 && {reach}[ends[$0].0] != {reach}[ends[$0].1] }}",
             f'#expect({var}.edges.map {{ "\\($0.position)\\($0.reversed ? "r" : "")" }} == crossing.map {{ {reach}[ends[$0].1] ? "\\($0)" : "\\($0)r" }})',
             f"#expect({var}.value == crossing.reduce(0) {{ $0 + capacities[$1] }})"]
    return L


def cut_exact_lines(net, T, value, var="cut"):
    S = set(range(net.n)) - T
    return [f"#expect(Array({var}.sourceSide) == {side_lit(net, S)})",
            f"#expect(Array({var}.sinkSide) == {side_lit(net, T)})",
            cut_expect(net, T, "al", var),
            f"#expect({var}.value == {lit(value)})"]


def brute_st_lines(net, value_expr, sink_expr, sv="s", tv="t"):
    """Every s-t cut by brute force (n ≤ 12): the least value, and the least sink side among the minimum
    cuts (their intersection: minimum cuts form a lattice)."""
    CT = ctype(net)
    cross = "inS[a] && !inS[b]" if net.directed else "inS[a] != inS[b]"
    return [
        f"// Brute force over every cut separating {sv} from {tv}: the least value, and the least sink side among",
        "// the minimum cuts, their intersection (minimum cuts form a lattice).",
        f"let others = (0 ..< n).filter {{ $0 != {sv} && $0 != {tv} }}",
        f"var best: {CT}? = nil",
        "var leastSink = Set(0 ..< n)",
        "for mask in 0 ..< (1 << others.count) {",
        "    var inS = [Bool](repeating: false, count: n)",
        f"    inS[{sv}] = true",
        "    for (bit, x) in others.enumerated() where mask & (1 << bit) != 0 { inS[x] = true }",
        f"    var value: {CT} = 0",
        f"    for k in pairs.indices where ends[k].0 != ends[k].1 {{",
        "        let (a, b) = ends[k]",
        f"        if {cross} {{ value += capacities[k] }}",
        "    }",
        "    let sink = Set((0 ..< n).filter { !inS[$0] })",
        "    if best == nil || value < best! {",
        "        best = value",
        "        leastSink = sink",
        "    } else if value == best! {",
        "        leastSink.formIntersection(sink)",
        "    }",
        "}",
        f"#expect(best == {value_expr})",
        f"#expect(leastSink == Set({sink_expr}))",
    ]


# ---------------------------------------------------------------------------------------------
# Row bodies
# ---------------------------------------------------------------------------------------------

FLOW_FN = {"MaximumFlow": "maximumFlow", "EdmondsKarp": "edmondsKarpMaximumFlow", "Dinic": "dinicMaximumFlow",
           "MaximumFlowValue": "maximumFlowValue", "MinimumCut": "minimumCut"}


def canonical(net, si, ti):
    value, flows, T, _ = ref.canonical(net, si, ti)
    return value, flows, T


def verify_flow(cid, group, net, si, ti):
    value, flows, T = canonical(net, si, ti)
    S = set(range(net.n)) - T
    cut = f"S {ref.lab_list(net, S)}; T {ref.lab_list(net, T)}; cut {ref.fmtl(ref.cut_edges(net, T))}"
    exp = {"MaximumFlow": f"value {ref.fmtv(value)}; {cut}",
           "EdmondsKarp": f"value {ref.fmtv(value)}; flow {ref.fmtl(ref.fmtv(x) for x in flows)}; {cut}",
           "Dinic": f"value {ref.fmtv(value)}; {cut}",
           "MaximumFlowValue": ref.fmtv(value),
           "MinimumCut": f"value {ref.fmtv(value)}; {cut}"}[group]
    assert CELLS[cid][5] == exp, (cid, CELLS[cid][5], exp)
    return value, flows, T


def body_flow(cid, group, net, si, ti):
    value, flows, T = verify_flow(cid, group, net, si, ti)
    fn = FLOW_FN[group]
    S_lab, T_lab = lit(net.labels[si]), lit(net.labels[ti])
    rep = primary(net)
    L = [comment_input(cid)] + prelude(net, rep)
    L += [f"let s = vertexList.firstIndex(of: {S_lab})!", f"let t = vertexList.firstIndex(of: {T_lab})!"]
    if group == "MaximumFlowValue":
        L += call_with_asked("value", f"graph.maximumFlowValue(from: {S_lab}, to: {T_lab})")
        L += ASKED
        L.append(value_expect(net, "value", value))
        L.append("// The value of the maximum flow and of the minimum cut.")
        if inexact(net):
            L.append(f"#expect(abs(value - graph.maximumFlow(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}).value) <= 1e-12)")
            L.append(f"#expect(abs(value - graph.minimumCut(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}).value) <= 1e-12)")
        else:
            L.append(f"#expect(value == graph.maximumFlow(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}).value)")
            L.append(f"#expect(value == graph.minimumCut(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}).value)")
        return L
    if group == "MinimumCut":
        L += call_with_asked("cut", f"graph.minimumCut(from: {S_lab}, to: {T_lab})")
        L += ASKED
        L += cut_exact_lines(net, T, value)
        L += ["// Its edges are every edge from the source side to the sink side, zero capacities included; its",
              "// value is their capacity.",
              "let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }",
              "#expect(Array(cut.sourceSide) + Array(cut.sinkSide) == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })"]
        L += cut_definition_lines(net)
        if net.n <= 12:
            L += brute_st_lines(net, "cut.value", "(0 ..< n).filter { reaches[$0] }")
        L += ["// The same cut as every maximum flow's.",
              f"#expect(cut == graph.maximumFlow(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}).minimumCut)",
              f"#expect(cut == graph.edmondsKarpMaximumFlow(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}).minimumCut)",
              f"#expect(cut == graph.dinicMaximumFlow(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}).minimumCut)"]
        return L
    L += call_with_asked("flow", f"graph.{fn}(from: {S_lab}, to: {T_lab})")
    L += ASKED
    L.append(f"#expect(flow.source == {S_lab} && flow.sink == {T_lab})")
    exact = flows if group == "EdmondsKarp" else None
    if net.directed:
        L += flow_checks_directed(net, value, exact)
    else:
        L += flow_checks_undirected(net, value, exact)
    fv = "flows" if net.directed else "signed"
    if inexact(net):
        L += ["// Capacities that are not dyadic: residuals near zero depend on rounding, so the cut is checked",
              "// against the catalog only (api.md: the cut follows residuals > 0 as computed)."]
        L += ["let cut = flow.minimumCut"] + cut_exact_lines(net, T, value)
        L.append("#expect(abs(cut.value - flow.value) <= 1e-12)")
        return L
    L += residual_reach(net, fv)
    L += ["let cut = flow.minimumCut"] + cut_exact_lines(net, T, value)
    L += ["#expect(Array(cut.sinkSide) == (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })",
          "// Its edges are every edge from the source side to the sink side, zero capacities included; its",
          "// value is their capacity, the flow's value (so both are optimal)."]
    L += cut_definition_lines(net)
    L.append("#expect(cut.value == flow.value)")
    return L


def verify_global(cid, net):
    """(value, sink side or None when several minimum cuts leave it open), or None."""
    res = ref.global_cut(net, net.caps())
    exp = ref.global_expected(net, res)
    assert CELLS[cid][5] == exp, (cid, CELLS[cid][5], exp)
    return None if res is None else res[:2]


def body_global(cid, net):
    res = verify_global(cid, net)
    rep = primary(net)
    L = [comment_input(cid)] + prelude(net, rep)
    L += call_with_asked("result", "graph.minimumCut")
    L += ASKED
    if res is None:
        L += ["// Fewer than two vertices: no nonempty proper vertex set.", "#expect(result == nil)"]
        return L
    val, T = res
    A = acc(net)
    L.append("let cut = try #require(result)")
    if T is not None:
        L += cut_exact_lines(net, T, val)
    else:
        L += ["// Several minimum cuts: which one is returned is not pinned, so the cut is checked from its own sides.",
              value_expect(net, "cut.value", val)]
    L += ["let reaches = vertexList.indices.map { cut.sinkSide.contains(vertexList[$0]) }",
          "#expect(cut.sourceSide + cut.sinkSide == (0 ..< n).filter { !reaches[$0] }.map { vertexList[$0] } + (0 ..< n).filter { reaches[$0] }.map { vertexList[$0] })",
          "#expect(!cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)",
          "// Its edges are every edge from the source side to the sink side; its value is their capacity."]
    L += cut_definition_lines(net)
    if not net.directed:
        L += ["// The first vertex is on the source side.", "#expect(!reaches[0])"]
    if net.n <= 12:
        cross = "inS[a] && !inS[b]" if net.directed else "inS[a] != inS[b]"
        L += ["// Brute force: the least cut over every nonempty proper vertex set." if net.directed else
              "// Brute force: the least cut over every nonempty proper vertex set (with the first vertex, by symmetry).",
              f"var best: {A}? = nil",
              "for mask in 1 ..< (1 << n) - 1 {" if net.directed else "for mask in 1 ..< (1 << n) - 1 where mask & 1 != 0 {",
              "    let inS = (0 ..< n).map { mask & (1 << $0) != 0 }",
              f"    var value: {A} = 0",
              "    for k in pairs.indices where ends[k].0 != ends[k].1 {",
              "        let (a, b) = ends[k]",
              f"        if {cross} {{ value += {widen(net, 'capacities[k]')} }}",
              "    }",
              "    if best == nil || value < best! { best = value }",
              "}",
              f"#expect(best == {widen(net, 'cut.value')})"]
        L.append("// The same cut on a second call.")
        L.append("#expect(graph.minimumCut(capacity: { capacities[$0] }) == cut)")
    return L


def verify_gh(cid, net):
    res = ref.gomory_hu(net)
    if res is None:
        exp = "nil"
    else:
        p, fl = res
        exp = f"edges {ref.fmtl([f'{net.lab(i)}–{net.lab(p[i])} {ref.fmtv(fl[i])}' for i in range(1, net.n)])}"
    assert CELLS[cid][5] == exp, (cid, CELLS[cid][5], exp)
    return res


def body_gh(cid, net):
    res = verify_gh(cid, net)
    rep = primary(net)
    CT = ctype(net)
    L = [comment_input(cid)] + prelude(net, rep)
    L += call_with_asked("result", "graph.gomoryHuTree")
    L += ASKED
    if res is None:
        L += ["#expect(result == nil)"]
        return L
    p, fl = res
    n = net.n
    L += ["let gomoryHu = try #require(result)",
          "let tree = gomoryHu.tree",
          "#expect(Array(tree.vertices) == vertexList)",
          f"#expect(tree.edgeCount == {n - 1})",
          "// The tree edge at position k joins the vertex at index k + 1 and its parent, with the minimum cut",
          "// value between them as its capacity.",
          f"let parent: [Int] = {arr([p[i] for i in range(1, n)])}",
          f"let treeCapacities: [{CT}] = {arr([fl[i] for i in range(1, n)])}",
          "for k in 0 ..< n - 1 {",
          "    let edge = tree.edges[k]",
          "    #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], vertexList[parent[k]]]), \"tree edge \\(k)\")",
          "    #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], \"tree edge \\(k)\")",
          "}"]
    if n <= 1:
        L += ["_ = (parent, treeCapacities, ends)"]
        return L
    L += [
        "// Every ordered pair: the least capacity on the tree path is minimumCutValue(between:and:), and the",
        "// least cut by brute force; minimumCut(between:and:) is the split at the least tree edge nearest u,",
        "// u on its source side, with the graph's crossing edges.",
        "for u in 0 ..< n {",
        "    for v in 0 ..< n where v != u {",
        "        // The tree path, written as the child end of each tree edge from u to v.",
        "        var upU = [u], upV = [v]",
        "        while upU.last! != 0 { upU.append(parent[upU.last! - 1]) }",
        "        while upV.last! != 0 { upV.append(parent[upV.last! - 1]) }",
        "        let lca = upU.first { upV.contains($0) }!",
        "        let pathChildren = Array(upU.prefix { $0 != lca }) + Array(upV.prefix { $0 != lca }.reversed())",
        "        let least = pathChildren.map { treeCapacities[$0 - 1] }.min()!",
        "        let firstLeast = pathChildren.first { treeCapacities[$0 - 1] == least }!",
        "        let minimum = gomoryHu.minimumCutValue(between: vertexList[u], and: vertexList[v])",
        "        #expect(minimum == least, \"\\(vertexList[u]), \\(vertexList[v])\")",
        "        // The subtree below the least edge, and u's side of the split.",
        "        let below = (0 ..< n).map { x in",
        "            var y = x",
        "            while y != 0 && y != firstLeast { y = parent[y - 1] }",
        "            return y == firstLeast",
        "        }",
        "        let inS = (0 ..< n).map { below[$0] == below[u] }",
        "        let cut = gomoryHu.minimumCut(between: vertexList[u], and: vertexList[v])",
        "        #expect(Array(cut.sourceSide) == (0 ..< n).filter { inS[$0] }.map { vertexList[$0] }, \"\\(vertexList[u]), \\(vertexList[v])\")",
        "        #expect(Array(cut.sinkSide) == (0 ..< n).filter { !inS[$0] }.map { vertexList[$0] }, \"\\(vertexList[u]), \\(vertexList[v])\")",
        "        let crossing = pairs.indices.filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }",
        '        #expect(cut.edges.map { "\\($0.position)\\($0.reversed ? "r" : "")" } == crossing.map { inS[ends[$0].0] ? "\\($0)" : "\\($0)r" })',
        "        #expect(cut.value == least, \"\\(vertexList[u]), \\(vertexList[v])\")",
        "        #expect(crossing.reduce(0) { $0 + capacities[$1] } == least)",
    ]
    if n <= 10:
        L += [
            "        // Brute force: the least cut separating u from v.",
            f"        var best: {acc(net)}? = nil",
            "        for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {",
            f"            var value: {acc(net)} = 0",
            "            for k in pairs.indices where ends[k].0 != ends[k].1 {",
            f"                if (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) {{ value += {widen(net, 'capacities[k]')} }}",
            "            }",
            "            if best == nil || value < best! { best = value }",
            "        }",
            f"        #expect(best == {widen(net, 'least')}, \"\\(vertexList[u]), \\(vertexList[v])\")",
        ]
    L += ["    }", "}"]
    return L


def mcf_supply(net):
    return net.supply if net.supply is not None else [0] * net.n


def verify_mcf(cid, net):
    res = ref.mcf_net(net, net.supply)
    if res is None:
        exp = "nil"
        uniq = None
    else:
        cost, f = res
        uniq = ref.unique_flow(net, net.supply, cost, f)
        exp = f"cost {cost}; flow {ref.fmtl(f)}" + ("" if uniq else " (one of several optima)")
    assert CELLS[cid][5] == exp, (cid, CELLS[cid][5], exp)
    return res, uniq


def mcf_feasibility_lines(supply_name="supplies", res="result"):
    return [
        "// Feasible, checked here: 0 ≤ flow ≤ capacity, and out − in = supply at every vertex.",
        "var balance = [Int](repeating: 0, count: n)",
        "for k in pairs.indices {",
        "    #expect(flows[k] >= 0 && flows[k] <= capacities[k], \"edge \\(k)\")",
        "    balance[ends[k].0] += Int(flows[k])",
        "    balance[ends[k].1] -= Int(flows[k])",
        "}",
        f"#expect(balance == {supply_name}.map {{ Int($0) }})",
        "// The cost is Σ flow × cost; a self-loop carries its capacity when its cost is negative, else nothing.",
        f"#expect(Int({res}.cost) == pairs.indices.reduce(0) {{ $0 + Int(flows[$1]) * Int(costs[$1]) }})",
        "for k in pairs.indices where ends[k].0 == ends[k].1 {",
        "    #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), \"self-loop \\(k)\")",
        "}",
        "// Optimal, checked here (complementary slackness): with the potentials p, every edge with flow below",
        "// its capacity has reduced cost cost + p(u) − p(v) ≥ 0, and every edge with positive flow has ≤ 0.",
        f"let potentials = vertexList.map {{ Int({res}.potential(of: $0)) }}",
        "for k in pairs.indices {",
        "    let reduced = Int(costs[k]) + potentials[ends[k].0] - potentials[ends[k].1]",
        "    if flows[k] < capacities[k] { #expect(reduced >= 0, \"edge \\(k): reduced cost \\(reduced)\") }",
        "    if flows[k] > 0 { #expect(reduced <= 0, \"edge \\(k): reduced cost \\(reduced)\") }",
        "}",
    ]


def body_mcf(cid, net):
    (res, uniq) = verify_mcf(cid, net)
    rep = primary(net)
    CT = ctype(net)
    T = vtype(net)
    sup = mcf_supply(net)
    L = [comment_input(cid)] + prelude(net, rep)
    L += [f"let costs: [{CT}] = {arr(net.cost)}",
          f"// Supplies by vertex index: positive sends, negative receives.",
          f"let supplies: [{CT}] = {arr(sup)}",
          f"var suppliesAsked: [{T}] = []",
          "var capacitiesAsked: [Int] = []",
          "var costsAsked: [Int] = []",
          "let result = graph.minimumCostFlow(supply: { vertex in",
          "    suppliesAsked.append(vertex)",
          "    return supplies[vertexList.firstIndex(of: vertex)!]",
          "}, capacity: { position in",
          "    capacitiesAsked.append(position)",
          "    return capacities[position]",
          "}, cost: { position in",
          "    costsAsked.append(position)",
          "    return costs[position]",
          "})",
          "// `supply` is called once per vertex in order, `capacity` and `cost` once per edge in position order."]
    if res is None:
        L += ["#expect(suppliesAsked == vertexList)",
              "// No flow exists: each closure is still called at most once per edge, in order.",
              "#expect(capacitiesAsked == Array(pairs.indices.prefix(capacitiesAsked.count)))",
              "#expect(costsAsked == Array(pairs.indices.prefix(costsAsked.count)))",
              "#expect(result == nil)",
              "// Infeasible, checked here: the supplies do not sum to zero, or some vertex set supplies more",
              "// than its out-edges carry (Gale's theorem).",
              "var witness = supplies.reduce(0) { $0 + Int($1) } != 0",
              "for mask in 1 ..< max(1 << n, 1) where !witness {",
              "    var supplied = 0, carried = 0",
              "    for x in 0 ..< n where mask & (1 << x) != 0 { supplied += Int(supplies[x]) }",
              "    for k in pairs.indices where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { carried += Int(capacities[k]) }",
              "    if supplied > carried { witness = true }",
              "}",
              "#expect(witness)"]
        return L
    cost, f = res
    L += ["#expect(suppliesAsked == vertexList)",
          "#expect(capacitiesAsked == Array(pairs.indices))",
          "#expect(costsAsked == Array(pairs.indices))",
          "let flowResult = try #require(result)",
          f"#expect(flowResult.cost == {cost})",
          "// The amount shipped: the sum of the positive supplies.",
          f"#expect(flowResult.value == {sum(x for x in sup if x > 0)})",
          "let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }"]
    if uniq:
        L.append(f"#expect(flows == {arr(f)} as [{CT}])")
    else:
        L.append(f"// One of several optima (catalog: {arr(f)}): the flow itself is not pinned.")
    L += mcf_feasibility_lines(res="flowResult")
    return L


def verify_mcmf(cid, net, si, ti):
    value, _ = ref.edmonds_karp(net, si, ti)
    supply = [0] * net.n
    supply[si], supply[ti] = value, -value
    cost, f = ref.mcf_net(net, supply)
    uniq = ref.unique_flow(net, supply, cost, f)
    exp = f"value {value}; cost {cost}; flow {ref.fmtl(f)}" + ("" if uniq else " (one of several optima)")
    assert CELLS[cid][5] == exp, (cid, CELLS[cid][5], exp)
    return value, cost, f, uniq


def body_mcmf(cid, net, si, ti):
    value, cost, f, uniq = verify_mcmf(cid, net, si, ti)
    rep = primary(net)
    CT = ctype(net)
    S_lab, T_lab = lit(net.labels[si]), lit(net.labels[ti])
    L = [comment_input(cid)] + prelude(net, rep)
    L += [f"let costs: [{CT}] = {arr(net.cost)}",
          f"let s = vertexList.firstIndex(of: {S_lab})!",
          f"let t = vertexList.firstIndex(of: {T_lab})!",
          f"let flowResult = graph.minimumCostMaximumFlow(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}, cost: {{ costs[$0] }})",
          f"#expect(flowResult.value == {value})",
          f"#expect(flowResult.cost == {cost})",
          "// The value is the maximum flow value.",
          f"#expect(flowResult.value == graph.maximumFlowValue(from: {S_lab}, to: {T_lab}, capacity: {{ capacities[$0] }}))",
          "let flows = pairs.indices.map { flowResult.flow(ofEdgeAt: $0) }"]
    if uniq:
        L.append(f"#expect(flows == {arr(f)} as [{CT}])")
    else:
        L.append(f"// One of several optima (catalog: {arr(f)}): the flow itself is not pinned.")
    L += ["// The supplies of a flow of that value from the source to the sink.",
          f"var supplies = [{CT}](repeating: 0, count: n)",
          "supplies[s] = flowResult.value",
          "supplies[t] = -flowResult.value"]
    L += mcf_feasibility_lines(res="flowResult")
    return L


def conn_simple_lines(net):
    """Adjacency of the simple graph (self-loops dropped, parallel edges once), both ways when
    undirected; and whether an edge goes from a to b."""
    if net.directed:
        return ["// The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).",
                "var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)",
                "for (a, b) in ends where a != b {",
                "    out[a].insert(b)",
                "    into[b].insert(a)",
                "}"]
    return ["// The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).",
            "var out = [Set<Int>](repeating: [], count: n)",
            "for (a, b) in ends where a != b {",
            "    out[a].insert(b)",
            "    out[b].insert(a)",
            "}",
            "let into = out"]


def strong_lines(removed, result):
    """`result`: whether the vertices not in `removed` (a mask) induce a strongly connected graph of
    at least two vertices."""
    return [f"let kept = (0 ..< n).filter {{ {removed} & (1 << $0) == 0 }}",
            f"var {result} = kept.count >= 2",
            f"if {result} {{",
            "    for rows in [out, into] {",
            "        var seen: Set<Int> = [kept[0]]",
            "        var queue = [kept[0]]",
            "        while let x = queue.popLast() {",
            f"            for y in rows[x] where {removed} & (1 << y) == 0 && !seen.contains(y) {{",
            "                seen.insert(y)",
            "                queue.append(y)",
            "            }",
            "        }",
            f"        if seen.count != kept.count {{ {result} = false }}",
            "    }",
            "}"]


def verify_conn(cid, net, group, call):
    fn, s, t = parse_call(call)
    if s is None:
        if group == "VertexConnectivity":
            v = ref.global_vertex(net)[0]
            exp = str(v)
        elif group == "MinimumVertexCut":
            v = ref.global_vertex(net)[1]
            exp = ref.lab_list(net, v)
        else:
            v = ref.global_edge(net)
            exp = str(v)
        assert CELLS[cid][5] == exp, (cid, CELLS[cid][5], exp)
        return v, None, None
    si, ti = label_index(net, s), label_index(net, t)
    if group == "VertexConnectivity":
        v = ref.local_vertex(net, si, ti)[0]
        exp = str(v)
    elif group == "MinimumVertexCut":
        v = ref.local_vertex(net, si, ti)[1]
        exp = "nil" if v is None else ref.lab_list(net, v)
    else:
        v = ref.local_edge(net, si, ti)
        exp = str(v)
    assert CELLS[cid][5] == exp, (cid, CELLS[cid][5], exp)
    return v, si, ti


def conn_prelude(net, rep):
    L = [pairs_line(net), graph_line(net, rep),
         "let vertexList = Array(graph.vertices)",
         f"#expect(vertexList == {vlist(net)})"]
    if net.directed:
        L.append("#expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })")
    else:
        L.append("#expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })")
    L += ["let n = vertexList.count",
          "// Edge ends as vertex indices (positions in `vertices`), in position order.",
          "let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }"]
    return L


def body_conn(cid, net, group, call):
    v, si, ti = verify_conn(cid, net, group, call)
    rep = primary(net)
    L = [comment_input(cid)] + conn_prelude(net, rep)
    n = net.n
    if si is None:
        if group == "EdgeConnectivity":
            L += [f"let lambda = graph.edgeConnectivity()",
                  f"#expect(lambda == {v})",
                  "// The minimum cut with unit capacities is one (api.md).",
                  "#expect(lambda == (graph.minimumCut(capacity: { _ in 1 })?.value ?? 0))"]
            if 2 <= n <= 12:
                cross = "inS[a] && !inS[b]" if net.directed else "inS[a] != inS[b]"
                L += ["// Brute force: the fewest edges leaving a nonempty proper vertex set, parallel edges each, self-loops never.",
                      "var best = Int.max",
                      "for mask in 1 ..< (1 << n) - 1 {",
                      "    let inS = (0 ..< n).map { mask & (1 << $0) != 0 }",
                      "    var count = 0",
                      "    for (a, b) in ends where a != b {",
                      f"        if {cross} {{ count += 1 }}",
                      "    }",
                      "    best = min(best, count)",
                      "}",
                      "#expect(lambda == best)"]
            return L
        if group == "VertexConnectivity":
            L += ["let kappa = graph.vertexConnectivity()", f"#expect(kappa == {v})"]
            if n <= 10:
                L += conn_simple_lines(net)
                L += ["// Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)",
                      "// connected; n − 1 when no smaller set does, and 0 below two vertices.",
                      "var least = max(n - 1, 0)",
                      "search: for size in 0 ..< max(n - 1, 0) {",
                      "    for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {"]
                L += indent(strong_lines("removed", "connected"), 8)
                L += ["        if !connected {",
                      "            least = size",
                      "            break search",
                      "        }",
                      "    }",
                      "}",
                      "#expect(kappa == least)"]
            L += ["// At most the edge connectivity (Whitney).", "#expect(kappa <= graph.edgeConnectivity())"]
            return L
        # MinimumVertexCut()
        L += ["let cut = graph.minimumVertexCut()",
              f"#expect(cut == {side_lit(net, v)})",
              "#expect(cut.count == graph.vertexConnectivity())"]
        L += conn_simple_lines(net)
        L += ["let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }" if n <= 60 else "",
              ]
        if n <= 60:
            L += ["// Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut",
                  "// is every vertex after the first."]
            L += strong_lines("removed", "connected")
            L += ["#expect(!connected || n < 2)",
                  "if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }"]
        return [l for l in L if l != ""]
    S_lab, T_lab = lit(net.labels[si]), lit(net.labels[ti])
    L += [f"let s = vertexList.firstIndex(of: {S_lab})!", f"let t = vertexList.firstIndex(of: {T_lab})!"]
    if group == "EdgeConnectivity":
        L += [f"let lambda = graph.edgeConnectivity(from: {S_lab}, to: {T_lab})",
              f"#expect(lambda == {v})",
              "// The maximum flow with unit capacities (Menger: edge-disjoint paths).",
              f"#expect(lambda == graph.maximumFlowValue(from: {S_lab}, to: {T_lab}, capacity: {{ _ in 1 }}))"]
        if n <= 12:
            cross = "inS[a] && !inS[b]" if net.directed else "inS[a] != inS[b]"
            L += ["// Brute force: the fewest edges from a set holding s but not t.",
                  "var best = Int.max",
                  "for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {",
                  "    let inS = (0 ..< n).map { mask & (1 << $0) != 0 }",
                  "    var count = 0",
                  "    for (a, b) in ends where a != b {",
                  f"        if {cross} {{ count += 1 }}",
                  "    }",
                  "    best = min(best, count)",
                  "}",
                  "#expect(lambda == best)"]
        return L
    L += conn_simple_lines(net)
    L += ["// Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.",
          "let adjacent = out[s].contains(t)",
          "// Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.",
          ]
    reach = ["var seen: Set<Int> = [s]",
             "var queue = [s]",
             "while let x = queue.popLast() {",
             "    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {",
             "        seen.insert(y)",
             "        queue.append(y)",
             "    }",
             "}",
             "let separated = !seen.contains(t)"]
    if group == "VertexConnectivity":
        L += [f"let kappa = graph.vertexConnectivity(from: {S_lab}, to: {T_lab})", f"#expect(kappa == {v})"]
        if n <= 12:
            L += ["// Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for",
                  "// an edge from s to t.",
                  "var least = -1",
                  "search: for size in 0 ... max(n - 2, 0) {",
                  "    for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {"]
            L += indent(reach, 8)
            L += ["        if separated {",
                  "            least = size",
                  "            break search",
                  "        }",
                  "    }",
                  "}",
                  "#expect(kappa == least + (adjacent ? 1 : 0))"]
        else:
            L.append("_ = adjacent")
        return L
    # MinimumVertexCut(from:to:)
    L += [f"let cut = graph.minimumVertexCut(from: {S_lab}, to: {T_lab})"]
    if v is None:
        L += ["// An edge from s to t: no vertex set separates them.", "#expect(adjacent)", "#expect(cut == nil)"]
        return L
    L += [f"#expect(cut == {side_lit(net, v)})",
          "#expect(!adjacent)",
          f"#expect(cut?.count == graph.vertexConnectivity(from: {S_lab}, to: {T_lab}))",
          "// Removing it separates s from t.",
          "let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }" if n <= 60 else "let removed = 0"]
    L += reach
    L += ["#expect(separated)"]
    return L


def verify_paths(cid, net, group, si, ti):
    k = ref.local_edge(net, si, ti) if group == "EdgeDisjointPaths" else ref.local_vertex(net, si, ti)[0]
    assert CELLS[cid][5] == ref.paths_word(k), (cid, CELLS[cid][5], k)
    return k


def body_paths(cid, net, group, si, ti):
    k = verify_paths(cid, net, group, si, ti)
    rep = primary(net)
    fn = "edgeDisjointPaths" if group == "EdgeDisjointPaths" else "vertexDisjointPaths"
    S_lab, T_lab = lit(net.labels[si]), lit(net.labels[ti])
    L = [comment_input(cid)] + conn_prelude(net, rep)
    L += [f"let s = vertexList.firstIndex(of: {S_lab})!", f"let t = vertexList.firstIndex(of: {T_lab})!",
          f"let paths = graph.{fn}(from: {S_lab}, to: {T_lab})",
          f"#expect(paths.count == {k})"]
    if group == "EdgeDisjointPaths":
        L += ["// As many as the fewest edges separating s from t (Menger).",
              f"#expect(paths.count == graph.edgeConnectivity(from: {S_lab}, to: {T_lab}))"]
    else:
        L += ["// As many as κ(s, t), an edge from s to t counting as one path (Menger).",
              f"#expect(paths.count == graph.vertexConnectivity(from: {S_lab}, to: {T_lab}))"]
    if net.directed:
        L += ["// Each a path from s to t along its edges, repeating no vertex; no edge in two of them."]
        step = "let (a, b) = ends[edge]"
        edge = "edge"
        L += ["var usedEdges = Set<Int>()"]
    else:
        L += ["// Each a path from s to t along its edges (an arc against the stored order when reversed), repeating",
              "// no vertex; no edge in two of them."]
        step = "let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]"
        edge = "arc.position"
        L += ["var usedEdges = Set<Int>()"]
    if group == "VertexDisjointPaths":
        L.append("var usedInner = Set<Int>()")
    L += ["for path in paths {",
          "    let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }",
          "    #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)",
          "    #expect(Set(numbers).count == numbers.count)"]
    L += [("    for (i, edge) in path.edges.enumerated() {" if net.directed else "    for (i, arc) in path.edges.enumerated() {"),
          f"        {step}",
          "        #expect(a == numbers[i] && b == numbers[i + 1] && a != b)",
          f"        #expect(usedEdges.insert({edge}).inserted)",
          "    }"]
    if group == "VertexDisjointPaths":
        L += ["    for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }"]
    L += ["}"]
    return L


# ---------------------------------------------------------------------------------------------
# Representation tests
# ---------------------------------------------------------------------------------------------


def rep_block(cid, kind, group, net, rep, si=None, ti=None, call=None):
    """Lines inside `do { … }` for one representation."""
    n = net.n
    L = []
    if index_form(rep):
        L.append(pairs_line(net, index_form=True))
    L.append(graph_line(net, rep))
    if rep in ("unidx", "unidxu"):
        L.append("#expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)")
    L += position_lines(net, rep)
    cap = capacity_closure(rep)
    if kind == "flow":
        value, flows, T = canonical(net, si, ti)
        S = set(range(n)) - T
        sa, ta = vertex_arg(net, rep, si), vertex_arg(net, rep, ti)
        fn = FLOW_FN[group]
        if group == "MaximumFlowValue":
            L.append(value_expect(net, f"graph.maximumFlowValue(from: {sa}, to: {ta}, capacity: {cap})", value))
            return L
        if group == "MinimumCut":
            L.append(f"let cut = graph.minimumCut(from: {sa}, to: {ta}, capacity: {cap})")
        else:
            L.append(f"let flow = graph.{fn}(from: {sa}, to: {ta}, capacity: {cap})")
            L.append(value_expect(net, "flow.value", value))
            if group == "EdmondsKarp":
                ek = ek_flows(net, si, ti, rep)
                pos = "positionOfEdge[$0]" if index_form(rep) else "$0"
                if net.directed:
                    got = f"pairs.indices.map {{ flow.flow(ofEdgeAt: {pos}) }}"
                else:
                    got = (f"pairs.indices.map {{ flow.flow(ofEdgeAt: .init(position: {pos}, reversed: false)) - "
                           f"flow.flow(ofEdgeAt: .init(position: {pos}, reversed: true)) }}")
                if index_form(rep) and ek != flows:
                    L.append("// Edmonds–Karp's flow follows positions, so it differs here from the catalog's.")
                if inexact(net):
                    L.append(f"let expectedFlows: [{ctype(net)}] = {arr(ek)}")
                    L.append(f"#expect(zip({got}, expectedFlows).allSatisfy {{ abs($0 - $1) <= 1e-12 }})")
                else:
                    L.append(f"#expect({got} == {arr(ek)} as [{ctype(net)}])")
            L.append("let cut = flow.minimumCut")
        L += [f"#expect(Array(cut.sourceSide) == {rep_side(net, rep, S)})",
              f"#expect(Array(cut.sinkSide) == {rep_side(net, rep, T)})",
              cut_expect(net, T, rep),
              f"#expect(cut.value == {lit(value)})"]
        return L
    if kind == "global":
        res = verify_global(cid, net)
        L.append(f"let result = graph.minimumCut(capacity: {cap})")
        if res is None:
            L.append("#expect(result == nil)")
            return L
        val, T = res
        if T is None:
            first = "0" if index_form(rep) else lit(net.labels[0])
            L += ["let cut = try #require(result)",
                  "// One of several minimum cuts: the value, the sides splitting every vertex, and on an undirected",
                  "// graph the first vertex on the source side.",
                  value_expect(net, "cut.value", val),
                  f"#expect(cut.sourceSide.count + cut.sinkSide.count == {n} && !cut.sourceSide.isEmpty && !cut.sinkSide.isEmpty)"]
            if not net.directed:
                L.append(f"#expect(cut.sourceSide.first == {first})")
            return L
        S = set(range(n)) - T
        L += ["let cut = try #require(result)",
              f"#expect(Array(cut.sourceSide) == {rep_side(net, rep, S)})",
              f"#expect(Array(cut.sinkSide) == {rep_side(net, rep, T)})",
              cut_expect(net, T, rep),
              f"#expect(cut.value == {lit(val)})"]
        return L
    if kind == "gh":
        res = verify_gh(cid, net)
        L.append(f"let result = graph.gomoryHuTree(capacity: {cap})")
        if res is None:
            L.append("#expect(result == nil)")
            return L
        p, fl = res
        vl = arr(list(range(n))) + " as [Int]" if index_form(rep) else vlist(net)
        pv = arr([p[i] if index_form(rep) else net.labels[p[i]] for i in range(1, n)])
        L += ["let gomoryHu = try #require(result)",
              f"let vertexList = {vl}",
              "#expect(Array(gomoryHu.tree.vertices) == vertexList)",
              f"let parents = {pv} as [{'Int' if index_form(rep) else vtype(net)}]",
              f"let treeCapacities: [{ctype(net)}] = {arr([fl[i] for i in range(1, n)])}",
              f"for k in 0 ..< {n - 1} {{",
              "    let edge = gomoryHu.tree.edges[k]",
              "    #expect(Set([edge.u, edge.v]) == Set([vertexList[k + 1], parents[k]]), \"tree edge \\(k)\")",
              "    #expect(gomoryHu.capacity(ofEdgeAt: k) == treeCapacities[k], \"tree edge \\(k)\")",
              "}"]
        if n <= 1:
            L.append("_ = (parents, treeCapacities)")
        return L
    if kind in ("mcf", "mcmf"):
        CT = ctype(net)
        order = rep_order(net, rep)
        L.append(f"let costs: [{CT}] = {arr(net.cost)}")
        costc = capacity_closure(rep, "costs")
        if kind == "mcf":
            res, uniq = verify_mcf(cid, net)
            sup = mcf_supply(net)
            L.append(f"let supplies: [{CT}] = {arr(sup)}")
            supc = "{ supplies[$0] }" if index_form(rep) else "{ supplies[vertexList.firstIndex(of: $0)!] }"
            if not index_form(rep):
                L.insert(0, f"let vertexList = {vlist(net)}")
            L.append(f"let result = graph.minimumCostFlow(supply: {supc}, capacity: {cap}, cost: {costc})")
            if res is None:
                L.append("#expect(result == nil)")
                return L
            cost, f = res
            value = sum(x for x in sup if x > 0)
            L.append("let flowResult = try #require(result)")
        else:
            value, cost, f, uniq = verify_mcmf(cid, net, si, ti)
            assert uniq, cid
            sa, ta = vertex_arg(net, rep, si), vertex_arg(net, rep, ti)
            L.append(f"let flowResult = graph.minimumCostMaximumFlow(from: {sa}, to: {ta}, capacity: {cap}, cost: {costc})")
        L += [f"#expect(flowResult.cost == {cost})", f"#expect(flowResult.value == {value})"]
        pos = "positionOfEdge[$0]" if index_form(rep) else "$0"
        if uniq:
            L.append(f"#expect(pairs.indices.map {{ flowResult.flow(ofEdgeAt: {pos}) }} == {arr(f)} as [{CT}])")
        else:
            L += ["// One of several optima: capacity, conservation and the potentials' certificate, by catalog edge.",
                  f"let flows = pairs.indices.map {{ flowResult.flow(ofEdgeAt: {pos}) }}",
                  "var balance = [Int](repeating: 0, count: supplies.count)",
                  "for (k, (a, b)) in pairs.enumerated() {",
                  "    #expect(flows[k] >= 0 && flows[k] <= capacities[k])",
                  ("    let ia = a, ib = b" if index_form(rep) else "    let ia = vertexList.firstIndex(of: a)!, ib = vertexList.firstIndex(of: b)!"),
                  "    balance[ia] += Int(flows[k])",
                  "    balance[ib] -= Int(flows[k])",
                  "    let reduced = Int(costs[k]) + Int(flowResult.potential(of: a)) - Int(flowResult.potential(of: b))",
                  "    if flows[k] < capacities[k] { #expect(reduced >= 0) }",
                  "    if flows[k] > 0 { #expect(reduced <= 0) }",
                  "}",
                  "#expect(balance == supplies.map { Int($0) })"]
        del order
        return L
    if kind == "paths":
        k = verify_paths(cid, net, group, si, ti)
        fn = "edgeDisjointPaths" if group == "EdgeDisjointPaths" else "vertexDisjointPaths"
        sa, ta = vertex_arg(net, rep, si), vertex_arg(net, rep, ti)
        L += [f"let paths = graph.{fn}(from: {sa}, to: {ta})",
              f"#expect(paths.count == {k})",
              f"#expect(paths.allSatisfy {{ $0.vertices.first == {sa} && $0.vertices.last == {ta} }})"]
        if group == "EdgeDisjointPaths":
            L.append("#expect(Set(paths.flatMap(\\.edges)).count == paths.reduce(0) { $0 + $1.edges.count })")
        else:
            L.append("#expect(Set(paths.flatMap { $0.vertices.dropFirst().dropLast() }).count == paths.reduce(0) { $0 + $1.vertices.count - 2 })")
        return L
    if kind == "conn":
        v, csi, cti = verify_conn(cid, net, group, call)
        if csi is None:
            if group == "VertexConnectivity":
                L.append(f"#expect(graph.vertexConnectivity() == {v})")
            elif group == "EdgeConnectivity":
                L.append(f"#expect(graph.edgeConnectivity() == {v})")
            else:
                L.append(f"#expect(graph.minimumVertexCut() == {rep_side(net, rep, v)})")
            return L
        sa, ta = vertex_arg(net, rep, csi), vertex_arg(net, rep, cti)
        if group == "VertexConnectivity":
            L.append(f"#expect(graph.vertexConnectivity(from: {sa}, to: {ta}) == {v})")
        elif group == "EdgeConnectivity":
            L.append(f"#expect(graph.edgeConnectivity(from: {sa}, to: {ta}) == {v})")
        else:
            L.append(f"#expect(graph.minimumVertexCut(from: {sa}, to: {ta}) == {'nil' if v is None else rep_side(net, rep, v)})")
        return L
    raise ValueError(kind)


def rep_test(cid, kind, group, net, si=None, ti=None, call=None):
    rs = reps(net)
    names = ", ".join(REP_NAMES[r] for r in rs)
    t = esc(f"{cid} {CELLS[cid][2]}, on {names}")
    body = [comment_input(cid)]
    if kind not in ("conn", "paths"):
        body += [pairs_line(net), caps_line(net)]
    else:
        body += [pairs_line(net)]
    needs_throw = False
    for r in rs:
        block = unused_cleanup(rep_block(cid, kind, group, net, r, si, ti, call))
        if any("try #require" in l for l in block):
            needs_throw = True
        body += [f"do {{ // {REP_NAMES[r]}"] + indent(block, 4) + ["}"]
    if kind == "conn":
        pass
    return emit_test(cid, t, body, throws=needs_throw)


# ---------------------------------------------------------------------------------------------
# Traps
# ---------------------------------------------------------------------------------------------

ONE = "AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])"
TRAPS = {
    "FL-213": (ONE, "_ = graph.maximumFlow(from: 0, to: 0, capacity: { _ in 5 })"),
    "FL-214": (ONE, "_ = graph.edmondsKarpMaximumFlow(from: 0, to: 0, capacity: { _ in 5 })"),
    "FL-215": (ONE, "_ = graph.dinicMaximumFlow(from: 0, to: 0, capacity: { _ in 5 })"),
    "FL-216": (ONE, "_ = graph.maximumFlowValue(from: 0, to: 0, capacity: { _ in 5 })"),
    "FL-217": (ONE, "_ = graph.minimumCut(from: 0, to: 0, capacity: { _ in 5 })"),
    "FL-218": (ONE, "_ = graph.maximumFlow(from: 7, to: 1, capacity: { _ in 5 })"),
    "FL-219": (ONE, "_ = graph.maximumFlow(from: 0, to: 7, capacity: { _ in 5 })"),
    "FL-220": (ONE, "_ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in -1 })"),
    "FL-221": ("AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])",
               "let capacities = [1, -1]\n_ = graph.maximumFlow(from: 0, to: 1, capacity: { capacities[$0] })"),
    "FL-222": (ONE, "_ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in Double.nan })"),
    "FL-223": (ONE, "_ = graph.maximumFlow(from: 0, to: 1, capacity: { _ in Double.infinity })"),
    "FL-224": ("AdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])",
               "let capacities: [Int8] = [100, 100, 50, 50]\n_ = graph.maximumFlow(from: 0, to: 3, capacity: { capacities[$0] })"),
    "FL-225": ("DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])",
               "let capacities = [Int.max, 1]\n_ = graph.maximumFlowValue(from: 0, to: 1, capacity: { capacities[$0] })"),
    "FL-226": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 2)])",
               "let capacities: [Int8] = [100, 28]\n_ = graph.maximumFlow(from: 0, to: 2, capacity: { capacities[$0] })"),
    "FL-249": ("UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
               "_ = graph.minimumCut(capacity: { _ in -1 })"),
    "FL-274": ("UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
               "_ = graph.gomoryHuTree(capacity: { _ in -2 })"),
    "FL-306": (ONE, "_ = graph.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in -1 }, cost: { _ in 1 })"),
    "FL-307": (ONE, "let supplies: [Int8] = [1, -1]\nlet capacities: [Int8] = [100]\nlet costs: [Int8] = [2]\n"
                    "_ = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[$0] }, cost: { costs[$0] })"),
    "FL-319": (ONE, "_ = graph.minimumCostMaximumFlow(from: 0, to: 0, capacity: { _ in 1 }, cost: { _ in 1 })"),
    "FL-485": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.vertexConnectivity(from: 0, to: 0)"),
    "FL-486": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.minimumVertexCut(from: 0, to: 0)"),
    "FL-487": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.edgeConnectivity(from: 0, to: 0)"),
    "FL-524": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.edgeDisjointPaths(from: 0, to: 0)"),
    "FL-525": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.vertexDisjointPaths(from: 0, to: 0)"),
}


def trap_test(cid):
    parts = CELLS[cid]
    why = re.sub(r"^trap: ", "", parts[5])
    graph, call = TRAPS[cid]
    body = [comment_input(cid), "await #expect(processExitsWith: .failure) {", f"    let graph = {graph}"]
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
    out = ["Flows", "GraphProtocols", "Testing"]
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


COMMON = ("Directed rows are `AdjacencyList`, or `DirectedPseudograph` when an edge repeats; undirected rows "
          "`UndirectedAdjacencyList`, or `Pseudograph` with parallel edges; each built by inserting the row's "
          "vertices, then its edges in order, so positions are the catalog's. In-test checks number vertices by "
          "their index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with "
          "ref.py's models; see README.md.")

ROWS = []
for i in range(TOTAL):
    cid = cid_of(i)
    kind, args, kwargs = RECORDS[i]
    group = CELLS[cid][1]
    call = CELLS[cid][4].strip("`")
    ROWS.append((cid, kind, group, args, kwargs, call))


def row_net_terms(kind, args, call):
    if kind == "flow":
        net = args[1]
        return net, net.index[args[2]], net.index[args[3]]
    if kind == "mcmf":
        net = args[1]
        return net, net.index[args[2]], net.index[args[3]]
    if kind == "paths":
        net = args[1]
        return net, net.index[args[2]], net.index[args[3]]
    if kind in ("global", "gh", "mcf", "conn"):
        return args[1], None, None
    raise ValueError(kind)


def row_body(cid, kind, group, args, call):
    net, si, ti = row_net_terms(kind, args, call)
    if kind == "flow":
        return body_flow(cid, group, net, si, ti)
    if kind == "global":
        return body_global(cid, net)
    if kind == "gh":
        return body_gh(cid, net)
    if kind == "mcf":
        return body_mcf(cid, net)
    if kind == "mcmf":
        return body_mcmf(cid, net, si, ti)
    if kind == "conn":
        return body_conn(cid, net, group, call)
    if kind == "paths":
        return body_paths(cid, net, group, si, ti)
    raise ValueError(kind)


FILES = [
    ("MaximumFlowTests.swift", lambda k, g: g == "MaximumFlow", "maximumFlow(from:to:capacity:)", "MaximumFlowTests",
     "`maximumFlow(from:to:capacity:)` (catalog §MaximumFlow): the value exactly; the flow is any maximum flow, "
     "checked here for capacity and conservation; the canonical minimum cut exactly, and equal to the vertices "
     "that still reach the sink in this flow's residual network (found here); its edges every edge from the "
     "source side to the sink side; its value the flow's; `capacity` called once per non-loop edge, in order."),
    ("EdmondsKarpTests.swift", lambda k, g: g == "EdmondsKarp", "edmondsKarpMaximumFlow(from:to:capacity:)", "EdmondsKarpTests",
     "`edmondsKarpMaximumFlow(from:to:capacity:)` (catalog §EdmondsKarp): the per-edge flow exactly, pinned by "
     "the documented procedure (residual rows in edge-position order, breadth-first search stopped at the sink, "
     "bottleneck augmentation); capacity and conservation; the canonical cut, from this flow's residual network too."),
    ("DinicTests.swift", lambda k, g: g == "Dinic", "dinicMaximumFlow(from:to:capacity:)", "DinicTests",
     "`dinicMaximumFlow(from:to:capacity:)` (catalog §Dinic): the value and the canonical cut exactly; the flow "
     "checked here for capacity and conservation, and its residual network for the cut."),
    ("MaximumFlowValueTests.swift", lambda k, g: g == "MaximumFlowValue", "maximumFlowValue(from:to:capacity:)", "MaximumFlowValueTests",
     "`maximumFlowValue(from:to:capacity:)` (catalog §MaximumFlowValue): the value exactly (within 1e-12 on "
     "rows whose capacities are not dyadic), equal to `maximumFlow`'s and the minimum cut's."),
    ("MinimumCutTests.swift", lambda k, g: g == "MinimumCut", "minimumCut(from:to:capacity:)", "MinimumCutTests",
     "`minimumCut(from:to:capacity:)` (catalog §MinimumCut): the canonical cut exactly (the least sink side); "
     "its edges every edge from the source side to the sink side; its value their capacity; by brute force over "
     "every s–t cut, the least value and the least sink side among the minimum cuts; the same `Cut` as every "
     "maximum flow's."),
    ("GlobalMinimumCutTests.swift", lambda k, g: g in ("GlobalMinimumCut", "DirectedGlobalMinimumCut"), "minimumCut(capacity:)", "GlobalMinimumCutTests",
     "`minimumCut(capacity:)` (catalog §GlobalMinimumCut, §DirectedGlobalMinimumCut): Nagamochi–Ibaraki on "
     "`Graph`, Hao–Orlin on `DirectedGraph`; the value exactly; the sides exactly where the catalog pins them "
     "(the only minimum cut, or the first vertex's component when the positive edges leave several); nil below "
     "two vertices; the cut's edges and value checked here from its sides, the first vertex on the source side "
     "of an undirected cut; by brute force the least cut over every nonempty proper vertex set; the same cut on "
     "a second call."),
    ("GomoryHuTreeTests.swift", lambda k, g: g == "GomoryHu", "gomoryHuTree(capacity:)", "GomoryHuTreeTests",
     "`gomoryHuTree(capacity:)` (catalog §GomoryHu): Gusfield's tree with the canonical cut, NetworkX's tree "
     "edge for edge; the tree edge at position k joins the vertex at index k + 1 and its parent; for every "
     "ordered pair, `minimumCutValue(between:and:)` is the least capacity on the tree path and the least cut by "
     "brute force, and `minimumCut(between:and:)` is the split at the least tree edge nearest the first vertex, "
     "with the graph's crossing edges."),
    ("MinimumCostFlowTests.swift", lambda k, g: g == "MinimumCostFlow", "minimumCostFlow(supply:capacity:cost:)", "MinimumCostFlowTests",
     "`minimumCostFlow(supply:capacity:cost:)` (catalog §MinimumCostFlow): the least cost exactly; the flow "
     "exactly where it is the only optimum; feasibility, the self-loop rule and optimality by the potentials' "
     "reduced costs (complementary slackness), checked here; nil rows have an infeasibility witness found here "
     "(unbalanced supplies, or a set supplying more than its out-edges carry); the closures' calls."),
    ("MinimumCostMaximumFlowTests.swift", lambda k, g: g == "MinimumCostMaximumFlow", "minimumCostMaximumFlow(from:to:capacity:cost:)", "MinimumCostMaximumFlowTests",
     "`minimumCostMaximumFlow(from:to:capacity:cost:)` (catalog §MinimumCostMaximumFlow): the maximum flow value "
     "and the least cost among maximum flows, circulations included; the flow where unique; feasibility and the "
     "potentials' certificate, checked here."),
    ("EdgeConnectivityTests.swift", lambda k, g: g == "EdgeConnectivity", "edgeConnectivity", "EdgeConnectivityTests",
     "`edgeConnectivity()` and `edgeConnectivity(from:to:)` (catalog §EdgeConnectivity): exact; parallel edges "
     "count, self-loops never; equal to the unit-capacity global cut and maximum flow; by brute force the fewest "
     "edges leaving a vertex set."),
    ("VertexConnectivityTests.swift", lambda k, g: g == "VertexConnectivity", "vertexConnectivity", "VertexConnectivityTests",
     "`vertexConnectivity()` and `vertexConnectivity(from:to:)` (catalog §VertexConnectivity): exact, on the "
     "simple graph; by brute force the fewest vertices whose removal disconnects (κ(G)), or separates s from t "
     "plus one for an edge from s to t (κ(s, t)); κ ≤ λ."),
    ("DisjointPathsTests.swift", lambda k, g: g in ("EdgeDisjointPaths", "VertexDisjointPaths"), "Disjoint paths", "DisjointPathsTests",
     "`edgeDisjointPaths(from:to:)` and `vertexDisjointPaths(from:to:)` (catalog §EdgeDisjointPaths, "
     "§VertexDisjointPaths): as many paths as λ(s, t) and κ(s, t) (an edge from s to t one path); each a path "
     "from s to t along its edges, repeating no vertex, checked here; no edge, or no inner vertex, in two of "
     "them. Which paths is not pinned."),
    ("MinimumVertexCutTests.swift", lambda k, g: g == "MinimumVertexCut", "minimumVertexCut", "MinimumVertexCutTests",
     "`minimumVertexCut()` and `minimumVertexCut(from:to:)` (catalog §MinimumVertexCut): the documented cut "
     "exactly (Even's pairs for the global one, the cut nearest the target for the local one); its size the "
     "connectivity; removing it disconnects, or separates s from t; nil when an edge goes from s to t."),
]


COUNTS = {}
for fname_, pred, suite, struct, intro in FILES:
    body = []
    count = 0
    for cid, kind, group, args, kwargs, call in ROWS:
        if kind != "trap" and pred(kind, group):
            lines = unused_cleanup(row_body(cid, kind, group, args, call))
            throws = any("try #require" in l for l in lines)
            body += emit_test(cid, title(cid), lines, throws=throws)
            count += 1
    L = header(wrap(intro + " " + COMMON), used_imports(body), suite, struct) + body
    write(fname_, L)
    COUNTS[fname_] = count

# Traps
body = []
for cid, kind, group, args, kwargs, call in ROWS:
    if kind == "trap":
        body += trap_test(cid)
EXTRA = open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n")
body += EXTRA
intro = ("Preconditions, as exit tests (catalog §Preconditions): the source as the sink in every s–t entry point; "
         "a terminal that is not a vertex; a negative capacity, also off every path; a NaN or infinite capacity; "
         "the capacities at the source summing past the type's maximum, though the value would fit; negative "
         "capacities for the global cut, Gomory–Hu and minimum-cost flow; a cost total past the cost type. Then "
         "the preconditions the catalog does not list (extra_traps.swift): each on the other entry points and "
         "kinds of graph, a terminal not in a graph without indices, `GomoryHuTree.minimumCut(between:and:)` "
         "with u = v, a floating sum that overflows to infinity. Each exit test "
         "builds its inputs inside the closure. Generated from cases.md by swiftgen.py; see README.md.")
L = header(wrap(intro), sorted(set(used_imports(body)) | {"AdjacencyListModule", "Multigraphs"}, key=str.lower),
           "Flows preconditions", "FlowsPreconditionTests", tags=".precondition", conformers=True, lines=body) + body
write("FlowsPreconditionTests.swift", L)
COUNTS["FlowsPreconditionTests.swift"] = sum(1 for l in body if l.strip().startswith("@Test("))

# Representations
REP_FILES = [
    ("MaximumFlowRepresentationTests.swift", ("MaximumFlow",), "maximumFlow on every representation", "MaximumFlowRepresentationTests"),
    ("EdmondsKarpRepresentationTests.swift", ("EdmondsKarp",), "edmondsKarpMaximumFlow on every representation", "EdmondsKarpRepresentationTests"),
    ("DinicRepresentationTests.swift", ("Dinic",), "dinicMaximumFlow on every representation", "DinicRepresentationTests"),
    ("MaximumFlowValueRepresentationTests.swift", ("MaximumFlowValue",), "maximumFlowValue on every representation", "MaximumFlowValueRepresentationTests"),
    ("MinimumCutRepresentationTests.swift", ("MinimumCut",), "minimumCut(from:to:capacity:) on every representation", "MinimumCutRepresentationTests"),
    ("GlobalMinimumCutRepresentationTests.swift", ("GlobalMinimumCut", "DirectedGlobalMinimumCut"), "minimumCut(capacity:) on every representation", "GlobalMinimumCutRepresentationTests"),
    ("GomoryHuTreeRepresentationTests.swift", ("GomoryHu",), "gomoryHuTree on every representation", "GomoryHuTreeRepresentationTests"),
    ("MinimumCostFlowRepresentationTests.swift", ("MinimumCostFlow", "MinimumCostMaximumFlow"), "Minimum-cost flows on every representation", "MinimumCostFlowRepresentationTests"),
    ("EdgeConnectivityRepresentationTests.swift", ("EdgeConnectivity",), "edgeConnectivity on every representation", "EdgeConnectivityRepresentationTests"),
    ("VertexConnectivityRepresentationTests.swift", ("VertexConnectivity",), "vertexConnectivity on every representation", "VertexConnectivityRepresentationTests"),
    ("MinimumVertexCutRepresentationTests.swift", ("MinimumVertexCut",), "minimumVertexCut on every representation", "MinimumVertexCutRepresentationTests"),
    ("DisjointPathsRepresentationTests.swift", ("EdgeDisjointPaths", "VertexDisjointPaths"), "Disjoint paths on every representation", "DisjointPathsRepresentationTests"),
]
REP_INTRO = ("The catalog's rows again on other representations: directed rows on `DirectedPseudograph` (or "
             "`ReferenceDirectedMultigraph` for rows already on it), a file-private conformer with no vertex or "
             "edge indices, and, without a repeated edge, `CompressedSparseRow` and `AdjacencyMatrix` on the vertex "
             "indices; undirected rows on `Pseudograph` (or `ReferencePseudograph`), the conformer, and, without a "
             "repeated edge, `AdjacencyList.undirected` (each edge an arc as written) and `AdjacencyMatrix.undirected`. "
             "CompressedSparseRow and AdjacencyMatrix number edges by row-major cell, so there each catalog edge's "
             "position is looked up, a cut's edges are listed in that order, and Edmonds–Karp's flow (which follows "
             "positions) was recomputed by swiftgen.py with ref.py's model on those positions. Everything else is "
             "the catalog's. See README.md.")
for fname_, groups, suite, struct in REP_FILES:
    body = []
    count = 0
    for cid, kind, group, args, kwargs, call in ROWS:
        if kind != "trap" and group in groups:
            net, si, ti = row_net_terms(kind, args, call)
            body += rep_test(cid, kind, group, net, si, ti, call)
            count += 1
    L = header(wrap(REP_INTRO), used_imports(body), suite, struct, conformers=True, lines=body) + body
    write(fname_, L)
    COUNTS[fname_] = count

for k, v in COUNTS.items():
    print(f"{k}: {v}")
print("total", sum(COUNTS.values()))
