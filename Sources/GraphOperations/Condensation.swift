import CompressedSparseRowModule
import Connectivity
import DirectedAcyclicGraphModule
import GraphProtocols

extension DirectedAcyclicGraph where Base: _DirectedGraphConstruction {
    /// The condensation of a graph as a `DirectedAcyclicGraph`: vertex `i` is
    /// `condensation.components[i]`, and its edges are `condensation.graph`'s, built in one bulk
    /// step through the base's construction hook.
    ///
    /// Every condensation edge goes from a later component to an earlier one (Tarjan's order,
    /// reverse topological), so the topological order is `n − 1, …, 0` and needs no sort.
    /// O(k + e) for k components and e condensation edges.
    @inlinable
    public init<G>(_ condensation: Condensation<G>) {
        let graph = condensation.graph
        let base = Base(_vertexCount: graph.vertexCount, sortedEdges: graph.edges, _ConstructionToken())
        self.init(_reverseVertexOrderedBase: base)
    }
}
