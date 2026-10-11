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

extension DirectedAcyclicGraph {
    /// `base` with its `vertices` order reversed as the topological order, for a builder that made
    /// every edge from a vertex to an earlier one (a condensation, whose components come in
    /// reverse topological order): unchecked, so it runs no Kahn pass and reads no edge. O(n), no
    /// hashing. The mirror of `init(_vertexOrderedBase:)`.
    ///
    /// - Precondition: every edge of `base` goes from a vertex to one before it in `vertices`.
    @inlinable
    package init(_reverseVertexOrderedBase base: Base) {
        var table = _KeyTable()
        var order = ContiguousArray<Int>()
        order.reserveCapacity(base.vertexCount)
        for key in base.vertices.indices { order.append(key) }
        // The table is filled in key order (it grows at the back from its first key's page);
        // the vertex at offset i of `vertices` takes the label n − 1 − i.
        let n = order.count
        for (offset, key) in order.enumerated() { table.insert(key, label: n &- 1 &- offset) }
        order.reverse()
        self.init(_base: base, order: order, table: table)
    }
}
