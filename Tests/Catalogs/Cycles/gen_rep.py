"""Representation variants of catalog rows (CY-701, CY-702): the generated middle of\nCycleRepresentationTests.swift, assembled by asm_rep.py."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref, gen  # noqa: E402

ROWS = {r[0]: r for r in gen.rows()}

def variant(cid, typ):
    _, src, spec, op, expected, note = ROWS[cid]
    g = ref.parse(spec)
    assert ref.compute(g, op) == expected
    text = gen.test_for(cid, src, spec, op, expected, note)
    lines = text.split("\n")
    ind = "        "
    out = []
    for ln in lines:
        if ln.strip().startswith("let graph = "):
            if typ in ("UndirectedAdjacencyList", "AdjacencyList"):
                ln = ln.replace("ReferencePseudograph", typ).replace("ReferenceDirectedMultigraph", typ)
                ln = re.sub(r"%s<(\w+)>" % typ, typ + r"<\1>", ln)
                out.append(ln)
                out.append(ind + "#expect(graph.edgeCount == %d)" % g.m)
                vs = g.vertices
                out.append(ind + "#expect(Array(graph.vertices) == %s)" % ("[" + ", ".join(gen.lit(v, isinstance(v, str)) for v in vs) + "]"))
                continue
            if typ == "CompressedSparseRow":
                assert g.directed and g.vertices == list(range(g.n)) and g.edges == sorted(g.edges) and len(set(g.edges)) == len(g.edges)
                out.append(ind + "let graph = CompressedSparseRow(vertexCount: %d, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })" % g.n)
                continue
            if typ == "AdjacencyMatrix":
                assert g.directed and g.vertices == list(range(g.n)) and g.edges == sorted(g.edges) and len(set(g.edges)) == len(g.edges)
                out.append(ind + "let graph = AdjacencyMatrix(vertexCount: %d, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })" % g.n)
                continue
        if typ == "AdjacencyMatrix" and "expectedEdges" in ln:
            continue
        out.append(ln)
    text = "\n".join(out)
    if typ == "AdjacencyMatrix":
        # edges as cells
        cs = ref.brute_cycles(g, None)
        cells = "[" + ", ".join("[" + ", ".join("[%d, %d]" % g.edges[e] for e in c[1]) + "]" for c in cs) + "]"
        text = text.replace("#expect(cycles.map(\\.vertices) == expectedVertices)",
            "#expect(cycles.map(\\.vertices) == expectedVertices)\n" + ind + "let expectedCells: [[[Int]]] = " + cells + "\n" + ind + "#expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)")
        text = re.sub(r"\n\s*let expectedEdges: \[\[Int\]\] = \[[^\n]*", "", text)
    # rename the function
    m = re.search(r"func (\w+)\(\)", text)
    text = text.replace("func %s()" % m.group(1), "func %s%s()" % ({"UndirectedAdjacencyList": "undirectedAdjacencyList", "AdjacencyList": "adjacencyList", "CompressedSparseRow": "compressedSparseRow", "AdjacencyMatrix": "adjacencyMatrix"}[typ], m.group(1)[0].upper() + m.group(1)[1:]))
    text = re.sub(r'@Test\("(CY-\d+)', lambda mm: '@Test("%s %s on %s:' % ({"UndirectedAdjacencyList": "CY-701", "AdjacencyList": "CY-701", "CompressedSparseRow": "CY-702", "AdjacencyMatrix": "CY-702"}[typ], mm.group(1), typ), text, count=1)
    return text

def rowmajor(cid, typ):
    _, src, spec, op, expected, note = ROWS[cid]
    g0 = ref.parse(spec)
    assert g0.directed and len(set(g0.edges)) == len(g0.edges)
    n = g0.n
    assert sorted(g0.vertices) == list(range(n))
    arcs = sorted(g0.edges)
    g = ref.G(list(range(n)), arcs, True)
    m = re.search(r"maxLength:\s*(\d+)", op)
    L = int(m.group(1)) if m else None
    ind = "        "
    pairs = ["(%d, %d)" % a for a in arcs]
    lines = []
    reordered = arcs != g0.edges or g0.vertices != list(range(n))
    title = "CY-702 %s on %s: %s" % (cid, typ, "the catalog's arcs in row-major order, vertices 0..<%d" % n if reordered else "positions are the representation's own")
    fname = {"CompressedSparseRow": "compressedSparseRow", "AdjacencyMatrix": "adjacencyMatrix"}[typ] + cid.split("-")[1]
    lines.append('    @Test("%s")' % title)
    lines.append("    func %s() {" % fname)
    lines.append(ind + "// %s%s" % (spec, ", rewritten row-major" if reordered else ""))
    one = "let pairs: [(Int, Int)] = [%s]" % ", ".join(pairs)
    if len(ind) + len(one) <= 110:
        lines.append(ind + one)
    else:
        lines.append(ind + "let pairs: [(Int, Int)] = [")
        lines += gen.wrap(pairs, ind + "    ")
        lines.append(ind + "]")
    lines.append(ind + "let graph = %s(vertexCount: %d, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })" % (typ, n))
    if op == "girth":
        v = ref.girth_edges(g); assert v == ref.girth_bfs(g)
        lines.append(ind + "#expect(graph.girth() == %s)" % ("nil" if v is None else v))
    elif op.startswith("count"):
        lines.append(ind + "#expect(Array(graph.simpleCycles(%s)).count == %d)" % ("" if L is None else "maxLength: %d" % L, len(ref.brute_cycles(g, L))))
    else:
        cs = ref.brute_cycles(g, L)
        lines.append(ind + "let cycles = Array(graph.simpleCycles(%s))" % ("" if L is None else "maxLength: %d" % L))
        vrows = ["[" + ", ".join(str(v) for v in c[0]) + "]" for c in cs]
        lines.append(ind + "let expectedVertices: [[Int]] = [%s]" % ", ".join(vrows))
        lines.append(ind + "#expect(cycles.map(\\.vertices) == expectedVertices)")
        if typ == "AdjacencyMatrix":
            cells = ["[" + ", ".join("[%d, %d]" % arcs[e] for e in c[1]) + "]" for c in cs]
            one = "let expectedCells: [[[Int]]] = [%s]" % ", ".join(cells)
            if len(ind) + len(one) <= 110:
                lines.append(ind + one)
            else:
                lines.append(ind + "let expectedCells: [[[Int]]] = [")
                lines += gen.wrap(cells, ind + "    ")
                lines.append(ind + "]")
            lines.append(ind + "#expect(cycles.map { $0.edges.map { [$0.source, $0.target] } } == expectedCells)")
        else:
            erows = ["[" + ", ".join(str(e) for e in c[1]) + "]" for c in cs]
            lines.append(ind + "let expectedEdges: [[Int]] = [%s]" % ", ".join(erows))
            lines.append(ind + "#expect(cycles.map(\\.edges) == expectedEdges)")
    lines.append("    }")
    return "\n".join(lines)


def text():
    plan = [(c, "UndirectedAdjacencyList") for c in ["CY-006", "CY-014", "CY-022", "CY-027", "CY-032", "CY-039", "CY-113", "CY-121", "CY-122", "CY-123", "CY-319", "CY-325", "CY-330", "CY-341", "CY-343", "CY-418", "CY-492", "CY-502", "CY-503"]]
    plan += [(c, "AdjacencyList") for c in ["CY-200", "CY-210", "CY-215", "CY-241", "CY-247", "CY-250", "CY-457", "CY-511", "CY-517", "CY-534"]]
    out = [variant(c, t) for c, t in plan]
    for t in ("CompressedSparseRow", "AdjacencyMatrix"):
        out += [rowmajor(c, t) for c in ["CY-200", "CY-240", "CY-241", "CY-457", "CY-511", "CY-534"]]
    return "\n\n".join(out)


if __name__ == "__main__":
    print(text())
