import GraphProtocols
import Walks

/// The two graphs of Kuratowski's theorem (1930), the complete graph K₅ and the complete bipartite
/// graph K₃,₃: a graph is planar exactly when it contains no subdivision of either.
@frozen
public enum KuratowskiGraph: Hashable, Sendable, CaseIterable, CustomStringConvertible {
    /// K₅: five branch vertices, each pair joined.
    case k5
    /// K₃,₃: two sides of three branch vertices, each vertex joined to every vertex of the other
    /// side.
    case k33

    public var description: String { self == .k5 ? "K5" : "K3,3" }
}

/// A Kuratowski subgraph: a subdivision of K₅ or K₃,₃ made of a graph's edges, the witness that the
/// graph is not planar. Suppressing its degree-2 vertices leaves exactly `kind`.
///
/// It never uses a self-loop, and uses one copy of each pair of parallel edges. Which subgraph is
/// found when there are several is not specified, but it depends only on the graph's rows: graphs
/// with the same vertices, the same edge positions and the same incidence order get the same one.
@frozen
public struct KuratowskiSubgraph<G: Graph> {
    /// Which Kuratowski graph this is a subdivision of.
    public let kind: KuratowskiGraph
    /// The edge positions, ascending.
    public let edges: [G.Edges.Index]
    /// The branch vertices (those of degree 3 or 4 in the subgraph). For K₅, all five in
    /// `vertices` order. For K₃,₃, the side holding the first branch vertex in `vertices` order,
    /// then the other side, each in `vertices` order.
    public let branchVertices: [G.Vertex]
    /// One path per pair of branch vertices joined in `kind`, from `branchVertices[i]` to
    /// `branchVertices[j]`, in increasing (i, j): ten for K₅; nine for K₃,₃, each across the
    /// sides. Their inner vertices have degree 2, and together they use every edge once.
    public let paths: [Path<G.Vertex, G.Edges.Index>]

    /// The subgraph on `witness`, simple edges of `simple` forming a subdivision.
    @inlinable
    init(_ graph: G, _ simple: borrowing _UnderlyingSimpleGraph, witness: [Int], listed: [G.Vertex]?) {
        let n = simple.vertexCount
        // Each vertex's witness edges (at most four), in increasing simple edge number.
        var degree = [Int](repeating: 0, count: n)
        var incident = [Int](repeating: -1, count: 4 * n)
        for k in witness {
            for i in 0 ... 1 {
                let end = simple.end(k, i)
                precondition(degree[end] < 4, "Planarity: a Kuratowski subgraph vertex of degree above 4")
                incident[4 * end + degree[end]] = k
                degree[end] += 1
            }
        }
        var branch: [Int] = []
        for k in witness {
            for i in 0 ... 1 {
                let end = simple.end(k, i)
                if degree[end] > 2 && !branch.contains(end) { branch.append(end) }
            }
        }
        branch.sort()
        let isK5 = branch.count == 5 && branch.allSatisfy { degree[$0] == 4 }
        precondition(isK5 || (branch.count == 6 && branch.allSatisfy { degree[$0] == 3 }), "Planarity: the isolated subgraph is not a Kuratowski subgraph")
        // The path along each witness edge at each branch vertex, to the next branch vertex.
        var traced: [(from: Int, to: Int, vertices: [Int], edges: [Int])] = []
        for b in branch {
            for i in 0 ..< degree[b] {
                var k = incident[4 * b + i]
                var vertices = [b], edges = [k]
                var current = simple.other(k, b)
                while degree[current] == 2 {
                    vertices.append(current)
                    k = incident[4 * current] == k ? incident[4 * current + 1] : incident[4 * current]
                    edges.append(k)
                    current = simple.other(k, current)
                }
                precondition(degree[current] > 2, "Planarity: a Kuratowski subgraph path ends at a vertex of degree 1")
                vertices.append(current)
                traced.append((b, current, vertices, edges))
            }
        }
        // Order the branch vertices: K₃,₃ by side.
        var order = branch
        if !isK5 {
            let first = branch[0]
            let across = Set(traced.filter { $0.from == first }.map(\.to))
            order = [first] + branch.filter { $0 != first && !across.contains($0) } + branch.filter { across.contains($0) }
            precondition(across.count == 3 && order.count == 6, "Planarity: the K3,3 subdivision is not bipartite")
        }
        var pairs: [(Int, Int)] = []
        if isK5 {
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        } else {
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        let positions = Array(graph.edges.indices)
        func vertex(_ v: Int) -> G.Vertex { listed?[v] ?? graph.vertex(atIndex: v) }
        func position(_ k: Int) -> G.Edges.Index { positions[simple.representative[k]] }
        var paths: [Path<G.Vertex, G.Edges.Index>] = []
        for (i, j) in pairs {
            guard let found = traced.first(where: { $0.from == order[i] && $0.to == order[j] }) else {
                preconditionFailure("Planarity: two branch vertices are not joined")
            }
            paths.append(Path(_uncheckedVertices: found.vertices.map(vertex), edges: found.edges.map(position)))
        }
        // Each witness edge lies on exactly one path: no stray cycle beside the subdivision.
        precondition(paths.reduce(0) { $0 + $1.edges.count } == witness.count, "Planarity: the Kuratowski subgraph has edges off its paths")
        kind = isK5 ? .k5 : .k33
        edges = witness.map { simple.representative[$0] }.sorted().map { positions[$0] }
        branchVertices = order.map(vertex)
        self.paths = paths
    }
}

extension KuratowskiSubgraph: Equatable {}

extension KuratowskiSubgraph: Sendable where G.Vertex: Sendable, G.Edges.Index: Sendable {}

extension KuratowskiSubgraph: CustomStringConvertible {
    /// The kind, the branch vertices and the edge positions.
    public var description: String {
        "KuratowskiSubgraph(\(kind), branch vertices: [" + branchVertices.map { "\($0)" }.joined(separator: ", ")
            + "], edges: [" + edges.map { "\($0)" }.joined(separator: ", ") + "])"
    }
}
