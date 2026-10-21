# EliasFanoGraph test suite

`EliasFanoGraph` is an immutable directed graph on `0..<n` whose rows of successors are Elias–Fano
coded; its edge positions are `CompressedSparseRow`'s. The tests check the coding of a hand-worked
row bit by bit, the degenerate graphs, rows that cross word boundaries, every query against the
compressed sparse row on random graphs dense and sparse, the collections and their slices, equality,
hashing, descriptions and Codable (interchangeable with the compressed sparse row's payload), the
checked spellings and traps, attached maps and the bundle, generations, and algorithms run on the
coded graph. `Performance/` bounds a decoding walk against the compressed sparse row's walk and the
bits an edge takes. The suite uses only the public API, and each test is self-contained.
