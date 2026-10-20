// snippet: packedrows-imports
import GraphProtocols
import PackedCompressedSparseRowModule
// snippet end

/// Who follows whom, built in one go: the rows come out packed end to end, with no spare cells.
func packedFollows(people: [String], arrows: [(String, String)]) -> PackedCompressedSparseRow<String> {
    // snippet: packedrows-build
    var follows = PackedCompressedSparseRow<String> {
        for name in people { name }
        for (who, whom) in arrows { DirectedEdge(from: who, to: whom) }
    }
    // snippet end
    return follows
}

/// Adds the follow, or removes it when it is there. Returns whether it is there afterwards.
func toggleFollow(_ follows: inout PackedCompressedSparseRow<String>, _ who: String, _ whom: String) -> Bool {
    // snippet: packedrows-change
    let follow = DirectedEdge(from: who, to: whom)
    if follows.contains(edge: follow) {
        follows.remove(edge: follow)
    } else {
        follows.insert(edge: follow)
    }
    // snippet end
    return follows.contains(edge: follow)
}

/// What the code panel prints.
func readBack(_ follows: PackedCompressedSparseRow<String>) -> [String] {
    // snippet: packedrows-read
    let anaFollows = Array(follows.successors(of: "Ana"))                     // →
    let deeFollowsCy = follows.contains(edge: DirectedEdge(from: "Dee", to: "Cy"))  // →
    let followCount = follows.edgeCount                                        // →
    // snippet end
    return ["[" + anaFollows.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "\(deeFollowsCy)", "\(followCount)"]
}

/// One row of the storage: where it starts, how many of its cells hold a follow, and how many
/// it owns in all.
struct RowCells {
    var name: String
    var start: Int
    var count: Int
    var capacity: Int
    var targets: [String]
}

/// The storage as the graph lends it to algorithms: every row's cells, in row order, over one
/// array of `capacity` cells.
struct StorageCells {
    var capacity: Int
    var rows: [RowCells]
    var used: Int { rows.reduce(0) { $0 + $1.count } }
}

func cells(of follows: PackedCompressedSparseRow<String>) -> StorageCells {
    follows._withOutIndexRows { targets, rows, _, _ in
        var out: [RowCells] = []
        for i in 0 ..< follows.vertexCount {
            let start = rows[3 * i], count = rows[3 * i + 1], capacity = rows[3 * i + 2]
            out.append(RowCells(name: follows.vertex(atIndex: i), start: start, count: count, capacity: capacity,
                                targets: (0 ..< count).map { follows.vertex(atIndex: targets[start + $0]) }))
        }
        return StorageCells(capacity: targets.count, rows: out)
    } ?? StorageCells(capacity: 0, rows: [])
}
