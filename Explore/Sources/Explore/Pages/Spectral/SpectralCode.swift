// snippet: spectral-imports
import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import SpectralGraphTheory
// snippet end

// Two circles of friends and the calls the spectral page makes. The marked regions are its code
// panels.

// snippet: spectral-friends
let insideTies = [
    UndirectedEdge("Ana", "Cy"), UndirectedEdge("Ana", "Dee"), UndirectedEdge("Ana", "Eli"),
    UndirectedEdge("Ben", "Dee"), UndirectedEdge("Ben", "Fay"), UndirectedEdge("Cy", "Dee"),
    UndirectedEdge("Cy", "Eli"), UndirectedEdge("Cy", "Fay"),
    UndirectedEdge("Gus", "Hal"), UndirectedEdge("Gus", "Kai"), UndirectedEdge("Hal", "Lea"),
    UndirectedEdge("Ivy", "Jo"), UndirectedEdge("Ivy", "Mo"), UndirectedEdge("Jo", "Lea"),
    UndirectedEdge("Jo", "Mo"), UndirectedEdge("Kai", "Mo"), UndirectedEdge("Lea", "Mo"),
]
let crossLinks = [UndirectedEdge("Cy", "Gus"), UndirectedEdge("Fay", "Jo"), UndirectedEdge("Eli", "Hal")]
// snippet end

/// The two circles with the links in `open` between them.
func circles(open: [UndirectedEdge<String>]) -> UndirectedAdjacencyList<String> {
    // snippet: spectral-circles
    let circles = UndirectedAdjacencyList<String> {
        for tie in insideTies { tie }
        for link in crossLinks where open.contains(link) { link }
    }
    // snippet end
    return circles
}

/// The spectral drawing of `circles`.
func spectralDrawing(_ circles: UndirectedAdjacencyList<String>) throws -> Drawing<String> {
    // snippet: spectral-layout
    let drawing = try circles.spectralLayout()
    // snippet end
    return drawing
}

/// λ₂, each person's Fiedler value, and the side of the sign split each is on; nil when the
/// circles are not joined.
func fiedlerSplit(_ circles: UndirectedAdjacencyList<String>) throws -> (connectivity: Double, values: [Double], negative: [String])? {
    // snippet: spectral-fiedler
    guard let fiedler = try circles.fiedlerVector() else { return nil }
    let connectivity = fiedler.algebraicConnectivity                     // →
    let negative = circles.vertices.filter { fiedler.value(of: $0) < 0 }  // →
    // snippet end
    return (connectivity, circles.vertices.map { fiedler.value(of: $0) }, negative)
}

/// The people from one end of the Fiedler vector to the other.
func fiedlerOrder(_ circles: UndirectedAdjacencyList<String>) throws -> [String] {
    // snippet: spectral-ordering
    let order = try circles.spectralOrdering()  // →
    // snippet end
    return order
}
