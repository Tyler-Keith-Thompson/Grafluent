import GraphProtocols
import Multigraphs
import Planarity

/// Planarity on the case's edges as an undirected multigraph (a directed case's arcs as edges,
/// loops kept): the yes/no answers, the embedding's face count and whether it passes the
/// definitions (each clockwise order a permutation of the incident edges from the first, every
/// position on two face sides), and the witness as pairs with its kind.
struct PlanarityAnswers: Encodable {
    var isPlanar = false
    var isOuterplanar = false
    var faceCount: Int?
    var embeddingValid = true
    var witnessKind: String?
    var witnessPairs: [[Int]]?
    var consistent = true
}

func planarityAnswers(n: Int, edges: [[Int]]) -> PlanarityAnswers {
    let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
    var a = PlanarityAnswers()
    a.isPlanar = graph.isPlanar
    a.isOuterplanar = graph.isOuterplanar
    let embedding = graph.planarEmbedding()
    let witness = graph.findKuratowskiSubgraph()
    a.consistent = (embedding != nil) == a.isPlanar && (witness == nil) == a.isPlanar
    if let embedding {
        a.faceCount = embedding.faceCount
        for v in 0 ..< n {
            let row = Array(embedding.clockwiseIncidentEdges(of: v)), incident = Array(graph.incidentEdges(of: v))
            if row.sorted() != incident.sorted() || row.first != incident.first { a.embeddingValid = false }
        }
        var sides = [Int](repeating: 0, count: edges.count)
        for face in embedding.faces { for p in face.edges { sides[p] += 1 } }
        if !sides.allSatisfy({ $0 == 2 }) { a.embeddingValid = false }
    }
    if let witness {
        a.witnessKind = witness.kind == .k5 ? "K5" : "K33"
        a.witnessPairs = witness.edges.map { [edges[$0][0], edges[$0][1]] }
    }
    return a
}
