// DisjointSet against a naive label array (union relabels every member). After each operation
// every query must agree with the model; a copy taken earlier must be unaffected by later finds
// and unions; and the value must equal one rebuilt from the model's partition.

import FuzzSupport
import DisjointSetModule

@main
enum FuzzDisjointSet {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let initial = input.int(in: 0 ... 24)
        var sets = DisjointSet(count: initial)
        var label = Array(0 ..< initial)
        var snapshot: (DisjointSet, [Int])?

        while !input.isEmpty {
            let op = input.int(below: 8)
            let n = label.count
            let a = n == 0 ? 0 : input.int(below: n)
            let b = n == 0 ? 0 : input.int(below: n)
            switch op {
            case 0:
                check(sets.makeSet() == n, "makeSet's element")
                label.append(n)
            case 1, 2, 3:
                guard n > 0 else { break }
                let merged = sets.union(a, b)
                check(merged == (label[a] != label[b]), "union(\(a), \(b)) returned \(merged)")
                let (from, to) = (label[b], label[a])
                for i in label.indices where label[i] == from { label[i] = to }
            case 4:
                guard n > 0 else { break }
                let root = sets.find(a)
                check(root >= 0 && root < n && label[root] == label[a], "find(\(a)) = \(root)")
                check(sets.find(root) == root, "find of a root is itself")
            case 5:
                snapshot = (sets, label)
            case 6:
                sets.reserveCapacity(a * 3)
            default:
                guard n > 0 else { break }
                check(sets.inSameSet(a, b) == (label[a] == label[b]), "inSameSet(\(a), \(b))")
                check(sets.setSize(of: a) == label.filter { $0 == label[a] }.count, "setSize(of: \(a))")
            }

            check(sets.count == label.count, "count")
            check(sets.setCount == Set(label).count, "setCount \(sets.setCount), model \(Set(label).count)")
        }

        // Labels number sets by first element, so they are the model's partition canonicalized.
        var canonical: [Int: Int] = [:]
        let expected = label.map { l in canonical[l] ?? { canonical[l] = canonical.count; return canonical.count - 1 }() }
        check(sets.labels() == expected, "labels \(sets.labels()), model \(expected)")
        check(sets.sets().flatMap { $0 }.sorted() == Array(label.indices), "sets() is a partition")

        var rebuilt = DisjointSet(count: label.count)
        for i in label.indices { rebuilt.union(label[i], i) }
        check(rebuilt == sets && rebuilt.hashValue == sets.hashValue, "equal partitions are equal values")

        if let (copy, saved) = snapshot {
            check(copy.count == saved.count && copy.setCount == Set(saved).count, "the snapshot changed")
            for i in saved.indices { check(copy.inSameSet(i, saved[i]), "the snapshot changed") }
        }
    }
}
