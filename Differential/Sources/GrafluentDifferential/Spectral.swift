import GraphProtocols
import Multigraphs
import SpectralGraphTheory

/// SpectralGraphTheory on a case, weights |w|. On the undirected multigraph of the case's edges (a
/// directed case's arcs as edges, loops kept): the k = min(3, n) extreme eigenpairs keyed "L-",
/// "L+", "N-", "A+", "A-", "Q+" (values, then vectors flat); both incidence matrices, unweighted,
/// as dense rows; the modularity matrix for n ≤ 60; hitting times from the first source to the
/// target and back, and the commute time. On a directed case also: the stationary distribution,
/// the oriented incidence matrix and the directed modularity matrix (n ≤ 60).
struct SpectralAnswers: Encodable {
    var eigenvalues: [String: [Double]] = [:]
    var eigenvectors: [String: [Double]] = [:]
    var incidence: [[Double]] = []
    var orientedIncidence: [[Double]] = []
    var modularity: [[Double]]?
    var hitting: Double?
    var hittingBack: Double?
    var commute: Double?
    var stationary: [Double]?
    var stationaryFailed = false
    var directedIncidence: [[Double]]?
    var directedModularity: [[Double]]?
}

private func dense(_ matrix: SparseMatrix) -> [[Double]] {
    (0 ..< matrix.rowCount).map { i in (0 ..< matrix.columnCount).map { matrix[i, $0] } }
}

func spectralAnswers(directed: Bool, n: Int, edges: [[Int]], source: Int, target: Int) -> SpectralAnswers {
    var a = SpectralAnswers()
    let weights = edges.map { Double(abs($0[2])) }
    let graph = Pseudograph(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
    let k = min(3, n)
    do throws(NoConvergence) {
        let pairs: [(String, Eigenpairs<Pseudograph<Int>>)] = [
            ("L-", try graph.laplacianEigenpairs(smallest: k, weight: { weights[$0] })),
            ("L+", try graph.laplacianEigenpairs(largest: k, weight: { weights[$0] })),
            ("N-", try graph.normalizedLaplacianEigenpairs(smallest: k, weight: { weights[$0] })),
            ("A+", try graph.adjacencyEigenpairs(largest: k, weight: { weights[$0] })),
            ("A-", try graph.adjacencyEigenpairs(smallest: k, weight: { weights[$0] })),
            ("Q+", try graph.signlessLaplacianEigenpairs(largest: k, weight: { weights[$0] })),
        ]
        for (key, p) in pairs {
            a.eigenvalues[key] = p.eigenvalues
            a.eigenvectors[key] = (0 ..< p.count).flatMap { p.eigenvector(at: $0) }
        }
    } catch {
        a.eigenvalues["error"] = [Double(error.iterations), error.residual]
    }
    a.incidence = dense(graph.incidenceMatrix())
    a.orientedIncidence = dense(graph.incidenceMatrix(oriented: true))
    if n <= 60 { a.modularity = graph.modularityMatrix(weight: { weights[$0] }) }
    a.hitting = try? graph.hittingTime(from: source, to: target, weight: { weights[$0] })
    a.hittingBack = try? graph.hittingTime(from: target, to: source, weight: { weights[$0] })
    a.commute = try? graph.commuteTime(from: source, to: target, weight: { weights[$0] })
    if directed {
        let digraph = DirectedPseudograph(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        do throws(NoConvergence) {
            a.stationary = try digraph.stationaryDistribution(weight: { weights[$0] }).probabilities
        } catch {
            a.stationaryFailed = true
        }
        a.directedIncidence = dense(digraph.incidenceMatrix(oriented: true))
        if n <= 60 { a.directedModularity = digraph.modularityMatrix(weight: { weights[$0] }) }
    }
    return a
}
