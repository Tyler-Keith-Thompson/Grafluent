import GraphProtocols

/// What Floyd's cycle detection reports, in order, as `floydCycleDetection(from:successor:)`
/// runs it on a functional graph.
///
/// The tortoise steps once and the hare twice per `step`, from the start, until they `meet` on
/// the cycle. The tortoise goes back to the start, and both step once at a time until they meet
/// at the `root`, the first vertex on the cycle, after `tailLength` steps. Then the hare laps the
/// cycle from the root, one `step` at a time, and the steps back to the root are its
/// `cycle(length:)`.
@frozen
public enum FloydCycleDetectionEvent: Hashable, Sendable {
    /// The positions after a step.
    case step(tortoise: Int, hare: Int)
    /// The tortoise and hare meet, at this vertex on the cycle.
    case meet(Int)
    /// The first vertex on the cycle, `tailLength` steps from the start.
    case root(Int, tailLength: Int)
    /// The cycle's length; the last event.
    case cycle(length: Int)
}

/// What Brent's cycle detection reports, in order, as `brentCycleDetection(from:successor:)` runs
/// it on a functional graph.
///
/// The hare steps once per `step` from the start's successor, with the tortoise waiting. When
/// the hare has taken a power of two steps since the tortoise last moved, the tortoise teleports
/// to it and the power doubles. When they meet, the steps since the teleport are the
/// `cycle(length:)`. Then the tortoise starts over at the start and the hare that many steps
/// ahead, one `step` each, and both step together until they meet at the `root`, the last event.
@frozen
public enum BrentCycleDetectionEvent: Hashable, Sendable {
    /// The positions after a step.
    case step(tortoise: Int, hare: Int)
    /// The tortoise jumps to the hare at this vertex, and the next power of two is `power`.
    case teleport(Int, power: Int)
    /// The tortoise and hare meet; the cycle's length.
    case cycle(length: Int)
    /// The first vertex on the cycle, `tailLength` steps from the start; the last event.
    case root(Int, tailLength: Int)
}

extension FloydCycleDetectionEvent: CustomStringConvertible {
    /// `step(t, h)`, `meet(v)`, `root(v, μ)`, `cycle(λ)`.
    public var description: String {
        switch self {
        case .step(let t, let h): "step(\(t), \(h))"
        case .meet(let v): "meet(\(v))"
        case .root(let v, let mu): "root(\(v), \(mu))"
        case .cycle(let lambda): "cycle(\(lambda))"
        }
    }
}

extension BrentCycleDetectionEvent: CustomStringConvertible {
    /// `step(t, h)`, `teleport(v, power)`, `cycle(λ)`, `root(v, μ)`.
    public var description: String {
        switch self {
        case .step(let t, let h): "step(\(t), \(h))"
        case .teleport(let v, let power): "teleport(\(v), \(power))"
        case .cycle(let lambda): "cycle(\(lambda))"
        case .root(let v, let mu): "root(\(v), \(mu))"
        }
    }
}

/// Floyd's cycle detection on a functional graph as a sequence of `FloydCycleDetectionEvent`s,
/// one step at a time. It holds the graph, and can be iterated more than once.
@frozen
public struct FloydCycleDetection: Sequence, Sendable {
    public typealias Element = FloydCycleDetectionEvent

    @usableFromInline let graph: FunctionalGraph
    @usableFromInline let start: Int

    @inlinable
    init(graph: FunctionalGraph, start: Int) {
        graph._check(start)
        self.graph = graph
        self.start = start
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(graph: graph, start: start) }

    public struct Iterator: IteratorProtocol, Sendable {
        @usableFromInline let graph: FunctionalGraph
        @usableFromInline let start: Int
        @usableFromInline var tortoise: Int
        @usableFromInline var hare: Int
        @usableFromInline var count = 0
        /// 0 before the first step, 1 chasing, 2 seeking the root, 3 lapping, 4 done.
        @usableFromInline var phase = 0

        @inlinable
        init(graph: FunctionalGraph, start: Int) {
            self.graph = graph
            self.start = start
            tortoise = start
            hare = start
        }

        @inlinable
        public mutating func next() -> FloydCycleDetectionEvent? {
            switch phase {
            case 0:
                tortoise = graph.successor(of: start)
                hare = graph.successor(of: graph.successor(of: start))
                phase = 1
                return .step(tortoise: tortoise, hare: hare)
            case 1:
                guard tortoise == hare else {
                    tortoise = graph.successor(of: tortoise)
                    hare = graph.successor(of: graph.successor(of: hare))
                    return .step(tortoise: tortoise, hare: hare)
                }
                let meeting = hare
                tortoise = start
                phase = 2
                return .meet(meeting)
            case 2:
                guard tortoise == hare else {
                    tortoise = graph.successor(of: tortoise)
                    hare = graph.successor(of: hare)
                    count += 1
                    return .step(tortoise: tortoise, hare: hare)
                }
                let tailLength = count
                count = 0
                phase = 3
                return .root(tortoise, tailLength: tailLength)
            case 3:
                // The hare laps the cycle from the root, where the tortoise waits.
                guard count == 0 || tortoise != hare else {
                    phase = 4
                    return .cycle(length: count)
                }
                hare = graph.successor(of: hare)
                count += 1
                return .step(tortoise: tortoise, hare: hare)
            default:
                return nil
            }
        }
    }
}

/// Brent's cycle detection on a functional graph as a sequence of `BrentCycleDetectionEvent`s,
/// one step at a time. It holds the graph, and can be iterated more than once.
@frozen
public struct BrentCycleDetection: Sequence, Sendable {
    public typealias Element = BrentCycleDetectionEvent

    @usableFromInline let graph: FunctionalGraph
    @usableFromInline let start: Int

    @inlinable
    init(graph: FunctionalGraph, start: Int) {
        graph._check(start)
        self.graph = graph
        self.start = start
    }

    @inlinable
    public func makeIterator() -> Iterator { Iterator(graph: graph, start: start) }

    public struct Iterator: IteratorProtocol, Sendable {
        @usableFromInline let graph: FunctionalGraph
        @usableFromInline let start: Int
        @usableFromInline var tortoise: Int
        @usableFromInline var hare: Int
        @usableFromInline var power = 1
        @usableFromInline var cycleLength = 1
        @usableFromInline var count = 0
        @usableFromInline var teleported = false
        /// 0 before the first step, 1 searching for the cycle, 2 putting the hare λ ahead,
        /// 3 seeking the root, 4 done.
        @usableFromInline var phase = 0

        @inlinable
        init(graph: FunctionalGraph, start: Int) {
            self.graph = graph
            self.start = start
            tortoise = start
            hare = start
        }

        @inlinable
        public mutating func next() -> BrentCycleDetectionEvent? {
            switch phase {
            case 0:
                hare = graph.successor(of: start)
                phase = 1
                return .step(tortoise: tortoise, hare: hare)
            case 1:
                if !teleported {
                    if tortoise == hare {
                        tortoise = start
                        hare = start
                        count = 0
                        phase = 2
                        return .cycle(length: cycleLength)
                    }
                    if power == cycleLength {
                        tortoise = hare
                        power *= 2
                        cycleLength = 0
                        teleported = true
                        return .teleport(tortoise, power: power)
                    }
                }
                teleported = false
                hare = graph.successor(of: hare)
                cycleLength += 1
                return .step(tortoise: tortoise, hare: hare)
            case 2:
                if count < cycleLength {
                    hare = graph.successor(of: hare)
                    count += 1
                    return .step(tortoise: tortoise, hare: hare)
                }
                count = 0
                phase = 3
                return next()
            case 3:
                guard tortoise == hare else {
                    tortoise = graph.successor(of: tortoise)
                    hare = graph.successor(of: hare)
                    count += 1
                    return .step(tortoise: tortoise, hare: hare)
                }
                phase = 4
                return .root(tortoise, tailLength: count)
            default:
                return nil
            }
        }
    }
}

extension LazyDirectedGraphView where Base == FunctionalGraph {
    /// Floyd's tortoise-and-hare cycle detection from `start`, as
    /// `floydCycleDetection(from:successor:)` runs it, as a sequence of events: the runners'
    /// positions after each step, their meeting, the first vertex on the cycle with the tail's
    /// length, and the cycle's length. See `FloydCycleDetectionEvent` for the order.
    ///
    /// - Precondition: `start` is in `0..<vertexCount`.
    /// - Complexity: O(μ + λ) events for tail length μ and cycle length λ; O(1) memory.
    @inlinable
    public func floydCycleDetection(from start: Int) -> FloydCycleDetection {
        FloydCycleDetection(graph: base, start: start)
    }

    /// Brent's cycle detection from `start`, as `brentCycleDetection(from:successor:)` runs it,
    /// as a sequence of events: the runners' positions after each step, each teleport of the
    /// tortoise, the cycle's length, and the first vertex on the cycle with the tail's length. See
    /// `BrentCycleDetectionEvent` for the order.
    ///
    /// - Precondition: `start` is in `0..<vertexCount`.
    /// - Complexity: O(μ + λ) events for tail length μ and cycle length λ; O(1) memory.
    @inlinable
    public func brentCycleDetection(from start: Int) -> BrentCycleDetection {
        BrentCycleDetection(graph: base, start: start)
    }
}
