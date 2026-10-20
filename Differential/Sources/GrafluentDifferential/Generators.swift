import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import NamedGraphs
import RandomGraphs

/// The generator inputs scripts/differential_generators.py derives from a case: degree sequences
/// to test and realize, parameters for the random families (drawn from `seed`), and parameters for
/// the named families.
struct GeneratorCase: Decodable {
    let degrees: [Int]
    let inDegrees: [Int]
    let outDegrees: [Int]
    let seed: UInt64
    let stubDegrees: [Int]
    let stubIn: [Int]
    let stubOut: [Int]
    let weights: [Double]
    let holmeKim: [Double]          // n, m, p
    let smallWorld: [Double]        // n, k, p, tries
    let kOut: [Int]                 // n, k
    let scaleFree: [Double]         // n, alpha, beta, gamma, deltaIn, deltaOut
    let bipartite: [Int]            // a, b, m
    let circulant: [Int]            // n, offsets…
    let petersen: [Int]             // n, k
    let kneser: [Int]               // n, k
    let windmill: [Int]             // cliques, clique size
    let trees: [Int]                // binomial order, r, n
    let words: [Int]                // de Bruijn m, L; Kautz s, L
    let lattice: [Int]              // rows, columns
    let lcf: [Int]                  // n, repeats, shifts…
    let expanders: [Int]            // Margulis–Gabber–Galil side, chordal cycle prime, Paley prime ≡ 1 (mod 4), Paley prime ≡ 3 (mod 4)
    let named: Bool
}

/// The answers, every graph as its edges in order ([u, v] pairs, smaller end first for the
/// undirected ones).
struct GeneratorAnswers: Encodable {
    var isGraphical = false
    var isDigraphical = false
    var havelHakimi: [[Int]]?
    var kleitmanWang: [[Int]]?
    var configurationModel: [[Int]] = []
    var directedConfigurationModel: [[Int]] = []
    var chungLu: [[Int]] = []
    var chungLuDirected: [[Int]] = []
    var holmeKim: [[Int]] = []
    var holmeKimDirected: [[Int]] = []
    var newmanWattsStrogatz: [[Int]] = []
    var connectedWattsStrogatz: [[Int]]?
    var kOut: [[Int]] = []
    var kOutUndirected: [[Int]] = []
    var scaleFree: [[Int]] = []
    var bipartite: [[Int]] = []
    var bipartiteDirected: [[Int]] = []
    var conformersAgree = true
    var named: [String: [[Int]]] = [:]
    var namedCounts: [String: [Int]] = [:]
    var paleyTournament: [[Int]] = []
}

func undirectedPairs(_ graph: some Graph<Int>) -> [[Int]] { graph.edges.map { [min($0.u, $0.v), max($0.u, $0.v)] } }
func directedPairs(_ graph: some DirectedGraph<Int>) -> [[Int]] { graph.edges.map { [$0.source, $0.target] } }

func generatorAnswers(_ g: GeneratorCase) -> GeneratorAnswers {
    var a = GeneratorAnswers()
    a.isGraphical = isGraphical(g.degrees)
    if a.isGraphical {
        let graph = UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: g.degrees)
        a.havelHakimi = undirectedPairs(graph)
        a.conformersAgree = undirectedPairs(Pseudograph<Int>.havelHakimi(degreeSequence: g.degrees)) == a.havelHakimi
    }
    a.isDigraphical = isDigraphical(inDegrees: g.inDegrees, outDegrees: g.outDegrees)
    if a.isDigraphical {
        a.kleitmanWang = directedPairs(CompressedSparseRow.havelHakimi(inDegrees: g.inDegrees, outDegrees: g.outDegrees))
        a.conformersAgree = a.conformersAgree
            && directedPairs(AdjacencyList<Int>.havelHakimi(inDegrees: g.inDegrees, outDegrees: g.outDegrees)) == a.kleitmanWang
    }
    var r = Xoshiro256StarStar(seed: g.seed)
    a.configurationModel = Pseudograph<Int>.configurationModel(degreeSequence: g.stubDegrees, using: &r).edges.map { [$0.u, $0.v] }
    r = Xoshiro256StarStar(seed: g.seed)
    a.directedConfigurationModel = directedPairs(DirectedPseudograph<Int>.configurationModel(inDegrees: g.stubIn, outDegrees: g.stubOut, using: &r))
    r = Xoshiro256StarStar(seed: g.seed)
    a.chungLu = undirectedPairs(UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: g.weights, using: &r))
    r = Xoshiro256StarStar(seed: g.seed)
    a.chungLuDirected = directedPairs(CompressedSparseRow.chungLu(expectedDegrees: g.weights, using: &r))
    let (hn, hm, hp) = (Int(g.holmeKim[0]), Int(g.holmeKim[1]), g.holmeKim[2])
    r = Xoshiro256StarStar(seed: g.seed)
    a.holmeKim = undirectedPairs(UndirectedAdjacencyList<Int>.holmeKim(vertexCount: hn, edgesPerVertex: hm, triangleProbability: hp, using: &r))
    r = Xoshiro256StarStar(seed: g.seed)
    a.holmeKimDirected = directedPairs(CompressedSparseRow.holmeKim(vertexCount: hn, edgesPerVertex: hm, triangleProbability: hp, using: &r))
    let (wn, wk, wp, wt) = (Int(g.smallWorld[0]), Int(g.smallWorld[1]), g.smallWorld[2], Int(g.smallWorld[3]))
    r = Xoshiro256StarStar(seed: g.seed)
    a.newmanWattsStrogatz = undirectedPairs(UndirectedAdjacencyList<Int>.newmanWattsStrogatz(
        vertexCount: wn, nearestNeighborCount: wk, shortcutProbability: wp, using: &r))
    r = Xoshiro256StarStar(seed: g.seed)
    a.connectedWattsStrogatz = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(
        vertexCount: wn, nearestNeighborCount: wk, rewiringProbability: wp, tries: wt, using: &r).map { undirectedPairs($0) }
    r = Xoshiro256StarStar(seed: g.seed)
    a.kOut = directedPairs(CompressedSparseRow.randomKOut(vertexCount: g.kOut[0], outDegree: g.kOut[1], using: &r))
    r = Xoshiro256StarStar(seed: g.seed)
    a.kOutUndirected = undirectedPairs(UndirectedAdjacencyList<Int>.randomKOut(vertexCount: g.kOut[0], outDegree: g.kOut[1], using: &r))
    let s = g.scaleFree
    r = Xoshiro256StarStar(seed: g.seed)
    a.scaleFree = directedPairs(DirectedPseudograph<Int>.scaleFree(
        vertexCount: Int(s[0]), alpha: s[1], beta: s[2], gamma: s[3], deltaIn: s[4], deltaOut: s[5], using: &r))
    r = Xoshiro256StarStar(seed: g.seed)
    a.bipartite = undirectedPairs(UndirectedAdjacencyList<Int>.randomBipartite(
        leftCount: g.bipartite[0], rightCount: g.bipartite[1], edgeCount: g.bipartite[2], using: &r))
    r = Xoshiro256StarStar(seed: g.seed)
    a.bipartiteDirected = directedPairs(CompressedSparseRow.randomBipartite(
        leftCount: g.bipartite[0], rightCount: g.bipartite[1], edgeCount: g.bipartite[2], using: &r))

    // The named families on the case's parameters, as undirected edge lists, and their directed
    // forms' arc counts.
    typealias U = UndirectedAdjacencyList<Int>
    typealias D = CompressedSparseRow
    func both(_ name: String, _ u: U, _ d: D) {
        a.named[name] = undirectedPairs(u)
        a.namedCounts[name] = [u.vertexCount, u.edgeCount, d.edgeCount]
    }
    both("circulant", .circulant(vertexCount: g.circulant[0], offsets: Array(g.circulant.dropFirst())),
         .circulant(vertexCount: g.circulant[0], offsets: Array(g.circulant.dropFirst())))
    both("generalizedPetersen", .generalizedPetersen(outerCycleLength: g.petersen[0], step: g.petersen[1]),
         .generalizedPetersen(outerCycleLength: g.petersen[0], step: g.petersen[1]))
    both("kneser", .kneser(setSize: g.kneser[0], subsetSize: g.kneser[1]), .kneser(setSize: g.kneser[0], subsetSize: g.kneser[1]))
    both("windmill", .windmill(cliqueCount: g.windmill[0], cliqueVertexCount: g.windmill[1]),
         .windmill(cliqueCount: g.windmill[0], cliqueVertexCount: g.windmill[1]))
    both("binomialTree", .binomialTree(order: g.trees[0]), .binomialTree(order: g.trees[0]))
    both("fullRaryTree", .fullRaryTree(branchingFactor: g.trees[1], vertexCount: g.trees[2]),
         .fullRaryTree(branchingFactor: g.trees[1], vertexCount: g.trees[2]))
    both("triangularLattice", .triangularLattice(rowCount: g.lattice[0], columnCount: g.lattice[1]),
         .triangularLattice(rowCount: g.lattice[0], columnCount: g.lattice[1]))
    both("hexagonalLattice", .hexagonalLattice(rowCount: g.lattice[0], columnCount: g.lattice[1]),
         .hexagonalLattice(rowCount: g.lattice[0], columnCount: g.lattice[1]))
    both("lcf", .lcf(vertexCount: g.lcf[0], shifts: Array(g.lcf.dropFirst(2)), repeatCount: g.lcf[1]),
         .lcf(vertexCount: g.lcf[0], shifts: Array(g.lcf.dropFirst(2)), repeatCount: g.lcf[1]))
    both("margulisGabberGalil", .margulisGabberGalil(side: g.expanders[0]), .margulisGabberGalil(side: g.expanders[0]))
    both("chordalCycle", .chordalCycle(prime: g.expanders[1]), .chordalCycle(prime: g.expanders[1]))
    both("paley", .paley(prime: g.expanders[2]), .paley(prime: g.expanders[2]))
    a.paleyTournament = directedPairs(CompressedSparseRow.paley(prime: g.expanders[3]))
    a.named["deBruijn"] = directedPairs(AdjacencyList<Int>.deBruijn(alphabetSize: g.words[0], wordLength: g.words[1]))
    a.named["kautz"] = directedPairs(CompressedSparseRow.kautz(alphabetSize: g.words[2], wordLength: g.words[3]))
    if g.named {
        both("petersen", .petersen(), .petersen())
        both("heawood", .heawood(), .heawood())
        both("moebiusKantor", .moebiusKantor(), .moebiusKantor())
        both("pappus", .pappus(), .pappus())
        both("desargues", .desargues(), .desargues())
        both("dodecahedral", .dodecahedral(), .dodecahedral())
        both("icosahedral", .icosahedral(), .icosahedral())
        both("frucht", .frucht(), .frucht())
        both("tutte", .tutte(), .tutte())
        both("chvatal", .chvatal(), .chvatal())
        both("hoffmanSingleton", .hoffmanSingleton(), .hoffmanSingleton())
    }
    return a
}
