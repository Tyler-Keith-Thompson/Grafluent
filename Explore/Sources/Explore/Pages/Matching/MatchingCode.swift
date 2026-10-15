// snippet: matching-imports
import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import MatchingModule
// snippet end

/// The hires the matching page shows: each as an applicant and a job.
func hire(applicants: [String], jobs: [String], canDo: [(String, String)]) -> [(applicant: String, job: String)] {
    // snippet: matching-hire
    let skills = UndirectedAdjacencyList<String> {
        for name in applicants + jobs { name }
        for (applicant, job) in canDo { UndirectedEdge(applicant, job) }
    }
    let sides = skills.bipartition(left: applicants)!
    let hires = skills.maximumBipartiteMatching(bipartition: sides)
    let pairs = hires.edges.map { skills.edges[$0] }  // →
    // snippet end
    return pairs.map { edge in applicants.contains(edge.u) ? (edge.u, edge.v) : (edge.v, edge.u) }
}

/// The hires with only the first 1, 2, … applicants: each newcomer is placed directly, placed
/// after a chain of swaps, or left out.
func arrivals(applicants: [String], jobs: [String], canDo: [(String, String)]) -> [[(applicant: String, job: String)]] {
    // snippet: matching-arrivals
    // `hire` is the code above; run it as the applicants arrive one at a time.
    let rounds = (1 ... applicants.count).map { arrived in
        let present = Array(applicants.prefix(arrived))
        return hire(applicants: present, jobs: jobs, canDo: canDo.filter { present.contains($0.0) })
    }
    // snippet end
    return rounds
}
