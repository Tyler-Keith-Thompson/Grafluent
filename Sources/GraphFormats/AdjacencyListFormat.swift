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
/// loop once. The rows are a stable counting sort of the edges by line, from one pass over the
/// graph (each edge's line and far end kept for the second, as 32-bit numbers when they fit).
@inlinable func _writeAdjacencyList<Source: _WriteSource>(
    _ source: Source, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String
) {
    if source.vertexCount <= Int(Int32.max) {
        _writeAdjacencyList(source, numbers: Int32.self, to: &out, vertexID: vertexID)
    } else {
        _writeAdjacencyList(source, numbers: Int.self, to: &out, vertexID: vertexID)
    }
}

/// `_writeAdjacencyList`, with vertex numbers stored as `Number`.
@inlinable func _writeAdjacencyList<Source: _WriteSource, Number: FixedWidthInteger>(
    _ source: Source, numbers _: Number.Type, to out: inout _OutputBuffer, vertexID: (Source.Vertex) -> String
) {
    let n = source.vertexCount, m = source.edgeCount
    var rowStart = [Int](repeating: 0, count: n &+ 1)
    var lines = [Number](repeating: 0, count: m), ends = [Number](repeating: 0, count: m)
    var count = 0
    rowStart.withUnsafeMutableBufferPointer { rowStart in
        lines.withUnsafeMutableBufferPointer { lines in
            ends.withUnsafeMutableBufferPointer { ends in
                source.forEachEdge { _, u, v in
                    let forward = Source.isDirected || u <= v
                    let line = forward ? u : v
                    lines[count] = Number(truncatingIfNeeded: line)
                    ends[count] = Number(truncatingIfNeeded: forward ? v : u)
                    rowStart[line &+ 1] &+= 1
                    count &+= 1
                }
            }
        }
        for k in 0 ..< n { rowStart[k &+ 1] &+= rowStart[k] }
    }
    var far = [Number](repeating: 0, count: count)
    var fill = rowStart
    fill.withUnsafeMutableBufferPointer { fill in
        far.withUnsafeMutableBufferPointer { far in
            lines.withUnsafeBufferPointer { lines in
                ends.withUnsafeBufferPointer { ends in
                    for i in 0 ..< count {
                        let line = Int(truncatingIfNeeded: lines[i])
                        far[fill[line]] = ends[i]
                        fill[line] &+= 1
                    }
                }
            }
        }
    }
    var ids = _IDCache(vertexCount: n)
    for k in 0 ..< n {
        let id = vertexID(source.vertex(at: k))
        ids.set(k, id: id.debugDescription) { _appendListToken(id, to: &$0) }
    }
    rowStart.withUnsafeBufferPointer { rowStart in
        far.withUnsafeBufferPointer { far in
            for k in 0 ..< n {
                ids.write(k, to: &out)
                for j in rowStart[k] ..< rowStart[k &+ 1] { ids.write(Int(truncatingIfNeeded: far[j]), to: &out, after: 0x20) }
                out.append(0x0A)
            }
        }
    }
}
