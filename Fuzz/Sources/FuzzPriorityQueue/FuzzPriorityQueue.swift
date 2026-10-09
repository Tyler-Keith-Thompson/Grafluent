// IndexedPriorityQueue against a dictionary from index to priority. Each input is a sequence of
// operations on indices 0..<16 with priorities 0..<8, so ties are common; after each one the
// queue's observable state must match the model, and a copy taken earlier must still match the
// model as it was.

import FuzzSupport
import PriorityQueueModule

@main
enum FuzzPriorityQueue {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let bound = 16
        var queue = IndexedPriorityQueue<Int>(indexBound: bound)
        var model: [Int: Int] = [:]
        var snapshot: (queue: IndexedPriorityQueue<Int>, model: [Int: Int])?

        while !input.isEmpty {
            let index = input.int(below: bound)
            let priority = input.int(below: 8)
            switch input.int(below: 9) {
            case 0, 1:
                if model[index] == nil {
                    queue.insert(index, priority: priority)
                    model[index] = priority
                }
            case 2:
                let popped = queue.popMin()
                check(popped?.priority == model.values.min(), "popMin gave \(String(describing: popped)), model \(model)")
                if let popped {
                    check(model[popped.index] == popped.priority, "popMin gave \(popped), model \(model)")
                    model[popped.index] = nil
                }
            case 3:
                if let old = model[index], priority <= old {
                    queue.decreasePriority(of: index, to: priority)
                    model[index] = priority
                }
            case 4:
                let changed = queue.insertOrDecreasePriority(of: index, to: priority)
                let expected = model[index].map { priority < $0 } ?? true
                check(changed == expected, "insertOrDecrease(\(index), \(priority)) returned \(changed), model \(model)")
                if expected { model[index] = priority }
            case 5:
                if let old = model[index] {
                    check(queue.updatePriority(of: index, to: priority) == old, "updatePriority's old value")
                    model[index] = priority
                }
            case 6:
                check(queue.remove(index) == model[index], "remove(\(index)), model \(model)")
                model[index] = nil
            case 7:
                snapshot = (queue, model)
            default:
                queue.removeAll(keepingCapacity: index % 2 == 0)
                model = [:]
            }

            check(queue.count == model.count, "count \(queue.count), model \(model)")
            check(queue.isEmpty == model.isEmpty, "isEmpty")
            check(queue.min?.priority == model.values.min(), "min \(String(describing: queue.min)), model \(model)")
            for i in 0 ..< bound {
                check(queue.contains(i) == (model[i] != nil), "contains(\(i))")
                check(queue.priority(of: i) == model[i], "priority(of: \(i))")
            }
            let unordered = Dictionary(uniqueKeysWithValues: queue.unordered.map { ($0.index, $0.priority) })
            check(unordered == model, "unordered \(unordered), model \(model)")
        }

        // Value semantics: the copy saw none of the later operations, and drains in order.
        if var (copy, expected) = snapshot {
            var last = Int.min
            while let (index, priority) = copy.popMin() {
                check(expected.removeValue(forKey: index) == priority && priority >= last, "the snapshot drained out of order")
                last = priority
            }
            check(expected.isEmpty, "the snapshot lost \(expected)")
        }
    }
}
