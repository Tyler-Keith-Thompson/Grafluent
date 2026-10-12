/// Counting sort of the indices `0..<labels.count` by label (CLRS 8.2), stable: group `g` is
/// `order[offsets[g] ..< offsets[g + 1]]`, its indices increasing. The partitions, colourings
/// and frontiers that store their members flat, group by group, are built from it. O(n + count).
///
/// - Precondition: every label is in `0..<count`.
@inlinable
package func _countingSort(labels: [Int], count: Int) -> (offsets: [Int], order: [Int]) {
    var offsets = [Int](repeating: 0, count: count + 1)
    let order = offsets.withUnsafeMutableBufferPointer { offsets in
        labels.withUnsafeBufferPointer { labels in
            // Count each group into the slot of the group after it, sum to get each group's
            // start, place the indices advancing the starts to the ends, and shift the ends up a
            // slot.
            for label in labels {
                precondition(UInt(bitPattern: label) < UInt(bitPattern: count), "A label is out of range")
                offsets[label &+ 1] &+= 1
            }
            for g in 0 ..< count { offsets[g + 1] += offsets[g] }
            let order = [Int](unsafeUninitializedCapacity: labels.count) { buffer, initialized in
                for i in 0 ..< labels.count {
                    let label = labels[i]
                    buffer[offsets[label]] = i
                    offsets[label] &+= 1
                }
                initialized = labels.count
            }
            var g = count
            while g > 0 {
                offsets[g] = offsets[g - 1]
                g -= 1
            }
            offsets[0] = 0
            return order
        }
    }
    return (offsets, order)
}
