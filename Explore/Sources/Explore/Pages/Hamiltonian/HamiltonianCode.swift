// snippet: hamiltonian-imports
import AdjacencyListModule
import GraphProtocols
import Tours
import Walks
// snippet end

// Hamilton's icosian game and the calls the Hamiltonian page makes. The marked regions are its
// code panels.

// snippet: hamiltonian-board
// The dodecahedron flattened: an outer ring of five, a middle ring of ten, an inner ring of
// five, named with Hamilton's twenty consonants.
let outerRing = ["B", "C", "D", "F", "G"]
let middleRing = ["H", "J", "K", "L", "M", "N", "P", "Q", "R", "S"]
let innerRing = ["T", "V", "W", "X", "Z"]

let icosian = UndirectedAdjacencyList<String> {
    for i in 0 ..< 5 { UndirectedEdge(outerRing[i], outerRing[(i + 1) % 5]) }
    for i in 0 ..< 5 { UndirectedEdge(outerRing[i], middleRing[2 * i]) }
    for i in 0 ..< 10 { UndirectedEdge(middleRing[i], middleRing[(i + 1) % 10]) }
    for i in 0 ..< 5 { UndirectedEdge(middleRing[2 * i + 1], innerRing[i]) }
    for i in 0 ..< 5 { UndirectedEdge(innerRing[i], innerRing[(i + 1) % 5]) }
}
// snippet end

/// Grafluent's Hamiltonian cycle of the board.
func icosianCycle() -> Cycle<String, Int>? {
    // snippet: hamiltonian-cycle
    let cycle = icosian.hamiltonianCycle()  // →
    // snippet end
    return cycle
}

/// A way to finish a route that starts at `first`, has reached `current`, and has passed through
/// `inside` on the way: a Hamiltonian path of what is left, from `current` back to `first`.
func icosianFinish(first: String, current: String, inside: Set<String>) -> Path<String, Int>? {
    // snippet: hamiltonian-finish
    let left = UndirectedAdjacencyList<String> {
        for town in icosian.vertices where !inside.contains(town) { town }
        for road in icosian.edges where !inside.contains(road.u) && !inside.contains(road.v) { road }
    }
    let finish = left.hamiltonianPath(from: current, to: first)  // →
    // snippet end
    return finish
}
