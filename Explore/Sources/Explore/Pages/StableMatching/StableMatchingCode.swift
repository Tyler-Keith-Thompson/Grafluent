// snippet: stablematching-imports
import MatchingModule
// snippet end

// The students and tutors of the stable matching page and the matchings it asks for. The marked
// regions are its code panel.

// snippet: stablematching-preferences
let students = ["Ada", "Ben", "Cleo", "Dev"]
let tutors = ["Iris", "Jon", "Kim", "Lou"]
let studentLikes = [["Kim", "Jon", "Lou", "Iris"], ["Iris", "Jon", "Kim", "Lou"], ["Iris", "Jon", "Lou", "Kim"], ["Kim", "Iris", "Jon", "Lou"]]
let tutorLikes = [["Ada", "Dev", "Ben", "Cleo"], ["Ben", "Cleo", "Dev", "Ada"], ["Dev", "Ada", "Cleo", "Ben"], ["Ben", "Dev", "Cleo", "Ada"]]
let studentPreferences = studentLikes.map { $0.map { tutors.firstIndex(of: $0)! } }
let tutorPreferences = tutorLikes.map { $0.map { students.firstIndex(of: $0)! } }
// snippet end

/// Every event of deferred acceptance with students or tutors proposing, and each proposer's
/// mate at the end.
func matchingRun(studentsPropose: Bool) -> (events: [GaleShapleyEvent], mates: [Int?]) {
    // snippet: stablematching-run
    let (proposers, reviewers) = studentsPropose ? (studentPreferences, tutorPreferences) : (tutorPreferences, studentPreferences)
    let events = Array(galeShapley(proposerPreferences: proposers, reviewerPreferences: reviewers))  // →
    let matching = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
    let mates = proposers.indices.map { matching.mate(ofProposer: $0) }                              // →
    // snippet end
    return (events, mates)
}
