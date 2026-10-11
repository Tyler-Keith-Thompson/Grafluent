import GraphProtocols

extension DirectedAcyclicGraph {
    /// `base` with its `vertices` order as the topological order, for a generator that built every
    /// edge from an earlier vertex to a later one (the Barak–Erdős random DAG): unchecked, so it
    /// runs no Kahn pass and reads no edge. O(n), no hashing.
    ///
    /// - Precondition: every edge of `base` goes from a vertex to one after it in `vertices`.
    @inlinable
    package init(_vertexOrderedBase base: Base) {
        var table = _KeyTable()
        var order = ContiguousArray<Int>()
        order.reserveCapacity(base.vertexCount)
        for key in base.vertices.indices {
            table.insert(key, label: order.count)
            order.append(key)
        }
        self.init(_base: base, order: order, table: table)
    }
}
