// snippet: euler-imports
import GraphProtocols
import Multigraphs
import Tours
import Walks
// snippet end

// The cities of the Euler tours page and the calls it makes. The marked region is its code panel.

/// A city of land and bridges as a multigraph: the parallel bridges stay separate edges.
func eulerCity(_ bridges: [UndirectedEdge<String>]) -> Multigraph<String> {
    // snippet: euler-city
    let city = Multigraph<String> {
        for bridge in bridges { bridge }
    }!
    // snippet end
    return city
}

/// What Grafluent says about `city`: the places with an odd number of bridges, its Eulerian
/// circuit and its Eulerian trail.
func eulerAnswers(_ city: Multigraph<String>) -> (odd: [String], circuit: Circuit<String, Int>?, trail: Trail<String, Int>?) {
    // snippet: euler-tour
    let odd = city.vertices.filter { city.degree(of: $0) % 2 == 1 }  // →
    let circuit = city.eulerianCircuit()                              // →
    let trail = city.eulerianTrail()                                  // →
    // snippet end
    return (odd, circuit, trail)
}
