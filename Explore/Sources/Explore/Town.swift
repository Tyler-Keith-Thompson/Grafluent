import AdjacencyListModule
import GraphProtocols
import ShortestPaths

// The town: the Swift the code panel shows, run as written. `CodePanel` prints these
// declarations with the values read back from them.

let minutes: [UndirectedEdge<String>: Int] = [
    UndirectedEdge("Home", "Bakery"): 4,
    UndirectedEdge("Home", "Park"): 6,
    UndirectedEdge("Bakery", "Park"): 3,
    UndirectedEdge("Bakery", "School"): 7,
    UndirectedEdge("Park", "Library"): 5,
    UndirectedEdge("School", "Library"): 4,
    UndirectedEdge("School", "Café"): 6,
    UndirectedEdge("Library", "Café"): 3,
    UndirectedEdge("Library", "Station"): 8,
    UndirectedEdge("Café", "Station"): 5,
    UndirectedEdge("Park", "Market"): 6,
    UndirectedEdge("Market", "Station"): 4,
    UndirectedEdge("Library", "Market"): 7,
]

let town = UndirectedAdjacencyList<String> {
    for street in minutes.keys { street }
}

/// The streets in the order the code panel lists them: the order of the dictionary literal above.
let streetOrder: [UndirectedEdge<String>] = [
    UndirectedEdge("Home", "Bakery"), UndirectedEdge("Home", "Park"), UndirectedEdge("Bakery", "Park"),
    UndirectedEdge("Bakery", "School"), UndirectedEdge("Park", "Library"), UndirectedEdge("School", "Library"),
    UndirectedEdge("School", "Café"), UndirectedEdge("Library", "Café"), UndirectedEdge("Library", "Station"),
    UndirectedEdge("Café", "Station"), UndirectedEdge("Park", "Market"), UndirectedEdge("Market", "Station"),
    UndirectedEdge("Library", "Market"),
]

/// Each place and where it sits on the map, in SVG units of the 640 × 520 view box.
let places: [(name: String, x: Int, y: Int)] = [
    ("Home", 80, 290), ("Bakery", 210, 160), ("Park", 230, 370), ("School", 380, 90),
    ("Library", 390, 280), ("Café", 540, 180), ("Market", 370, 450), ("Station", 560, 390),
]

/// The index in `places` of each place's name.
let placeIndex: [String: Int] = Dictionary(uniqueKeysWithValues: places.enumerated().map { ($0.element.name, $0.offset) })
