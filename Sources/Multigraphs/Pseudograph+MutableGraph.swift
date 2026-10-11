import AdjacencyListModule
import GraphProtocols

// MARK: - MutableGraph

extension Pseudograph: MutableGraph {
    /// The slot of `vertex`, or `nil`. One hash.
    @inlinable public func _key(of vertex: Vertex) -> Int? { _slots[vertex] }

    @inlinable public mutating func _insertVertex(_ vertex: Vertex) -> Int { _appendSlot(for: vertex) }

    /// Always a new copy, at position `edgeCount`, stored `u` first.
    @inlinable
    public mutating func _insertEdge(fromKey u: Int, toKey v: Int) -> Int {
        _insertEdge(slots: u, v)
    }
}
