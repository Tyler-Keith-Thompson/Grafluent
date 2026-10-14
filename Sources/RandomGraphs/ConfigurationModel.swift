import GraphProtocols
import Multigraphs

/// The stubs of a degree sequence, `count` copies of each vertex in order, after checking it.
@inlinable
func _stubs(_ degrees: some Collection<Int>, _ name: StaticString) -> [Int] {
    var total = 0
    for d in degrees {
        precondition(d >= 0, "\(name) has a negative degree \(d)")
        precondition(total <= Int.max - d, "degree sum overflows Int")
        total += d
    }
    var stubs: [Int] = []
    stubs.reserveCapacity(total)
    var v = 0
    for d in degrees {
        stubs.append(contentsOf: repeatElement(v, count: d))
        v += 1
    }
    return stubs
}

/// A Fisher–Yates shuffle: i from the last index down to 1, swapped with `below(i + 1)`.
@inlinable
func _shuffle<G: RandomNumberGenerator>(_ values: inout [Int], _ g: inout G) {
    values.withUnsafeMutableBufferPointer { values in
        var i = values.count - 1
        while i >= 1 {
            values.swapAt(i, _below(i + 1, &g))
            i -= 1
        }
    }
}

extension Pseudograph where Vertex == Int {
    /// A random pseudograph with these degrees, by the configuration model: vertex i gets
    /// `degreeSequence[i]` stubs, the stubs are shuffled, and the k-th stub of the first half is
    /// paired with the k-th of the second half. Every pairing of the stubs is equally likely, so
    /// self-loops and parallel edges occur; a self-loop counts 2 toward its vertex's degree, and
    /// every vertex has exactly its degree. The edges are at positions `0..<m` in pairing order,
    /// each written (first-half end, second-half end). The shuffle is Fisher–Yates, i from the
    /// last stub down to 1 swapped with `below(i + 1)`.
    ///
    /// > Béla Bollobás. A probabilistic proof of an asymptotic formula for the number of labelled
    /// > regular graphs. *European Journal of Combinatorics* 1(4), 311–316 (1980).
    /// > doi:10.1016/S0195-6698(80)80030-8
    ///
    /// - Complexity: O(n + m) expected.
    /// - Precondition: no degree is negative, and their sum is even and fits in `Int`.
    @inlinable
    public static func configurationModel(
        degreeSequence: some Collection<Int>, using generator: inout some RandomNumberGenerator
    ) -> Pseudograph {
        var stubs = _stubs(degreeSequence, "degreeSequence")
        precondition(stubs.count.isMultiple(of: 2), "the degree sum \(stubs.count) is odd")
        _shuffle(&stubs, &generator)
        let half = stubs.count / 2
        // The rows by counting sort, as inserting the pairs in order would leave them.
        return _built(vertices: ContiguousArray(0 ..< degreeSequence.count), uKeys: Array(stubs[..<half]), vKeys: Array(stubs[half...]),
                      reportingPositions: false, _ConstructionToken()).graph
    }

    /// `configurationModel(degreeSequence:using:)` with the system's random number generator.
    @inlinable
    public static func configurationModel(degreeSequence: some Collection<Int>) -> Pseudograph {
        var generator = SystemRandomNumberGenerator()
        return configurationModel(degreeSequence: degreeSequence, using: &generator)
    }
}

extension DirectedPseudograph where Vertex == Int {
    /// A random directed pseudograph with these degrees, by the directed configuration model:
    /// vertex i gets `outDegrees[i]` out-stubs and `inDegrees[i]` in-stubs, both lists are
    /// shuffled (the out-stubs first), and the k-th out-stub is joined to the k-th in-stub. Every
    /// matching of out-stubs to in-stubs is equally likely, so self-loops and parallel arcs occur,
    /// and every vertex has exactly its in- and out-degree. The arcs are at positions `0..<m` in
    /// matching order. Each shuffle is the undirected form's Fisher–Yates.
    ///
    /// - Complexity: O(n + m) expected.
    /// - Precondition: the two sequences have the same count, no degree is negative, and the sums
    ///   are equal and fit in `Int`.
    @inlinable
    public static func configurationModel(
        inDegrees: some Collection<Int>, outDegrees: some Collection<Int>, using generator: inout some RandomNumberGenerator
    ) -> DirectedPseudograph {
        let n = inDegrees.count
        precondition(outDegrees.count == n, "inDegrees.count \(n) != outDegrees.count \(outDegrees.count)")
        var sources = _stubs(outDegrees, "outDegrees")
        var targets = _stubs(inDegrees, "inDegrees")
        precondition(sources.count == targets.count, "the in-degree sum \(targets.count) != the out-degree sum \(sources.count)")
        _shuffle(&sources, &generator)
        _shuffle(&targets, &generator)
        return _built(vertices: ContiguousArray(0 ..< n), sourceKeys: sources, targetKeys: targets, reportingPositions: false,
                      _ConstructionToken()).graph
    }

    /// `configurationModel(inDegrees:outDegrees:using:)` with the system's random number
    /// generator.
    @inlinable
    public static func configurationModel(inDegrees: some Collection<Int>, outDegrees: some Collection<Int>) -> DirectedPseudograph {
        var generator = SystemRandomNumberGenerator()
        return configurationModel(inDegrees: inDegrees, outDegrees: outDegrees, using: &generator)
    }
}
