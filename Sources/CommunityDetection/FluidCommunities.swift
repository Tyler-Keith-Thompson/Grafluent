import GraphProtocols

/// Asynchronous fluid communities in index space (Parés et al. 2017): `k` communities seeded at the
/// first k vertices of a shuffled order, each with density 1 / size; sweeps in shuffled orders, each
/// vertex taking the community of greatest summed density over itself and its neighbors (sums within
/// 10⁻⁴ of the greatest tie), keeping its own on a tie and otherwise drawing among the tied ones in
/// order of first appearance (itself, then its row), until a sweep changes nothing or `iterations`
/// sweeps have run. A vertex no community reached is alone. Returns a label per vertex.
@inlinable
func _fluidCommunities<R: RandomNumberGenerator>(_ rows: _MergedRows, k: Int, iterations: Int, using generator: inout R) -> [Int] {
    let n = rows.count
    var community = [Int](repeating: -1, count: n)
    var size = [Int](repeating: 0, count: k)
    var density = [Double](repeating: 0, count: k)
    let seeds = Array(_shuffledOrder(n, &generator).prefix(k))
    for (c, v) in seeds.enumerated() {
        community[v] = c
        size[c] = 1
        density[c] = 1
    }
    var total = [Double](repeating: 0, count: k)
    var stamp = [Int](repeating: -1, count: k)
    var touched: [Int] = []
    var best: [Int] = []
    var step = 0
    var sweep = 0
    var changed = true
    while changed, sweep < iterations {
        changed = false
        sweep += 1
        for v in _shuffledOrder(n, &generator) {
            step += 1
            touched.removeAll(keepingCapacity: true)
            let own = community[v]
            if own >= 0 {
                stamp[own] = step
                total[own] = density[own]
                touched.append(own)
            }
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] {
                let c = community[rows.neighbors[slot]]
                guard c >= 0 else { continue }
                if stamp[c] != step {
                    stamp[c] = step
                    total[c] = 0
                    touched.append(c)
                }
                total[c] += density[c]
            }
            guard !touched.isEmpty else { continue }
            var most = total[touched[0]]
            for c in touched where total[c] > most { most = total[c] }
            best.removeAll(keepingCapacity: true)
            var keeps = false
            for c in touched where most - total[c] < 1e-4 {
                best.append(c)
                if c == own { keeps = true }
            }
            guard !keeps else { continue }
            changed = true
            let chosen = best[Int(generator.next(upperBound: UInt(best.count)))]
            if own >= 0 {
                size[own] -= 1
                density[own] = size[own] > 0 ? 1 / Double(size[own]) : 0
            }
            community[v] = chosen
            size[chosen] += 1
            density[chosen] = 1 / Double(size[chosen])
        }
    }
    // Labels below n for the partition: each community's seed, or the vertex itself.
    return (0 ..< n).map { community[$0] < 0 ? $0 : seeds[community[$0]] }
}

extension Graph {
    @inlinable
    func _asynchronousFluidCommunities<R: RandomNumberGenerator>(count k: Int, iterations: Int, using generator: inout R) -> Partition<DirectedView<Self>> {
        precondition(iterations >= 1, "The number of iterations must be at least one")
        precondition(k >= 1 && k <= vertexCount, "The number of communities must be in 1 ... vertexCount")
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let rows = _mergedRows(nil)
        // Connected: one search from vertex 0.
        var seen = [Bool](repeating: false, count: rows.count)
        var stack = [0]
        seen[0] = true
        var reached = 1
        while let v = stack.popLast() {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] where !seen[rows.neighbors[slot]] {
                seen[rows.neighbors[slot]] = true
                reached += 1
                stack.append(rows.neighbors[slot])
            }
        }
        precondition(reached == rows.count, "Fluid communities need a connected graph")
        let labels = _fluidCommunities(rows, k: k, iterations: iterations, using: &generator)
        return Partition(directedView, numbers: numbers, listed: listed, labels: labels)
    }

    /// Asynchronous fluid communities (Parés, Garcia-Gasulla, Vilalta, Moreno, Ayguadé, Labarta,
    /// Cortés and Suzumura 2017): `count` communities, seeded at random vertices, flow through the
    /// graph. Each community has density 1 / its size; in each sweep (in a shuffled order) a vertex
    /// joins the community of greatest summed density over itself and its neighbors, keeping its own
    /// on a tie (within 10⁻⁴) and otherwise choosing among the tied ones at random. Sweeps repeat
    /// until one changes nothing, or `iterations` of them. Parallel edges count once; self-loops
    /// do not count.
    ///
    /// - Parameters:
    ///   - count: the number of communities, k; a community can empty out, so the result can
    ///     have fewer.
    ///   - iterations: at most this many sweeps.
    ///   - generator: shuffles the seeds and each sweep's order (one shuffle of every vertex
    ///     number each) and draws among ties.
    /// - Returns: the communities, in canonical order; a vertex no community reached before the
    ///   sweeps ran out is alone.
    /// - Complexity: O(n + m) per sweep.
    /// - Precondition: the graph is connected; `count` is in 1 ... `vertexCount`; `iterations` is
    ///   at least 1.
    @inlinable
    public func asynchronousFluidCommunities(count: Int, iterations: Int = 100, using generator: inout some RandomNumberGenerator) -> Partition<DirectedView<Self>> {
        _asynchronousFluidCommunities(count: count, iterations: iterations, using: &generator)
    }

    /// Asynchronous fluid communities drawing from the system's random number generator.
    ///
    /// - Precondition: the graph is connected; `count` is in 1 ... `vertexCount`; `iterations` is
    ///   at least 1.
    @inlinable
    public func asynchronousFluidCommunities(count: Int, iterations: Int = 100) -> Partition<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return _asynchronousFluidCommunities(count: count, iterations: iterations, using: &generator)
    }
}
