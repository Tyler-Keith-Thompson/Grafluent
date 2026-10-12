/// The adjacency list (NetworkX `read_adjlist`/`write_adjlist`): per line a vertex, then its
/// neighbours, one edge to each; `#` comments.

/// Reads an adjacency list into `target`: the first field of each line that has any is a vertex
/// (inserted even alone), each later field an edge from it, in order.
@inlinable func _readAdjacencyList<Target: _ReadTarget>(
    _ text: UnsafeBufferPointer<UInt8>, into target: inout Target,
    map: (UnsafeBufferPointer<UInt8>) -> Target.Vertex?
) throws(ParseError) {
    var registry = _Registry<Target>()
    let n = text.count
    var p = 0
    while p < n {
        var q = p
        var head = -1
        while let (s, e) = _nextListField(text, &q) {
            let resolved = try registry.resolve(UnsafeBufferPointer(rebasing: text[s ..< e]), at: s, into: &target, map: map)
            if head < 0 {
                head = resolved.key
            } else {
                _ = target.insertEdge(head, resolved.key)
            }
        }
        while q < n && text[q] != 0x0A { q &+= 1 }
        p = q &+ 1
    }
}

/// Writes one line per vertex in `vertices` order: the vertex, then the far end of each of its
/// edges in position order; an undirected edge on the line of whichever endpoint comes first, a
/// loop once.
@inlinable func _writeAdjacencyList<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String
) {
    let n = source.vertexCount
    // The rows, as one array grouped by line (a counting sort of the edges by line).
    var rowStart = [Int](repeating: 0, count: n + 1)
    source.forEachEdge { _, u, v in
        let line = Source.isDirected ? u : min(u, v)
        rowStart[line + 1] += 1
    }
    for k in 0 ..< n { rowStart[k + 1] += rowStart[k] }
    var fill = rowStart
    var far = [Int](repeating: 0, count: rowStart[n])
    source.forEachEdge { _, u, v in
        let line = Source.isDirected ? u : min(u, v)
        far[fill[line]] = Source.isDirected || u <= v ? v : u
        fill[line] += 1
    }
    var ids = _IDCache(vertexCount: n)
    for k in 0 ..< n {
        let id = vertexID(source.vertex(at: k))
        ids.set(k, id: id.debugDescription) { _appendListToken(id, to: &$0) }
    }
    for k in 0 ..< n {
        ids.write(k, to: &out)
        for j in rowStart[k] ..< rowStart[k + 1] {
            out.append(0x20)
            ids.write(far[j], to: &out)
        }
        out.append(0x0A)
    }
}
