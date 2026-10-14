# Planted bugs for PriorityQueueModule's RadixHeap; run with `just mutate PriorityQueueModule`.
# See scripts/mutate.py.
#
# Known equivalent mutants (they survive by design): none.

TESTS = ["PriorityQueueTests"]

R = "RadixHeap.swift"

MUTANTS = [
    Mutant("rhbucketlast", R, "key ^ lastKey", "key"),
    Mutant("rhbucket", R, "UInt.bitWidth", "(UInt.bitWidth - 1)", nth=2),
    Mutant("rhprecondition", R, "key >= _lastKey", "true"),
    Mutant("rhinsertafter", R, "Self._bucket(of: key, after: _lastKey)", "Self._bucket(of: key, after: 0)"),
    Mutant("rhcount", R, "_count &+= 1", "_count &+= 2", mode="stmt"),
    Mutant("rhpopcount", R, "_count &-= 1", "_count &-= 0", mode="stmt"),
    Mutant("rhempty", R, "guard _count > 0 else { return nil }", "guard _count >= 0 else { return nil }", mode="stmt"),
    Mutant("rhscan", R, "while buckets[i].isEmpty { i &+= 1 }", "i &+= 1; while buckets[i].isEmpty { i &+= 1 }", mode="stmt"),
    Mutant("rhsmallest", R, "pair.key < smallest", "pair.key > smallest"),
    Mutant("rhlastkey", R, "lastKey = smallest", "lastKey = lastKey", mode="stmt"),
    Mutant("rhlastinit", R, "_lastKey = 0", "_lastKey = 1", mode="stmt"),
]
