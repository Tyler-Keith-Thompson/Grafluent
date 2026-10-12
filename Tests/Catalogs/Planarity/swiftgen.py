"""Writes the catalog-row test files of Tests/PlanarityTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 \
        python3 Tests/Catalogs/Planarity/swiftgen.py [--phase2] [OUT_DIR]
    # default OUT_DIR: Tests/PlanarityTests

First checks that ref.py's model reproduces cases.md byte for byte. Then re-evaluates every row with
ref.py's functions (the enumeration oracle, the NetworkX-certified embedding, Whitney's theorem, the
Kuratowski enumeration), asserts that each value it writes matches the catalog cell, and writes one
@Test per phase-1 row. `--phase2` also writes the dual-graph rows (PL-178 – PL-188) to
DualGraphTests.swift; without it that file is not written, because `dualGraph()` is phase 2.

Every planar row checks the embedding against the definitions in api.md, written out in the test:
each clockwise order is a permutation of the vertex's incident edges that starts at the first one,
the three clockwise accessors and their `safe:` spellings agree, `faces` is exactly the orbits of
the face permutation in the documented order, `face(from:alongEdgeAt:)` is the orbit from that
half-edge and `rightFace(from:alongEdgeAt:)` its position in `faces`, `faceCount` is Euler's
count, and a second call returns the same embedding. Rows whose embedding is unique compare every
clockwise order (as a cyclic order) with the model's embedding or its mirror image, the same one at
every vertex. Every non-planar witness is checked to be a
subdivision of its kind made of the graph's edges, with its branch vertices and internally disjoint
paths in the documented order; a unique witness is pinned exactly. Graphs are `Pseudograph<Int>`
(Multigraphs) with the row's vertices listed, so positions are the catalog's; `D:` rows are
`AdjacencyList<Int>(...).undirected`. Trap rows go to the precondition file, with the hand-written
exit tests in extra_traps.swift.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.chdir(HERE)
import ref  # noqa: E402

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
PHASE2 = "--phase2" in sys.argv
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.normpath(os.path.join(HERE, "..", "..", "PlanarityTests"))

# ---------------------------------------------------------------------------------------------
# Catalog check
# ---------------------------------------------------------------------------------------------
ref.define()
ref.number_rows()
ref.compute()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
ROWS = {int(r[0][3:]): r for r in ref.ROWS}
N = len(ROWS)
assert N == 188
PHASE1 = [n for n in ROWS if not ROWS[n][1].startswith("Phase 2")]
assert PHASE1 == list(range(1, 178))


def group(n): return ROWS[n][1]
def title(n): return ROWS[n][2]
def gcell(n): return ROWS[n][3]
def op(n): return ROWS[n][4]
def cell(n): return ROWS[n][6]
def is_trap(n): return cell(n).startswith("**trap**")


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------
def ints(xs):
    xs = list(xs)
    return "[" + ", ".join(str(x) for x in xs) + "]" if xs else "[] as [Int]"


def int_rows(rows):
    return "[" + ", ".join(ints(r) if r else "[]" for r in rows) + "]" if rows else "[] as [[Int]]"


def wrap(prefix, items, ind, width=110, close="]"):
    """`prefix` + items joined by ", " in lines of at most `width` characters."""
    lines, cur = [], ind + prefix
    for i, it in enumerate(items):
        piece = it + (", " if i + 1 < len(items) else "")
        if len(cur) + len(piece) > width and cur.strip() != prefix.strip():
            lines.append(cur.rstrip())
            cur = ind + "    "
        cur += piece
    lines.append(cur + close)
    return lines


def construct(g, ind, checks=True):
    """The row's graph: `graph`, with the row's vertices listed, so positions are the catalog's."""
    vs = g.vertices
    vlit = "0 ..< %d" % g.n if vs == list(range(g.n)) and g.n > 0 else ints(vs)
    names = [(vs[a], vs[b]) for a, b in g.edges]
    out = []
    if g.directed:
        assert g.m <= 40
        es = ["DirectedEdge(from: %d, to: %d)" % e for e in names]
        out += wrap("let graph = AdjacencyList<Int>(vertices: %s, edges: [" % vlit, es, ind, close="]).undirected")
    elif g.m <= 30:
        es = ["UndirectedEdge(%d, %d)" % e for e in names]
        if es:
            out += wrap("let graph = Pseudograph<Int>(vertices: %s, edges: [" % vlit, es, ind, close="])")
        else:
            out.append(ind + "let graph = Pseudograph<Int>(vertices: %s, edges: [] as [UndirectedEdge<Int>])" % vlit)
    else:
        out.append(ind + "// The edges as flat (u, v) pairs in position order.")
        out += wrap("let ends: [Int] = [", ["%d, %d" % e for e in names], ind)
        out.append(ind + "let graph = Pseudograph<Int>(vertices: %s, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })" % vlit)
    if not checks:
        return out
    out.append(ind + "#expect(graph.vertexCount == %d && graph.edgeCount == %d)" % (g.n, g.m))
    if g.m <= 30:
        out.append(ind + "#expect(Array(graph.vertices) == %s)" % ints(vs))
    return out


def cyclic_min(row):
    if not row:
        return []
    return min(row[i:] + row[:i] for i in range(len(row)))


def rotation_positions(rot):
    """A half-edge rotation as positions per vertex, each row from its least rotation."""
    return [cyclic_min([h >> 1 for h in r]) for r in rot]


# ---------------------------------------------------------------------------------------------
# The embedding written out against the definitions
# ---------------------------------------------------------------------------------------------
def embedding_block(g, ind, face_count, lengths=None, mirror=None, sample=1):
    """Lines checking `embedding` (already unwrapped) on `graph`. mirror: (A, B) rotations as least
    cyclic rotations of positions, for a unique embedding."""
    L = []
    a = L.append
    a(ind + "let vertexList = Array(graph.vertices)")
    a(ind + "let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })")
    a(ind + "// Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;")
    a(ind + "// the neighbours, the index-space neighbours and the safe: spellings say the same.")
    a(ind + "var rotation: [[Int]] = []")
    a(ind + "for (i, v) in vertexList.enumerated() {")
    a(ind + "    let row = Array(embedding.clockwiseIncidentEdges(of: v))")
    a(ind + "    let incident = Array(graph.incidentEdges(of: v))")
    a(ind + "    let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }")
    a(ind + "    #expect(row.sorted() == incident.sorted(), \"the clockwise order at \\(v) is not its incident edges\")")
    a(ind + "    #expect(row.first == incident.first, \"the clockwise order at \\(v) does not start at its first edge\")")
    a(ind + "    #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)")
    a(ind + "    #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)")
    a(ind + "    #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)")
    a(ind + "    #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })")
    a(ind + "    rotation.append(row)")
    a(ind + "}")
    a(ind + "// Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far")
    a(ind + "// vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the")
    a(ind + "// twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in")
    a(ind + "// order, each from that half-edge's tail.")
    a(ind + "var slots: [Int: [(Int, Int)]] = [:]")
    a(ind + "for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }")
    a(ind + "#expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)")
    a(ind + "var seen = rotation.map { [Bool](repeating: false, count: $0.count) }")
    a(ind + "var orbits: [(vertices: [Int], edges: [Int])] = []")
    a(ind + "var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }")
    a(ind + "for i in rotation.indices {")
    a(ind + "    for s in rotation[i].indices where !seen[i][s] {")
    a(ind + "        var vertices: [Int] = [], edges: [Int] = []")
    a(ind + "        var (x, y) = (i, s)")
    a(ind + "        repeat {")
    a(ind + "            seen[x][y] = true")
    a(ind + "            faceOf[x][y] = orbits.count")
    a(ind + "            vertices.append(vertexList[x])")
    a(ind + "            edges.append(rotation[x][y])")
    a(ind + "            let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!")
    a(ind + "            (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)")
    a(ind + "        } while (x, y) != (i, s)")
    a(ind + "        orbits.append((vertices + [vertexList[i]], edges))")
    a(ind + "    }")
    a(ind + "}")
    a(ind + "#expect(embedding.faces.map(\\.vertices) == orbits.map(\\.vertices))")
    a(ind + "#expect(embedding.faces.map(\\.edges) == orbits.map(\\.edges))")
    a(ind + "// Euler's formula per component with an edge: Σ (2 − n_c + m_c).")
    a(ind + "#expect(embedding.faceCount == %d && orbits.count == %d)" % (face_count, face_count))
    a(ind + "// face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).")
    loop = "for i in rotation.indices {"
    a(ind + ("var visited = 0" if sample > 1 else "// Every half-edge."))
    a(ind + loop)
    a(ind + "    for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {")
    if sample > 1:
        a(ind + "        visited += 1")
        a(ind + "        if visited %% %d != 0 { continue }" % sample)
    a(ind + "        var vertices: [Int] = [], edges: [Int] = []")
    a(ind + "        var (x, y) = (i, s)")
    a(ind + "        repeat {")
    a(ind + "            vertices.append(vertexList[x])")
    a(ind + "            edges.append(rotation[x][y])")
    a(ind + "            let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!")
    a(ind + "            (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)")
    a(ind + "        } while (x, y) != (i, s)")
    a(ind + "        let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])")
    a(ind + "        #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)")
    a(ind + "        #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])")
    a(ind + "    }")
    a(ind + "}")
    if lengths is not None:
        a(ind + "#expect(embedding.faces.map(\\.length).sorted(by: >) == %s)" % ints(lengths))
    if mirror is not None:
        A, B = mirror
        a(ind + "// Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at")
        a(ind + "// every vertex at once, its mirror image's.")
        a(ind + "let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }")
        if A == B:
            L.extend(wrap("#expect(cyclic == [", [ints(r) if r else "[]" for r in A], ind, close="])"))
        else:
            L.extend(wrap("let rotationA: [[Int]] = [", [ints(r) if r else "[]" for r in A], ind))
            L.extend(wrap("let rotationB: [[Int]] = [", [ints(r) if r else "[]" for r in B], ind))
            a(ind + "let isA = cyclic == rotationA")
            a(ind + "#expect(isA || cyclic == rotationB)")
    a(ind + "// A second call gives the same embedding.")
    a(ind + "let again = try #require(graph.planarEmbedding())")
    a(ind + "#expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)")
    a(ind + "#expect(again.faces.map(\\.vertices) == embedding.faces.map(\\.vertices) && again.faces.map(\\.edges) == embedding.faces.map(\\.edges))")
    a(ind + "#expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)")
    a(ind + "#expect(!embedding.description.isEmpty)")
    return L


# ---------------------------------------------------------------------------------------------
# A Kuratowski subgraph written out against the definition
# ---------------------------------------------------------------------------------------------
def witness_block(g, ind, kind=None, pinned=None):
    L = []
    a = L.append
    a(ind + "let witness = try #require(graph.findKuratowskiSubgraph())")
    a(ind + "let vertexList = Array(graph.vertices)")
    a(ind + "let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })")
    a(ind + "// Edges: ascending positions of the graph, no loop, no two copies of one pair.")
    a(ind + "#expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)")
    a(ind + "#expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })")
    a(ind + "#expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)")
    a(ind + "// Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,")
    a(ind + "// each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.")
    a(ind + "let branch = witness.branchVertices")
    a(ind + "let order = branch.map { indexOf[$0]! }")
    a(ind + "var pairs: [(Int, Int)] = []")
    a(ind + "switch witness.kind {")
    a(ind + "case .k5:")
    a(ind + "    #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)")
    a(ind + "    for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }")
    a(ind + "case .k33:")
    a(ind + "    #expect(branch.count == 6 && witness.paths.count == 9)")
    a(ind + "    #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())")
    a(ind + "    for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }")
    a(ind + "}")
    a(ind + "#expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })")
    a(ind + "// Each path joins its pair through the graph's edges; inner vertices are not branch vertices and")
    a(ind + "// belong to one path only; the paths use every witness edge once.")
    a(ind + "var inner = Set<Int>()")
    a(ind + "var used: [Int] = []")
    a(ind + "for (path, (i, j)) in zip(witness.paths, pairs) {")
    a(ind + "    #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], \"path \\(i)–\\(j)\")")
    a(ind + "    #expect(path.edges.count == path.vertices.count - 1)")
    a(ind + "    for (k, p) in path.edges.enumerated() {")
    a(ind + "        #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), \"path \\(i)–\\(j) step \\(k)\")")
    a(ind + "    }")
    a(ind + "    for v in path.vertices.dropFirst().dropLast() {")
    a(ind + "        #expect(!branch.contains(v) && inner.insert(v).inserted, \"inner vertex \\(v)\")")
    a(ind + "    }")
    a(ind + "    used += path.edges")
    a(ind + "}")
    a(ind + "#expect(used.sorted() == witness.edges)")
    if kind is not None:
        a(ind + "#expect(witness.kind == %s)" % kind)
    if pinned is not None:
        es, bs = pinned
        L.extend(wrap("#expect(witness.edges == [", [str(x) for x in es], ind, close="])"))
        a(ind + "#expect(witness.branchVertices == %s)" % ints(bs))
    a(ind + "// A second call gives the same witness.")
    a(ind + "let again = try #require(graph.findKuratowskiSubgraph())")
    a(ind + "#expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)")
    a(ind + "#expect(!graph.isPlanar && graph.planarEmbedding() == nil)")
    a(ind + "#expect(!witness.description.isEmpty)")
    return L


# ---------------------------------------------------------------------------------------------
# Rows
# ---------------------------------------------------------------------------------------------
def expected_face_count(text):
    return int(re.match(r"faceCount (\d+)", text).group(1))


def lengths_of(text):
    m = re.search(r"face lengths \{([^}]*)\}", text)
    if not m:
        return None
    out = []
    for part in m.group(1).split(", "):
        if "×" in part:
            k, c = part.split("×")
            out += [int(k)] * int(c)
        else:
            out.append(int(part))
    return sorted(out, reverse=True)


def info(g):
    planar, one, allr, unique = ref.embedding_info(g)
    return planar, one, unique


def header(n, extra=""):
    return ['    @Test("%s %s: %s"%s)' % (ROWS[n][0], title(n).replace('"', '\\"'), op(n).replace('"', '\\"'), extra)]


def describe(n):
    return "        // %s; %s → %s" % (gcell(n), op(n), cell(n))


def row_test(n):
    g = ref.parse_graph(gcell(n))
    o = op(n)
    if o.startswith("undirected."):
        o = o[len("undirected."):]
    c = cell(n)
    assert ref.evaluate(gcell(n), op(n), ROWS[n][5]) == c
    fname = "pl%03d" % n
    scale = group(n) == "Scale"
    big = g.m > 300
    L = header(n, ", .timeLimit(.minutes(1))" if scale else "")
    L.append("    func %s() {" % fname)
    L.append(describe(n))
    ind = "        "
    L += construct(g, ind)
    planar, one, unique = info(g)
    if o in ("isPlanar", "isOuterplanar"):
        val = c == "true"
        L.append(ind + "#expect(graph.%s == %s)" % (o, "true" if val else "false"))
        if o == "isPlanar":
            assert val == planar
            L.append(ind + "// The witnesses agree with the answer.")
            L.append(ind + "#expect((graph.planarEmbedding() != nil) == %s)" % ("true" if val else "false"))
            L.append(ind + "#expect((graph.findKuratowskiSubgraph() == nil) == %s)" % ("true" if val else "false"))
        else:
            if val:
                assert planar
                L.append(ind + "#expect(graph.isPlanar)  // outerplanar graphs are planar")
            L.append(ind + "#expect(graph.isOuterplanar == %s)  // asking again" % ("true" if val else "false"))
    elif o == "findKuratowskiSubgraph()":
        if c == "nil":
            assert planar
            L.append(ind + "#expect(graph.findKuratowskiSubgraph() == nil)")
            L.append(ind + "#expect(graph.isPlanar && graph.planarEmbedding() != nil)")
        else:
            assert not planar
            m = re.match(r"(K₅|K₃,₃): edges \[([^\]]*)\]; branch vertices \[([^\]]*)\]$", c)
            kind = pinned = None
            if m:
                kind = ".k5" if m.group(1) == "K₅" else ".k33"
                pinned = ([int(x) for x in m.group(2).split(", ")], [int(x) for x in m.group(3).split(", ")])
                kinds, allw = ref.possible_kinds(g)
                assert allw is not None and len(allw) == 1 and allw[0] == pinned[0]
            elif c.startswith("some K₅ subdivision"):
                kind = ".k5"
            elif c.startswith("some K₃,₃ subdivision"):
                kind = ".k33"
            else:
                assert c.startswith("some K₅ or K₃,₃ subdivision")
            L += witness_block(g, ind, kind, pinned)
    elif o == "planarEmbedding()" and c == "nil":
        assert not planar
        L.append(ind + "#expect(graph.planarEmbedding() == nil)")
        L.append(ind + "#expect(!graph.isPlanar && graph.findKuratowskiSubgraph() != nil)")
    else:
        assert planar
        L.append(ind + "let embedding = try #require(graph.planarEmbedding())")
        fc = g.euler_faces()
        lengths = None
        if o == "planarEmbedding()":
            assert expected_face_count(c) == fc
            lengths = lengths_of(c)
            assert ("unique up to mirror image" in c) == bool(unique and fc)
        mirror = None
        if unique and g.m:
            A, B = rotation_positions(one), rotation_positions(ref.mirror(one))
            mirror = (A, B)
        sample = 1 if g.m <= 300 else max(1, g.m // 150)
        L += embedding_block(g, ind, fc, lengths, mirror, sample)
        L += accessor_lines(g, o, c, one, mirror, ind)
    L.append("    }")
    if any("try " in line for line in L):
        L[len(header(n))] = "    func %s() throws {" % fname
    return L


def accessor_lines(g, o, c, one, mirror, ind):
    """The row's own accessor, pinned (A or B, matching the whole embedding)."""
    L = []
    if o in ("planarEmbedding()",):
        return L
    if o == "planarEmbedding()!.faceCount":
        L.append(ind + "#expect(embedding.faceCount == %s)" % c)
        return L
    if o == "planarEmbedding()!.faces":
        a, b = ref.face_set(g, one), ref.face_set(g, ref.mirror(one))
        names = lambda fs: [[g.vertices[v] for v in f] for f in fs]
        L.append(ind + "// Each face as a cycle of vertices from its least rotation, the faces sorted.")
        L.append(ind + "let cycles = embedding.faces.map { face -> [Int] in")
        L.append(ind + "    let cycle = Array(face.vertices.dropLast())")
        L.append(ind + "    return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []")
        L.append(ind + "}.sorted { $0.lexicographicallyPrecedes($1) }")
        if mirror[0] == mirror[1]:
            assert a == b
            L.append(ind + "#expect(cycles == %s)" % int_rows(names(a)))
        else:
            L.append(ind + "#expect(cycles == (isA ? %s : %s))" % (int_rows(names(a)), int_rows(names(b))))
        assert ref.fmt_faces(min(a, b), g) in c
        return L
    m = re.match(r"planarEmbedding\(\)!\.clockwise(Neighbors|IncidentEdges)\((of|safe): (-?\d+)\)", o)
    if m:
        what, label, x = m.group(1), m.group(2), int(m.group(3))
        call = "embedding.clockwise%s(%s: %d)" % (what, label, x)
        if c == "nil":
            L.append(ind + "#expect(%s == nil)" % call)
            return L
        v = g.vertices.index(x)

        def show(rot):
            row = [h for h in rot[v]]
            return [g.vertices[g.head(h)] for h in row] if what == "Neighbors" else [h >> 1 for h in row]
        A, B = show(one), show(ref.mirror(one))
        expr = "Array(%s)" % call if label == "of" else "%s.map { Array($0) }" % call
        if A == B:
            L.append(ind + "#expect(%s == %s)" % (expr, ints(A)))
            assert c == ref.fmt_list(A)
        else:
            L.append(ind + "#expect(%s == (isA ? %s : %s))" % (expr, ints(A), ints(B)))
            assert c == "%s or %s (mirror image)" % (ref.fmt_list(A), ref.fmt_list(B))
        return L
    m = re.match(r"planarEmbedding\(\)!\.face\(from: (-?\d+), alongEdgeAt: (\d+)\)", o)
    if m:
        x, p = int(m.group(1)), int(m.group(2))
        v = g.vertices.index(x)
        h = ref.half_edge_of(g, v, p)

        def show(rot):
            f = ref.face_from(g, [list(r) for r in rot], h)
            return [g.vertices[g.origin(y)] for y in f] + [x], [y >> 1 for y in f]
        A, B = show(one), show(ref.mirror(one))
        call = "embedding.face(from: %d, alongEdgeAt: %d)" % (x, p)
        if A == B:
            L.append(ind + "#expect(%s.vertices == %s && %s.edges == %s)" % (call, ints(A[0]), call, ints(A[1])))
        else:
            L.append(ind + "let face = %s" % call)
            L.append(ind + "#expect(face.vertices == (isA ? %s : %s))" % (ints(A[0]), ints(B[0])))
            L.append(ind + "#expect(face.edges == (isA ? %s : %s))" % (ints(A[1]), ints(B[1])))
        return L
    raise AssertionError(o)


def trap_test(n):
    """The trapping call in a child process; then the same setup without it, checked in-process."""
    g = ref.parse_graph(gcell(n))
    o = op(n)
    L = header(n)
    L.append("    func pl%03d() async throws {" % n)
    L.append(describe(n))
    call = "embedding." + o[len("planarEmbedding()!."):]
    L.append("        await #expect(processExitsWith: .failure) {")
    L += construct(g, "            ", checks=False)
    L.append("            let embedding = graph.planarEmbedding()!")
    L.append("            _ = %s" % call)
    L.append("        }")
    L.append("        // Without the call: the same setup answers.")
    L += construct(g, "        ")
    L.append("        let embedding = try #require(graph.planarEmbedding())")
    m = re.match(r"clockwiseNeighbors\(of: (-?\d+)\)", call[len("embedding."):])
    if m:
        L.append("        #expect(embedding.clockwiseNeighbors(safe: %s) == nil)" % m.group(1))
        L.append("        #expect(Array(embedding.clockwiseNeighbors(of: 0)).sorted() == [1, 2, 3])")
    else:
        m = re.match(r"face\(from: (-?\d+), alongEdgeAt: (\d+)\)", call[len("embedding."):])
        x, p = int(m.group(1)), int(m.group(2))
        u, w = g.edges[p]
        L.append("        // Edge %d joins %d and %d; from either end the call answers." % (p, g.vertices[u], g.vertices[w]))
        L.append("        #expect(embedding.face(from: %d, alongEdgeAt: %d).vertices.first == %d)" % (g.vertices[u], p, g.vertices[u]))
        L.append("        #expect(embedding.face(from: %d, alongEdgeAt: %d).vertices.first == %d)" % (g.vertices[w], p, g.vertices[w]))
        L.append("        #expect(Array(embedding.clockwiseIncidentEdges(of: %d)).contains(%d) == false)" % (x, p))
    L.append("    }")
    return L


def dual_test(n):
    g = ref.parse_graph(gcell(n))
    c = cell(n)
    assert ref.evaluate(gcell(n), op(n), ROWS[n][5]) == c
    m = re.match(r"(\d+) vert(?:ex|ices), (\d+) edges? \((\d+) loops?\); degrees \[([^\]]*)\]", c)
    fc, m_, loops, degs = int(m.group(1)), int(m.group(2)), int(m.group(3)), [int(x) for x in m.group(4).split(", ")]
    L = header(n)
    L.append("    func pl%03d() throws {" % n)
    L.append(describe(n))
    ind = "        "
    L += construct(g, ind)
    L.append(ind + "let embedding = try #require(graph.planarEmbedding())")
    L.append(ind + "let dual = embedding.dualGraph()")
    L.append(ind + "#expect(Array(dual.vertices) == Array(0 ..< %d) && dual.edgeCount == %d)" % (fc, m_))
    L.append(ind + "#expect(dual.edges.filter { $0.u == $0.v }.count == %d)" % loops)
    L.append(ind + "#expect(dual.vertices.map { dual.degree(of: $0) }.sorted(by: >) == %s)" % ints(degs))
    L.append(ind + "// Dual edge k joins the faces on the two sides of edge position k (in `faces` order).")
    L.append(ind + "var sides = [[Int]](repeating: [], count: graph.edgeCount)")
    L.append(ind + "for (f, face) in embedding.faces.enumerated() { for p in face.edges { sides[p].append(f) } }")
    L.append(ind + "#expect(dual.edges.indices.map { [dual.edges[$0].u, dual.edges[$0].v].sorted() } == sides.map { $0.sorted() })")
    L.append("    }")
    return L


def test_for(n):
    return trap_test(n) if is_trap(n) else row_test(n)


def ids(*groups):
    return [n for n in PHASE1 if group(n) in groups and not is_trap(n)]


TRAPS = [n for n in PHASE1 if is_trap(n)]
FILES = [
    ("IsPlanarTests.swift", "isPlanar", ids("Test"),
     "isPlanar (catalog PL-001 – PL-048): small named graphs, Kuratowski's two graphs and their\n"
     "// subdivisions, Platonic solids, cubic graphs, grids, stacked triangulations with and without one\n"
     "// more edge, disjoint unions and blocks. Each row also checks that exactly one witness exists."),
    ("PlanarityInputTests.swift", "Planarity inputs", ids("Inputs"),
     "Inputs (catalog PL-049 – PL-061): self-loops and parallel edges never change the answer; directed\n"
     "// graphs go through `undirected` (AdjacencyList, each arc an edge, a 2-cycle two parallel edges)."),
    ("PlanarEmbeddingTests.swift", "planarEmbedding()", ids("Embedding"),
     "planarEmbedding() (catalog PL-062 – PL-096): nil for a non-planar graph; otherwise every edge position\n"
     "// embedded (loops and parallel edges too), checked against the definitions, with faceCount, the face\n"
     "// lengths where every embedding has the same, and the rotation where it is unique up to mirror image."),
    ("PlanarFaceTests.swift", "PlanarEmbedding.faces", ids("Faces"),
     "faces (catalog PL-097 – PL-107): unique embeddings, so the faces as vertex cycles are pinned, or\n"
     "// every face reversed for the mirror image (the same choice as the rotation's)."),
    ("PlanarRotationTests.swift", "PlanarEmbedding clockwise orders and faces", ids("Rotation"),
     "Clockwise orders and face(from:alongEdgeAt:) (catalog PL-108 – PL-130 without the traps): starting at\n"
     "// the first incident edge, the mirror image accepted when it is the whole embedding's."),
    ("KuratowskiSubgraphTests.swift", "findKuratowskiSubgraph()", ids("Kuratowski"),
     "findKuratowskiSubgraph() (catalog PL-131 – PL-151): nil when planar; otherwise a subdivision of K₅ or\n"
     "// K₃,₃ made of the graph's edges, checked against the definition, pinned where it is unique, and its\n"
     "// kind pinned where only one kind occurs."),
    ("OuterplanarTests.swift", "isOuterplanar", ids("Outerplanar"),
     "isOuterplanar (catalog PL-152 – PL-168): planar with every vertex on one face."),
    ("PlanarityScaleTests.swift", "Planarity catalog rows at scale", ids("Scale"),
     "Scale (catalog PL-169 – PL-177): grids, stacked triangulations, near-planar and random graphs, and\n"
     "// a 2,000-vertex tree, each with a one-minute limit."),
    ("PlanarityPreconditionTests.swift", "Planarity preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the call, so the trap is the call's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]
if PHASE2:
    FILES.append(("DualGraphTests.swift", "PlanarEmbedding.dualGraph() (phase 2)",
                  [n for n in ROWS if group(n).startswith("Phase 2")],
                  "dualGraph() (catalog PL-178 – PL-188, phase 2): written only with swiftgen.py --phase2. Pinned by\n"
                  "// the vertex, edge and loop counts and the degrees; each dual edge joins the faces on its sides."))


def write(fname, suite, rows, comment):
    tests = [dual_test(n) if group(n).startswith("Phase 2") else test_for(n) for n in rows]
    if fname == "PlanarityPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphProtocols", "Planarity", "Testing"]
    if "Pseudograph<" in text:
        imports.append("Multigraphs")
    if "AdjacencyList<" in text:
        imports.append("AdjacencyListModule")
    if "AdjacencyMatrix(" in text:
        imports.append("AdjacencyMatrixModule")
    if fname == "PlanarityPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "PlanarityPreconditionTests.swift" else ""
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
assert rows_total == (N if PHASE2 else len(PHASE1)), rows_total
print("catalog rows", rows_total, "tests", total)
