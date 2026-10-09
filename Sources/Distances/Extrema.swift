/// What a bounding run must decide.
@usableFromInline
enum _ExtremaGoal: Sendable {
    case eccentricities, diameter, radius, center, periphery
}

/// Takes and Kosters' bounding (NetworkX `_extrema_bounding`), for undirected unweighted graphs:
/// each search from `c`, of eccentricity `e`, bounds every candidate `i` by
/// `max(d(i), e − d(i)) ≤ ecc(i) ≤ e + d(i)`, and candidates whose bounds settle the goal leave.
/// Searches alternate between the candidate of least lower bound and the one of greatest upper
/// bound (ties: greater degree, then lower index). Nil when the graph is not connected.
@inlinable
func _bounding(_ rows: _DistanceRows, _ goal: _ExtremaGoal) -> (lower: [Int], upper: [Int], minUpper: Int, maxLower: Int)? {
    let n = rows.count
    guard n > 0 else { return ([], [], 0, 0) }
    var searches = _BreadthFirstSearches(rows)
    var lower = [Int](repeating: 0, count: n), upper = [Int](repeating: n, count: n)
    var candidates = Array(0 ..< n)
    var minLower = n, maxLower = 0, minUpper = n, maxUpper = 0
    let degrees = (0 ..< n).map { rows.degree($0) }
    var start = 0
    for v in 1 ..< max(n, 1) where degrees[v] > degrees[start] { start = v }
    var minLowerVertex = start, maxUpperVertex = start
    var high = false
    while !candidates.isEmpty {
        let current = high ? maxUpperVertex : minLowerVertex
        high.toggle()
        let (e, reachedAll, _) = searches.search(from: current)
        guard reachedAll else { return nil }
        // One pass over flat buffers with plain loops and comparisons: this runs once per
        // search over every candidate, n² steps on a cycle, so even a debug build must keep it
        // free of generic iteration and checked subscripts.
        var kept = 0
        searches.distance.withUnsafeBufferPointer { distance in
            lower.withUnsafeMutableBufferPointer { lower in
                upper.withUnsafeMutableBufferPointer { upper in
                    candidates.withUnsafeMutableBufferPointer { candidates in
                        degrees.withUnsafeBufferPointer { degree in
                            let count = candidates.count
                            var k = 0
                            while k < count {
                                let i = candidates[k]
                                let d = distance[i]
                                var low = lower[i]
                                if d > low { low = d }
                                if e - d > low { low = e - d }
                                var up = upper[i]
                                if e + d < up { up = e + d }
                                lower[i] = low
                                upper[i] = up
                                if low < minLower { minLower = low }
                                if low > maxLower { maxLower = low }
                                if up < minUpper { minUpper = up }
                                if up > maxUpper { maxUpper = up }
                                k += 1
                            }
                            k = 0
                            while k < count {
                                let i = candidates[k]
                                let low = lower[i], up = upper[i]
                                var out = low == up
                                if !out {
                                    switch goal {
                                    case .eccentricities: break
                                    case .diameter: out = up <= maxLower && 2 * low >= maxUpper
                                    case .radius: out = low >= minUpper && up + 1 <= 2 * minLower
                                    case .periphery: out = up < maxLower && (maxLower == maxUpper || low > maxUpper)
                                    case .center: out = low > minUpper && (minLower == minUpper || up + 1 < 2 * minLower)
                                    }
                                }
                                if !out {
                                    // The next sources: least lower bound and greatest upper bound,
                                    // ties to greater degree, then lower index (first kept).
                                    if kept == 0 {
                                        minLowerVertex = i
                                        maxUpperVertex = i
                                    } else {
                                        let lm = lower[minLowerVertex]
                                        if low < lm || (low == lm && degree[i] > degree[minLowerVertex]) { minLowerVertex = i }
                                        let um = upper[maxUpperVertex]
                                        if up > um || (up == um && degree[i] > degree[maxUpperVertex]) { maxUpperVertex = i }
                                    }
                                    candidates[kept] = i
                                    kept += 1
                                }
                                k += 1
                            }
                        }
                    }
                }
            }
        }
        candidates.removeLast(candidates.count - kept)
    }
    return (lower, upper, minUpper, maxLower)
}

/// Every eccentricity by breadth-first search from every vertex; nil where some vertex is not
/// reached. Undirected, one miss makes every eccentricity infinite; directed, a vertex reached by
/// a search that misses a vertex misses it too, so its search is skipped. `stopAtMiss` returns at
/// the first infinite eccentricity (for the diameter).
@inlinable
func _allEccentricities(_ rows: _DistanceRows, stopAtMiss: Bool = false) -> [Int?] {
    let n = rows.count
    var result = [Int?](repeating: nil, count: n)
    var known = [Bool](repeating: false, count: n)
    var searches = _BreadthFirstSearches(rows)
    for s in 0 ..< n where !known[s] {
        let (e, reachedAll, _) = searches.search(from: s)
        known[s] = true
        if reachedAll {
            result[s] = e
            continue
        }
        if rows.undirected || stopAtMiss { return [Int?](repeating: nil, count: n) }
        for v in searches.reachedVertices { known[v] = true }
    }
    return result
}

/// The same with weights, by Dijkstra's algorithm.
@inlinable
func _allEccentricities<W: Comparable & AdditiveArithmetic>(_ rows: _DistanceRows, weights: [W], stopAtMiss: Bool = false) -> [W?] {
    let n = rows.count
    var result = [W?](repeating: nil, count: n)
    var known = [Bool](repeating: false, count: n)
    var searches = _DijkstraSearches(rows, weights: weights)
    for s in 0 ..< n where !known[s] {
        let (e, reachedAll, _) = searches.search(from: s)
        known[s] = true
        if reachedAll {
            result[s] = e
            continue
        }
        if rows.undirected || stopAtMiss { return [W?](repeating: nil, count: n) }
        for v in 0 ..< n where searches.reached[v] == searches.round { known[v] = true }
    }
    return result
}

/// The least and greatest eccentricity, nil standing for infinity: the radius is nil when every
/// eccentricity is, the diameter when any is.
@inlinable
func _radiusAndDiameter<W: Comparable>(_ eccentricities: [W?]) -> (radius: W?, diameter: W?) {
    var radius: W?, diameter: W?
    var infinite = false
    for e in eccentricities {
        guard let e else {
            infinite = true
            continue
        }
        if radius.map({ e < $0 }) ?? true { radius = e }
        if diameter.map({ e > $0 }) ?? true { diameter = e }
    }
    return (radius, infinite ? nil : diameter)
}

/// The vertex numbers whose value equals `target`, nil equal to nil, in index order.
@inlinable
func _matching<W: Equatable>(_ values: [W?], _ target: W?) -> [Int] {
    values.indices.filter { values[$0] == target }
}

/// Each vertex's total distance to every other, nil when it does not reach them all, by
/// searches from every vertex (pruned as `_allEccentricities`).
@inlinable
func _totals(_ rows: _DistanceRows) -> [Int?] {
    let n = rows.count
    var result = [Int?](repeating: nil, count: n)
    var known = [Bool](repeating: false, count: n)
    var searches = _BreadthFirstSearches(rows)
    for s in 0 ..< n where !known[s] {
        let (_, reachedAll, total) = searches.search(from: s)
        known[s] = true
        if reachedAll {
            result[s] = total
            continue
        }
        if rows.undirected { return [Int?](repeating: nil, count: n) }
        for v in searches.reachedVertices { known[v] = true }
    }
    return result
}

@inlinable
func _totals<W: Comparable & AdditiveArithmetic>(_ rows: _DistanceRows, weights: [W]) -> [W?] {
    let n = rows.count
    var result = [W?](repeating: nil, count: n)
    var known = [Bool](repeating: false, count: n)
    var searches = _DijkstraSearches(rows, weights: weights)
    for s in 0 ..< n where !known[s] {
        let (_, reachedAll, total) = searches.search(from: s)
        known[s] = true
        if reachedAll {
            result[s] = total
            continue
        }
        if rows.undirected { return [W?](repeating: nil, count: n) }
        for v in 0 ..< n where searches.reached[v] == searches.round { known[v] = true }
    }
    return result
}

/// The least totals' vertices, nil (infinite) for all when every total is.
@inlinable
func _leastTotals<W: Comparable>(_ totals: [W?]) -> [Int] {
    var least: W?
    for t in totals {
        guard let t else { continue }
        if least.map({ t < $0 }) ?? true { least = t }
    }
    return _matching(totals, least)
}

/// The Wiener index: sources in index order, each source's targets in index order (only later
/// ones when undirected), one running total; nil when some pair is not connected.
@inlinable
func _wienerIndex(_ rows: _DistanceRows) -> Int? {
    // Integer sums are exact in any order: each search's own total, halved when every pair is
    // counted from both ends.
    let n = rows.count
    var searches = _BreadthFirstSearches(rows)
    var total = 0
    for s in 0 ..< n {
        let (_, reachedAll, sum) = searches.search(from: s)
        guard reachedAll else { return nil }
        total += sum
    }
    return rows.undirected ? total / 2 : total
}

@inlinable
func _wienerIndex<W: Comparable & AdditiveArithmetic>(_ rows: _DistanceRows, weights: [W]) -> W? {
    let n = rows.count
    var searches = _DijkstraSearches(rows, weights: weights)
    var total = W.zero
    for s in 0 ..< n {
        let (_, reachedAll, _) = searches.search(from: s)
        guard reachedAll else { return nil }
        for t in (rows.undirected ? s + 1 : 0) ..< n where t != s { total += searches.distance[t] }
    }
    return total
}

/// The pairs a Wiener index sums over.
@inlinable
func _pairCount(_ n: Int, undirected: Bool) -> Int { undirected ? n * (n - 1) / 2 : n * (n - 1) }
