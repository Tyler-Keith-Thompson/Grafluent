// snippet: planarity-imports
import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import Planarity
// snippet end

// The graphs of the planarity page and the questions it asks of them. The marked region is its
// code panel.

/// What Grafluent says about `places` joined by the first `added` of `links`: whether it is
/// planar, a Kuratowski subgraph when it is not, a crossing-free drawing when it is, and the
/// number of faces of its embedding.
func planarity(places: [String], links: [UndirectedEdge<String>], added: Int)
    -> (graph: UndirectedAdjacencyList<String>, planar: Bool, witness: KuratowskiSubgraph<UndirectedAdjacencyList<String>>?, drawing: Drawing<String>?, faces: Int?) {
    // snippet: planarity-test
    let graph = UndirectedAdjacencyList<String> {
        for place in places { place }
        for link in links.prefix(added) { link }
    }
    let planar = graph.isPlanar                      // →
    let witness = graph.findKuratowskiSubgraph()     // →
    let drawing = graph.planarLayout()               // →
    let faces = graph.planarEmbedding()?.faceCount   // →
    // snippet end
    return (graph, planar, witness, drawing, faces)
}
