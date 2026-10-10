/// An algorithm run on capacities converted to a type wide enough for every sum it forms: the
/// global cuts and Gomory–Hu, whose intermediate sums (a contracted group's connection, a
/// vertex's excess) can pass the capacity type although the answer fits.
@usableFromInline
protocol _WideCapacityAlgorithm {
    associatedtype Capacity: Comparable & AdditiveArithmetic
    associatedtype Result

    /// Runs on `wide` (by edge number, self-loops zero), converting a value back with `narrow`,
    /// which traps when it does not fit in `Capacity`.
    func run<K: Comparable & AdditiveArithmetic>(_ wide: [K], _ narrow: (K) -> Capacity) -> Result
}

/// Runs `algorithm` on the capacities in the narrowest exact wide type: for a fixed-width integer
/// type, `Int` when twice the total of the non-loop capacities fits, else `Int128` (exact for
/// every type of up to 64 bits, whose totals stay below 2⁹⁵), else the type itself; `Double` for
/// `Float` and `Double`; any other type as it is.
@inlinable
func _runWide<A: _WideCapacityAlgorithm>(_ algorithm: A, _ edges: _FlowEdges, _ capacities: [A.Capacity]) -> A.Result {
    if let t = A.Capacity.self as? any FixedWidthInteger.Type {
        return _runFixedWidth(t, algorithm, edges, capacities)
    }
    if A.Capacity.self == Double.self {
        return algorithm.run(capacities as! [Double]) { $0 as! A.Capacity }
    }
    if A.Capacity.self == Float.self {
        return algorithm.run((capacities as! [Float]).map { Double($0) }) { Float($0) as! A.Capacity }
    }
    return algorithm.run(capacities) { $0 }
}

@inlinable
func _runFixedWidth<T: FixedWidthInteger, A: _WideCapacityAlgorithm>(_: T.Type, _ algorithm: A, _ edges: _FlowEdges, _ capacities: [A.Capacity]) -> A.Result {
    let typed = capacities as! [T]
    var total = 0
    var fits = true
    var wide = [Int](repeating: 0, count: typed.count)
    for e in typed.indices where edges.tail[e] != edges.head[e] {
        guard let c = Int(exactly: typed[e]) else {
            fits = false
            break
        }
        let (sum, overflow) = total.addingReportingOverflow(c)
        if overflow {
            fits = false
            break
        }
        total = sum
        wide[e] = c
    }
    if fits && total <= Int.max / 2 {
        return algorithm.run(wide) { T($0) as! A.Capacity }
    }
    if T.bitWidth <= 64 {
        var wider = [Int128](repeating: 0, count: typed.count)
        for e in typed.indices where edges.tail[e] != edges.head[e] { wider[e] = Int128(typed[e]) }
        return algorithm.run(wider) { T($0) as! A.Capacity }
    }
    return algorithm.run(capacities) { $0 }
}
