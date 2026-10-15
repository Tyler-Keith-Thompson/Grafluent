import GraphProtocols

/// What the Louvain method reports, in order.
///
/// Each level starts with local moving: level vertices are taken in number order, sweep after
/// sweep, and each moves to the neighboring community that raises the modularity most, reported
/// as it moves. Communities are named by level vertex numbers. When a sweep moves nothing the
/// level is finished, with its partition of the graph's vertices and that partition's modularity.
/// While the modularity rose by more than the threshold, the communities are then merged into the
/// next level's vertices, numbered by their labels in the partition just reported. At the first
/// level the level vertices are the graph's vertices, numbered in `vertices` order (their vertex
/// indices when the graph has them). The method ends after a level whose modularity did not rise
/// enough, or after an aggregation whose local moving moved nothing.
@frozen
public enum LouvainEvent<G: DirectedGraph> {
    /// Level vertex `vertex` moved from community `from` to community `to`, raising the modularity
    /// by `gain`.
    case move(Int, from: Int, to: Int, gain: Double)
    /// The level is finished: the partition of the graph's vertices it stands for, and its
    /// modularity.
    case levelFinished(Partition<G>, modularity: Double)
    /// The communities became the next level's `vertexCount` vertices.
    case aggregate(vertexCount: Int)
}

extension LouvainEvent: Equatable {}
extension LouvainEvent: Sendable where G: Sendable, G.Vertex: Sendable {}

extension LouvainEvent: CustomStringConvertible {
    /// `move(v, a → b, gain)`, `levelFinished(partition, modularity)`, `aggregate(k)`.
    public var description: String {
        switch self {
        case .move(let v, let a, let b, let gain): "move(\(v), \(a) → \(b), \(gain))"
        case .levelFinished(let partition, let q): "levelFinished(\(partition), \(q))"
        case .aggregate(let k): "aggregate(\(k))"
        }
    }
}

/// The observer that records each move as an event.
@frozen
@usableFromInline
struct _LouvainRecorder<G: DirectedGraph>: _LouvainObserver {
    @usableFromInline var events: [LouvainEvent<G>] = []

    @inlinable
    init() {}

    @inlinable
    mutating func moved(_ u: Int, from: Int, to: Int, gain: Double) {
        events.append(.move(u, from: from, to: to, gain: gain))
    }
}

/// The Louvain method as a sequence of `LouvainEvent`s, one level at a time: pulling the first
/// event of a level runs that level's local moving and keeps its moves until they are pulled.
///
/// It runs the engine of `louvainCommunities(resolution:threshold:)` and
/// `louvainPartitions(resolution:threshold:)`, in index order: the finished levels' partitions are
/// that call's partitions, the last of them its communities. It holds a copy of the graph, so
/// later changes to the original do not affect it, and it can be iterated more than once.
@frozen
public struct LouvainEvents<G: DirectedGraph>: Sequence {
    public typealias Element = LouvainEvent<G>

    @usableFromInline let graph: G
    @usableFromInline let numbers: [G.Vertex: Int]?
    @usableFromInline let listed: [G.Vertex]?
    @usableFromInline let network: _CommunityGraph
    @usableFromInline let weights: [Double]?
    @usableFromInline let resolution: Double
    @usableFromInline let threshold: Double

    @inlinable
    init(graph: G, numbers: [G.Vertex: Int]?, listed: [G.Vertex]?, network: _CommunityGraph, weights: [Double]?, resolution: Double, threshold: Double) {
        _checkLouvain(resolution: resolution, threshold: threshold)
        self.graph = graph
        self.numbers = numbers
        self.listed = listed
        self.network = network
        self.weights = weights
        self.resolution = resolution
        self.threshold = threshold
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(self)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let base: LouvainEvents
        @usableFromInline var run: _LouvainRun?
        /// The events of the current phase, and the next to report.
        @usableFromInline var pending: [LouvainEvent<G>] = []
        @usableFromInline var cursor = 0
        /// 0 before the first level, 1 after a level's local moving, 2 after an aggregation, 3 at
        /// the end.
        @usableFromInline var phase = 0

        @inlinable
        init(_ base: LouvainEvents) {
            self.base = base
        }

        @inlinable
        func _partition(_ labels: [Int]) -> Partition<G> {
            Partition(base.graph, numbers: base.numbers, listed: base.listed, labels: labels)
        }

        @inlinable
        public mutating func next() -> LouvainEvent<G>? {
            while cursor == pending.count {
                pending.removeAll(keepingCapacity: true)
                cursor = 0
                switch phase {
                case 0:
                    let n = base.network.count
                    guard base.network.edgeCount > 0 else {
                        pending.append(.levelFinished(_partition(Array(0 ..< n)), modularity: 0))
                        phase = 3
                        continue
                    }
                    var run = _LouvainRun(base.network, base.weights, resolution: base.resolution, threshold: base.threshold)
                    var recorder = _LouvainRecorder<G>()
                    run.move(order: Array(0 ..< n), observer: &recorder)
                    pending = recorder.events
                    self.run = run
                    phase = 1
                case 1:
                    let (labels, modularity, aggregated) = run!.finish()
                    pending.append(.levelFinished(_partition(labels), modularity: modularity))
                    if let k = aggregated {
                        pending.append(.aggregate(vertexCount: k))
                        phase = 2
                    } else {
                        phase = 3
                    }
                case 2:
                    var recorder = _LouvainRecorder<G>()
                    let k = run!.level.count
                    run!.move(order: Array(0 ..< k), observer: &recorder)
                    pending = recorder.events
                    phase = run!.moved ? 1 : 3
                default:
                    return nil
                }
            }
            let event = pending[cursor]
            cursor &+= 1
            return event
        }
    }
}

extension Graph {
    /// The Louvain method (Blondel et al.) as a sequence of events: each vertex moved with its
    /// modularity gain, each level finished with its partition and modularity, and each
    /// aggregation. See `LouvainEvent` for the order.
    ///
    /// The finished levels' partitions are `louvainPartitions(resolution:threshold:)`.
    ///
    /// - Complexity: O(n + m) to make the sequence; O(m) per sweep while iterating.
    /// - Precondition: `resolution` and `threshold` are finite and at least zero.
    @inlinable
    public func louvainEvents(resolution: Double = 1, threshold: Double = 1e-7) -> LouvainEvents<DirectedView<Self>> {
        let listed = _listedVertices()
        return LouvainEvents(graph: directedView, numbers: listed.map(_vertexNumbers), listed: listed, network: _communityGraph(),
                             weights: nil, resolution: resolution, threshold: threshold)
    }

    /// The weighted Louvain method as a sequence of events; `weight` is called once per edge, in
    /// position order, while the sequence is made. The finished levels' partitions are
    /// `louvainPartitions(weight:resolution:threshold:)`.
    ///
    /// - Precondition: as for `louvainEvents(resolution:threshold:)`; every weight is finite and at
    ///   least zero.
    @inlinable
    public func louvainEvents<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7) -> LouvainEvents<DirectedView<Self>> {
        let listed = _listedVertices()
        return LouvainEvents(graph: directedView, numbers: listed.map(_vertexNumbers), listed: listed, network: _communityGraph(),
                             weights: _communityWeights(weight), resolution: resolution, threshold: threshold)
    }
}

extension DirectedGraph {
    /// The Louvain method for directed modularity as a sequence of events. See
    /// `Graph.louvainEvents(resolution:threshold:)`.
    ///
    /// - Precondition: `resolution` and `threshold` are finite and at least zero.
    @inlinable
    public func louvainEvents(resolution: Double = 1, threshold: Double = 1e-7) -> LouvainEvents<Self> {
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        return LouvainEvents(graph: self, numbers: numbers, listed: listed, network: _communityGraph(numbers),
                             weights: nil, resolution: resolution, threshold: threshold)
    }

    /// The weighted directed Louvain method as a sequence of events.
    ///
    /// - Precondition: as for `louvainEvents(resolution:threshold:)`; every weight is finite and at
    ///   least zero.
    @inlinable
    public func louvainEvents<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, resolution: Double = 1, threshold: Double = 1e-7) -> LouvainEvents<Self> {
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        return LouvainEvents(graph: self, numbers: numbers, listed: listed, network: _communityGraph(numbers),
                             weights: _communityWeights(weight), resolution: resolution, threshold: threshold)
    }
}
