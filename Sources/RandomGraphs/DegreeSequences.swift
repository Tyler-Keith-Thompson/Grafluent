import GraphProtocols
import NamedGraphs

// Degree sequences: the graphicality tests (Erdős–Gallai, Fulkerson–Chen–Anstee) and the
// deterministic Havel–Hakimi constructions. Vertex i has degree `degreeSequence[i]`.

/// Whether some simple undirected graph on `degreeSequence.count` vertices has these degrees:
/// vertex i of degree `degreeSequence[i]`. This is the Erdős–Gallai test,
///
/// > Paul Erdős and Tibor Gallai. Gráfok előírt fokszámú pontokkal. *Matematikai Lapok* 11,
/// > 264–274 (1960),
///
/// in the linear-time form of Zverovich and Zverovich, which checks the inequalities only at the
/// ends of runs of equal degrees and accepts at once when the minimum degree is large enough:
///
/// > Igor E. Zverovich and Vadim E. Zverovich. Contributions to the theory of graphic sequences.
/// > *Discrete Mathematics* 105(1–3), 293–303 (1992). doi:10.1016/0012-365X(92)90152-6
///
/// A negative degree, or one of `count` or more, makes the sequence not graphical; so does an
/// odd sum. The empty sequence is graphical.
///
/// - Complexity: O(n).
@inlinable
public func isGraphical(_ degreeSequence: some Collection<Int>) -> Bool {
    let p = degreeSequence.count
    // The number of vertices of each nonzero degree.
    var counts = [Int](repeating: 0, count: p)
    var largest = 0, smallest = p, sum = 0, n = 0
    for d in degreeSequence {
        if d < 0 || d >= p { return false }
        if d > 0 {
            largest = Swift.max(largest, d)
            smallest = Swift.min(smallest, d)
            sum += d
            n += 1
            counts[d] += 1
        }
    }
    // n ≤ p, and an array of p elements fits in memory, so n(n − 1) fits in `Int`.
    if !sum.isMultiple(of: 2) || sum > n * (n - 1) { return false }
    // Zverovich–Zverovich: a sequence with 4·dmin·n ≥ (dmax + dmin + 1)² is graphical.
    if n == 0 || 4 * smallest * n >= (largest + smallest + 1) * (largest + smallest + 1) { return true }
    // Erdős–Gallai at each run end up to the Durfee number: Σᵢ≤ₖ dᵢ ≤ k(k − 1) + Σᵢ>ₖ min(dᵢ, k),
    // with the right side as k(n − 1) − k·Σⱼ<ₖ nⱼ + Σⱼ<ₖ j·nⱼ for nⱼ the vertices of degree j.
    var k = 0, leading = 0, below = 0, weighted = 0
    var d = largest
    while d >= smallest {
        if d < k + 1 { return true }
        let run = counts[d]
        if run > 0 {
            let taken = d < k + run ? d - k : run
            leading += taken * d
            for v in 0 ..< taken {
                below += counts[k + v]
                weighted += (k + v) * counts[k + v]
            }
            k += taken
            if leading > k * (n - 1) - k * below + weighted { return false }
        }
        d -= 1
    }
    return true
}

/// Whether some simple directed graph on `inDegrees.count` vertices has these degrees: vertex i
/// with in-degree `inDegrees[i]` and out-degree `outDegrees[i]`, with no self-loop and no
/// repeated arc. This is the Fulkerson–Chen–Anstee test,
///
/// > D. R. Fulkerson. Zero-one matrices with zero trace. *Pacific Journal of Mathematics* 10(3),
/// > 831–836 (1960); Wai-Kai Chen. On the realization of a (p, s)-digraph with prescribed
/// > degrees. *Journal of the Franklin Institute* 281(5), 406–422 (1966); Richard P. Anstee.
/// > Properties of a class of (0, 1)-matrix covering problems. *Discrete Mathematics* 41(1),
/// > 1–9 (1982),
///
/// with the vertices ordered by out-degree, non-increasing; the order among equal out-degrees
/// does not change the answer (Annabell Berger, "A note on the characterization of digraphic
/// sequences", *Discrete Mathematics* 314, 38–41, 2014). With a = the out-degrees and b = the
/// in-degrees in that order, it checks Σ a = Σ b and, for each k,
/// Σᵢ≤ₖ aᵢ ≤ Σᵢ≤ₖ min(bᵢ, k − 1) + Σᵢ>ₖ min(bᵢ, k).
/// A negative degree or one of `count` or more makes the pair not digraphical.
///
/// - Complexity: O(n): a counting sort, then one pass.
/// - Precondition: `inDegrees.count == outDegrees.count`.
@inlinable
public func isDigraphical(inDegrees: some Collection<Int>, outDegrees: some Collection<Int>) -> Bool {
    let n = inDegrees.count
    precondition(outDegrees.count == n, "inDegrees.count \(n) != outDegrees.count \(outDegrees.count)")
    var a = [Int](), b = [Int]()
    a.reserveCapacity(n)
    b.reserveCapacity(n)
    var sumIn = 0, sumOut = 0
    for d in inDegrees {
        if d < 0 || d >= n { return false }
        b.append(d)
        sumIn += d
    }
    for d in outDegrees {
        if d < 0 || d >= n { return false }
        a.append(d)
        sumOut += d
    }
    if sumIn != sumOut { return false }
    if n == 0 { return true }
    // The vertices by out-degree, non-increasing: a counting sort.
    var offsets = [Int](repeating: 0, count: n + 1)
    for d in a { offsets[n - 1 - d + 1] += 1 }
    for v in 0 ..< n { offsets[v + 1] += offsets[v] }
    var order = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        let slot = offsets[n - 1 - a[v]]
        offsets[n - 1 - a[v]] = slot + 1
        order[slot] = v
    }
    // The right side is S(k) − c(k): S(k) = Σᵢ min(bᵢ, k) grows by #{i : bᵢ ≥ k}, and
    // c(k) = #{i ≤ k : bᵢ ≥ k} loses the earlier bᵢ equal to k − 1 and gains b_k when b_k ≥ k.
    var atLeast = [Int](repeating: 0, count: n + 1)
    for d in b { atLeast[d] += 1 }
    for d in stride(from: n - 1, through: 0, by: -1) { atLeast[d] += atLeast[d + 1] }
    var prefixCounts = [Int](repeating: 0, count: n)
    var left = 0, minimumSum = 0, covered = 0
    for k in 1 ... n {
        let v = order[k - 1]
        left += a[v]
        minimumSum += atLeast[k]
        covered -= prefixCounts[k - 1]
        if b[v] >= k { covered += 1 }
        prefixCounts[b[v]] += 1
        if left > minimumSum - covered { return false }
    }
    return true
}

/// Havel–Hakimi on degree buckets: each bucket a stack of the vertices with that remaining degree,
/// filled in vertex order. Each round pops a vertex of the
/// largest remaining degree d and joins it to d vertices popped from the highest buckets, then
/// pushes those back one degree lower, in the order they were popped. Pairs sorted.
@usableFromInline
func _havelHakimiPairs(_ degrees: [Int]) -> [DirectedEdge<Int>] {
    precondition(isGraphical(degrees), "degreeSequence is not graphical")
    let p = degrees.count
    // head[d] is the top of bucket d, next[v] the vertex under v.
    var head = [Int](repeating: -1, count: Swift.max(p, 1))
    var next = [Int](repeating: -1, count: p)
    var largest = 0, remaining = 0, sum = 0
    for v in 0 ..< p where degrees[v] > 0 {
        let d = degrees[v]
        next[v] = head[d]
        head[d] = v
        largest = Swift.max(largest, d)
        remaining += 1
        sum += d
    }
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(sum / 2)
    var lowered: [(degree: Int, vertex: Int)] = []
    lowered.reserveCapacity(largest)
    while remaining > 0 {
        while head[largest] < 0 { largest -= 1 }
        let source = head[largest]
        head[largest] = next[source]
        remaining -= 1
        lowered.removeAll(keepingCapacity: true)
        var k = largest
        for _ in 0 ..< largest {
            while head[k] < 0 { k -= 1 }
            let target = head[k]
            head[k] = next[target]
            pairs.append(source < target ? DirectedEdge(from: source, to: target) : DirectedEdge(from: target, to: source))
            remaining -= 1
            if k > 1 { lowered.append((k - 1, target)) }
        }
        for (d, v) in lowered {
            next[v] = head[d]
            head[d] = v
            remaining += 1
        }
    }
    return _sortedRowMajor(p, pairs)
}

/// A key of the directed Havel–Hakimi heaps, (−out, −in, vertex), compared lexicographically.
@frozen
@usableFromInline
struct _DegreeKey: Comparable {
    @usableFromInline var negatedOut: Int
    @usableFromInline var negatedIn: Int
    @usableFromInline var vertex: Int

    @inlinable
    init(negatedOut: Int, negatedIn: Int, vertex: Int) {
        self.negatedOut = negatedOut
        self.negatedIn = negatedIn
        self.vertex = vertex
    }

    @inlinable
    static func < (a: _DegreeKey, b: _DegreeKey) -> Bool {
        (a.negatedOut, a.negatedIn, a.vertex) < (b.negatedOut, b.negatedIn, b.vertex)
    }
}

/// A binary min-heap of distinct keys.
@frozen
@usableFromInline
struct _DegreeHeap {
    @usableFromInline var keys: [_DegreeKey] = []

    @inlinable
    init() {}

    @inlinable
    var isEmpty: Bool { keys.isEmpty }

    @inlinable
    var top: _DegreeKey { keys[0] }

    @inlinable
    mutating func push(_ key: _DegreeKey) {
        keys.append(key)
        var i = keys.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            guard keys[i] < keys[parent] else { break }
            keys.swapAt(i, parent)
            i = parent
        }
    }

    @inlinable
    mutating func pop() -> _DegreeKey {
        let top = keys[0]
        let last = keys.removeLast()
        guard !keys.isEmpty else { return top }
        keys[0] = last
        var i = 0
        let count = keys.count
        while true {
            let l = 2 * i + 1, r = l + 1
            var smallest = i
            if l < count, keys[l] < keys[smallest] { smallest = l }
            if r < count, keys[r] < keys[smallest] { smallest = r }
            if smallest == i { break }
            keys.swapAt(i, smallest)
            i = smallest
        }
        return top
    }
}

/// Kleitman–Wang on in-degrees: one heap of the
/// vertices with in-degree left, keyed (−out, −in, v), and one of those with only out-degree left,
/// keyed (−out, v). Each round pops the first vertex with in-degree left as the target and draws
/// its in-degree's worth of sources, each the first of the two heaps by remaining out-degree (the
/// in-degree heap on ties), then pushes back the sources with degree left. Arcs in row-major
/// order.
@usableFromInline
func _directedHavelHakimiArcs(_ inDegrees: [Int], _ outDegrees: [Int]) -> [DirectedEdge<Int>] {
    precondition(isDigraphical(inDegrees: inDegrees, outDegrees: outDegrees), "the degree sequences are not digraphical")
    let n = inDegrees.count
    var withIn = _DegreeHeap(), outOnly = _DegreeHeap()
    var m = 0
    for v in 0 ..< n {
        if inDegrees[v] > 0 {
            withIn.push(_DegreeKey(negatedOut: -outDegrees[v], negatedIn: -inDegrees[v], vertex: v))
        } else if outDegrees[v] > 0 {
            outOnly.push(_DegreeKey(negatedOut: -outDegrees[v], negatedIn: 0, vertex: v))
        }
        m += inDegrees[v]
    }
    var arcs: [DirectedEdge<Int>] = []
    arcs.reserveCapacity(m)
    var lowered: [_DegreeKey] = []
    while !withIn.isEmpty {
        let target = withIn.pop()
        lowered.removeAll(keepingCapacity: true)
        for _ in 0 ..< -target.negatedIn {
            let source: _DegreeKey
            if !outOnly.isEmpty, withIn.isEmpty || withIn.top.negatedOut > outOnly.top.negatedOut {
                source = outOnly.pop()
            } else {
                source = withIn.pop()
            }
            arcs.append(DirectedEdge(from: source.vertex, to: target.vertex))
            if source.negatedOut + 1 < 0 || source.negatedIn < 0 {
                lowered.append(_DegreeKey(negatedOut: source.negatedOut + 1, negatedIn: source.negatedIn, vertex: source.vertex))
            }
        }
        for key in lowered {
            if key.negatedIn < 0 { withIn.push(key) } else { outOnly.push(key) }
        }
        if target.negatedOut < 0 { outOnly.push(_DegreeKey(negatedOut: target.negatedOut, negatedIn: 0, vertex: target.vertex)) }
    }
    return _sortedRowMajor(n, arcs)
}

extension _GraphConstruction {
    /// The graph the Havel–Hakimi procedure builds on these degrees: vertex i has degree
    /// `degreeSequence[i]`. Each round takes a vertex of the largest remaining degree d and joins
    /// it to d other vertices of the largest remaining degrees, lowering each by one. The vertices
    /// of each remaining degree form a stack, filled in vertex order: a round pops its vertex from
    /// the highest nonempty stack, pops the d others from the highest stacks, and pushes those
    /// back one degree lower in the order it popped them. Deterministic, with no draws. Edges
    /// sorted.
    ///
    /// > Václav Havel. Poznámka o existenci konečných grafů. *Časopis pro pěstování matematiky*
    /// > 80(4), 477–480 (1955); S. Louis Hakimi. On realizability of a set of integers as degrees
    /// > of the vertices of a linear graph I. *Journal of the SIAM* 10(3), 496–506 (1962).
    ///
    /// - Complexity: O(n + m).
    /// - Precondition: `isGraphical(degreeSequence)`.
    @inlinable
    public static func havelHakimi(degreeSequence: some Collection<Int>) -> Self {
        let degrees = Array(degreeSequence)
        let pairs = _havelHakimiPairs(degrees)
        return Self(_vertexCount: degrees.count, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The directed graph the Kleitman–Wang procedure builds on these degrees: vertex i has
    /// in-degree `inDegrees[i]` and out-degree `outDegrees[i]`, with no self-loop or repeated
    /// arc. Each round takes, among the vertices with in-degree left, the one with the most
    /// out-degree left (then the most in-degree, then the smallest index), and joins to it as
    /// many sources as its in-degree: each the vertex with the most out-degree left, preferring on
    /// a tie one with in-degree left (then the most in-degree, then the smallest index).
    /// Deterministic, with no draws. Arcs in row-major order.
    ///
    /// > Daniel J. Kleitman and Da-Lun Wang. Algorithms for constructing graphs and digraphs with
    /// > given valences and factors. *Discrete Mathematics* 6(1), 79–88 (1973).
    /// > doi:10.1016/0012-365X(73)90037-X
    ///
    /// - Complexity: O((n + m) log n).
    /// - Precondition: `isDigraphical(inDegrees: inDegrees, outDegrees: outDegrees)`, which
    ///   includes equal counts.
    @inlinable
    public static func havelHakimi(inDegrees: some Collection<Int>, outDegrees: some Collection<Int>) -> Self {
        let a = Array(inDegrees), b = Array(outDegrees)
        let arcs = _directedHavelHakimiArcs(a, b)
        return Self(_vertexCount: a.count, sortedEdges: arcs, _ConstructionToken())
    }
}
