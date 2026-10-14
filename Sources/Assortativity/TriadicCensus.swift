import GraphProtocols

/// How many of a directed graph's unordered vertex triples fall in each of the 16 isomorphism
/// classes of triads, named by Holland and Leinhardt's MAN codes: the numbers of mutual,
/// asymmetric and null dyads, and a letter (Down, Up, Cyclic, Transitive) telling apart triads
/// with the same three numbers.
@frozen
public struct TriadicCensus: Hashable, Sendable {
    /// The counts, in `types` order.
    public let counts: [Int]

    @inlinable
    init(counts: [Int]) { self.counts = counts }

    /// The 16 triad types: "003", "012", "102", "021D", "021U", "021C", "111D", "111U", "030T",
    /// "030C", "201", "120D", "120U", "120C", "210", "300".
    @inlinable
    public static var types: [String] {
        ["003", "012", "102", "021D", "021U", "021C", "111D", "111U", "030T", "030C", "201", "120D", "120U", "120C", "210", "300"]
    }

    /// The number of triples of `type`. O(1).
    ///
    /// - Parameter type: A MAN code from `types`, such as "021D".
    /// - Precondition: `type` is one of `types`.
    @inlinable
    public subscript(type: String) -> Int {
        guard let k = TriadicCensus.types.firstIndex(of: type) else { preconditionFailure("Not a triad type: \(type)") }
        return counts[k]
    }
}

/// The type number (an index into `TriadicCensus.types`) of each of the 64 triads coded
/// v→u = 1, u→v = 2, v→w = 4, w→v = 8, u→w = 16, w→u = 32 (Batagelj and Mrvar).
@inlinable
var _triadTypes: [Int] {
    [0, 1, 1, 2, 1, 3, 5, 7, 1, 5, 4, 6, 2, 7, 6, 10,
     1, 5, 3, 7, 4, 8, 8, 12, 5, 9, 8, 13, 6, 13, 11, 14,
     1, 4, 5, 6, 5, 8, 9, 13, 3, 8, 8, 11, 7, 12, 13, 14,
     2, 6, 7, 10, 6, 11, 13, 14, 7, 13, 12, 14, 10, 14, 14, 15]
}

extension DirectedGraph {
    /// The triadic census by Batagelj and Mrvar's algorithm, on the simple digraph underneath
    /// (self-loops ignored, parallel arcs counted once). Vertices are ranked by their number of
    /// distinct neighbors, greatest first, so each adjacent pair reads the row of its end with
    /// fewer; the triads it forms with the other end's remaining neighbors are counted in bulk by
    /// dyad type. O(n + m^(3/2)).
    ///
    /// - Returns: The count of every triad type; they add up to n(n − 1)(n − 2)/6.
    /// - Precondition: n(n − 1)(n − 2)/6 fits in `Int`.
    @inlinable
    public func triadicCensus() -> TriadicCensus {
        let simple = _simpleArcRows(_compressedRows(readsEdges: false, dropsLoops: true).rows)
        let n = simple.out.count
        let codes = _triadTypes
        var counts = [Int](repeating: 0, count: 16)
        // Each vertex's distinct neighbors either way, with the dyad's arcs: bit 1 for v → w, bit
        // 2 for w → v.
        var degree = [Int](repeating: 0, count: n)
        var link = [Int](repeating: 0, count: n), linked = [Int](repeating: -1, count: n)
        for v in 0 ..< n {
            for slot in simple.out.offsets[v] ..< simple.out.offsets[v + 1] {
                linked[simple.out.targets[slot]] = v
                degree[v] += 1
            }
            for slot in simple.in.offsets[v] ..< simple.in.offsets[v + 1] where linked[simple.in.targets[slot]] != v { degree[v] += 1 }
        }
        // Rank by that degree, greatest first, ties by index: a stable counting sort.
        let greatest = degree.max() ?? 0
        var start = [Int](repeating: 0, count: greatest + 2)
        for v in 0 ..< n { start[greatest - degree[v] + 1] += 1 }
        for d in 0 ... greatest { start[d + 1] += start[d] }
        var rank = [Int](repeating: 0, count: n), order = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            rank[v] = start[greatest - degree[v]]
            order[rank[v]] = v
            start[greatest - degree[v]] += 1
        }
        // The rows by rank, each ascending by rank, with each neighbor's dyad bits.
        var offsets = [Int](repeating: 0, count: n + 1)
        var neighbors: [Int] = [], links: [Int] = []
        neighbors.reserveCapacity(degree.reduce(0, +))
        links.reserveCapacity(neighbors.capacity)
        for i in 0 ..< n {
            let v = order[i]
            for slot in simple.out.offsets[v] ..< simple.out.offsets[v + 1] {
                let w = simple.out.targets[slot]
                linked[w] = n + i
                link[w] = 1
            }
            for slot in simple.in.offsets[v] ..< simple.in.offsets[v + 1] {
                let w = simple.in.targets[slot]
                if linked[w] == n + i {
                    link[w] = 3
                } else {
                    linked[w] = n + i
                    link[w] = 2
                }
            }
            var row: [Int] = []
            row.reserveCapacity(degree[v])
            for slot in simple.out.offsets[v] ..< simple.out.offsets[v + 1] { row.append(simple.out.targets[slot]) }
            for slot in simple.in.offsets[v] ..< simple.in.offsets[v + 1] where link[simple.in.targets[slot]] == 2 { row.append(simple.in.targets[slot]) }
            row.sort { rank[$0] < rank[$1] }
            for w in row {
                neighbors.append(rank[w])
                links.append(link[w])
            }
            offsets[i + 1] = neighbors.count
        }
        var nearV = [Int](repeating: -1, count: n), linkV = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            let rowStart = offsets[v], rowEnd = offsets[v + 1]
            // v's neighbors ranked above the current u, by dyad type.
            var above = SIMD4<Int>()
            for slot in rowStart ..< rowEnd {
                nearV[neighbors[slot]] = v
                linkV[neighbors[slot]] = links[slot]
                above[links[slot]] += 1
            }
            for slotU in rowStart ..< rowEnd {
                let u = neighbors[slotU], dyad = links[slotU]
                above[dyad] -= 1
                guard u > v else { continue }
                // Triads (v, u, w) with w a neighbor of u: counted here when w is a neighbor of v
                // too and ranked above u, or not a neighbor of v and ranked above v.
                var common = 0
                var commonAbove = SIMD4<Int>()
                for slot in offsets[u] ..< offsets[u + 1] {
                    let w = neighbors[slot]
                    guard w != v else { continue }
                    let fromU = links[slot]
                    let uw = (fromU & 1) * 16 + (fromU & 2) * 16
                    if nearV[w] == v {
                        common += 1
                        guard w > u else { continue }
                        let vw = (linkV[w] & 1) * 4 + (linkV[w] & 2) * 4
                        counts[codes[dyad + vw + uw]] += 1
                        commonAbove[linkV[w]] += 1
                    } else if w > v {
                        counts[codes[dyad + uw]] += 1
                    }
                }
                // Triads with w a neighbor of v only, ranked above u: one per dyad type.
                for type in 1 ... 3 {
                    let count = above[type] - commonAbove[type]
                    if count > 0 { counts[codes[dyad + (type & 1) * 4 + (type & 2) * 4]] += count }
                }
                let union = (rowEnd - rowStart - 1) + (offsets[u + 1] - offsets[u] - 1) - common
                counts[dyad == 3 ? 2 : 1] += n - union - 2
            }
        }
        let triples = n < 3 ? 0 : n * (n - 1) / 2 * (n - 2) / 3
        counts[0] = triples - counts[1...].reduce(0, +)
        return TriadicCensus(counts: counts)
    }
}
