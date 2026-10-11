/// Runs `body` over `input` as one contiguous buffer, after a leading byte-order mark if there is
/// one, once the whole buffer has been checked to be UTF-8. An error thrown by `body` (or by the
/// check) gets its line and column here, from its byte offset.
///
/// The buffer is the sequence's own storage when it has one (`String.UTF8View`, `Array`,
/// `UnsafeBufferPointer`); otherwise the sequence is copied into an array once.
@inlinable func _readInput<Result>(
    _ input: some Sequence<UInt8>,
    xmlCharacters: Bool = false,
    _ body: (UnsafeBufferPointer<UInt8>) throws(ParseError) -> Result
) throws(ParseError) -> Result {
    func run(_ whole: UnsafeBufferPointer<UInt8>) -> Swift.Result<Result, ParseError> {
        var text = whole
        if whole.count >= 3, whole[0] == 0xEF, whole[1] == 0xBB, whole[2] == 0xBF {
            text = UnsafeBufferPointer(rebasing: whole[3...])
        }
        do throws(ParseError) {
            try _validateUTF8(text, xmlCharacters: xmlCharacters)
            return .success(try body(text))
        } catch {
            return .failure(error._located(in: text))
        }
    }
    if let result = input.withContiguousStorageIfAvailable({ run($0) }) {
        return try result.get()
    }
    let copy = Array(input)
    return try copy.withUnsafeBufferPointer { run($0) }.get()
}
