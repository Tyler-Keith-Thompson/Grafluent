import GraphProtocols

/// A cut: the vertices split into a source side and a sink side, and the edges from the first to
/// the second (OR-Tools' source-side and sink-side cuts; JGraphT `getSourcePartition`,
/// `getSinkPartition`, `getCutEdges`; igraph `Cut.partition`, `Cut.cut`). The result of
/// `minimumCut(from:to:capacity:)`, `minimumCut(capacity:)` and `Flow.minimumCut`.
///
/// On an undirected graph the cut is over `directed`: each crossing edge is listed once, as the
/// arc that leaves the source side.
@frozen
public struct Cut<G: DirectedGraph, Capacity: Comparable & AdditiveArithmetic> {
    /// The capacity of `edges`.
    public let value: Capacity
    /// The vertices on the source side, in `vertices` order.
    public let sourceSide: [G.Vertex]
    /// The vertices on the sink side, in `vertices` order.
    public let sinkSide: [G.Vertex]
    /// Every edge from the source side to the sink side, zero capacities included, in position
    /// order. Edges back from the sink side are not part of the cut.
    public let edges: [G.Edges.Index]

    @inlinable
    init(value: Capacity, sourceSide: [G.Vertex], sinkSide: [G.Vertex], edges: [G.Edges.Index]) {
        self.value = value
        self.sourceSide = sourceSide
        self.sinkSide = sinkSide
        self.edges = edges
    }
}

extension Cut: Equatable {
    /// Whether both have the same value, sides and edges.
    @inlinable
    public static func == (lhs: Cut, rhs: Cut) -> Bool {
        lhs.value == rhs.value && lhs.sourceSide == rhs.sourceSide && lhs.sinkSide == rhs.sinkSide && lhs.edges == rhs.edges
    }
}

extension Cut: Sendable where G.Vertex: Sendable, G.Edges.Index: Sendable, Capacity: Sendable {}

extension Cut: CustomStringConvertible {
    /// `value 23; S [s, v1]; T [v3, t]; cut [2, 7]`.
    public var description: String {
        "value \(value); S [\(sourceSide.map { "\($0)" }.joined(separator: ", "))]; T [\(sinkSide.map { "\($0)" }.joined(separator: ", "))]; cut [\(edges.map { "\($0)" }.joined(separator: ", "))]"
    }
}

/// The sides of a cut from a mark per vertex number (true: sink side), each in order.
@inlinable
func _cutSides<Vertex>(_ listed: [Vertex], _ inSink: [Bool]) -> (source: [Vertex], sink: [Vertex]) {
    var sinkCount = 0
    for v in listed.indices where inSink[v] { sinkCount += 1 }
    var source: [Vertex] = [], sink: [Vertex] = []
    source.reserveCapacity(listed.count - sinkCount)
    sink.reserveCapacity(sinkCount)
    for v in listed.indices {
        if inSink[v] { sink.append(listed[v]) } else { source.append(listed[v]) }
    }
    return (source, sink)
}

extension DirectedGraph {
    /// The cut with this sink side over the graph's edges: every non-loop edge from the source
    /// side into the sink side, in position order, and their capacities' sum.
    @inlinable
    func _cut<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C], _ listed: [Vertex], _ inSink: [Bool]) -> Cut<Self, C> {
        let (sourceSide, sinkSide) = _cutSides(listed, inSink)
        var crossing: [Edges.Index] = []
        var value = C.zero
        var e = 0
        for position in self.edges.indices {
            let u = Int(edges.tail[e]), v = Int(edges.head[e])
            if !inSink[u] && inSink[v] {
                crossing.append(position)
                value += capacities[e]
            }
            e += 1
        }
        return Cut(value: value, sourceSide: sourceSide, sinkSide: sinkSide, edges: crossing)
    }
}

extension Graph {
    /// The cut with this sink side over `directed`: each edge between the sides once, as the arc
    /// leaving the source side, in position order, and their capacities' sum.
    @inlinable
    func _cut<C: Comparable & AdditiveArithmetic>(_ edges: _FlowEdges, _ capacities: [C], _ listed: [Vertex], _ inSink: [Bool]) -> Cut<DirectedView<Self>, C> {
        let (sourceSide, sinkSide) = _cutSides(listed, inSink)
        var crossing: [DirectedView<Self>.Edges.Index] = []
        var value = C.zero
        var e = 0
        for position in self.edges.indices {
            let u = Int(edges.tail[e]), v = Int(edges.head[e])
            if inSink[u] != inSink[v] {
                crossing.append(DirectedView<Self>.Edges.Index(position: position, reversed: inSink[u]))
                value += capacities[e]
            }
            e += 1
        }
        return Cut(value: value, sourceSide: sourceSide, sinkSide: sinkSide, edges: crossing)
    }
}
