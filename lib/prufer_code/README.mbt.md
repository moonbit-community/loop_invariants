# Prufer Code

## Overview

A **Prufer code** is a sequence of length `n - 2` that uniquely represents a
labeled tree with `n` vertices. It provides a bijection between trees and
integer sequences.

- **Encoding**: repeatedly remove the smallest leaf
- **Decoding**: rebuild the tree from degree counts

- **Time**: O(n log n) with a min-heap
- **Space**: O(n)

## Key Facts

1. Each vertex `v` appears exactly `deg[v] - 1` times in the code.
2. Leaves never appear in the remaining suffix of the code.
3. The code is unique for each labeled tree.

## Encoding Algorithm

```
Repeat n-2 times:
  1. Pick the smallest leaf.
  2. Append its neighbor to the code.
  3. Remove the leaf.
```

## Decoding Algorithm

```
Initialize degree[v] = 1 + count(v in code).
Repeat over code:
  1. Pick the smallest vertex with degree 1 (leaf).
  2. Connect it to the current code value.
  3. Decrease degrees and update the leaf set.
Finally connect the last two leaves.
```

## Example

Tree: 0-1-2-3

```
Leaves: 0, 3
Remove 0 -> append 1
Leaves: 1, 3
Remove 1 -> append 2
Code = [1, 2]
```

## Example Usage

```mbt check
///|
test "prufer example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let code = @prufer_code.prufer_encode(4, edges[:]).unwrap()
  inspect(code, content="[1, 2]")
  let edges2 = @prufer_code.prufer_decode(code[:]).unwrap()
  inspect(edges2.length(), content="3")
}
```

## Applications

- Counting labeled trees (Cayley’s formula)
- Random tree generation
- Tree compression and serialization
- Combinatorics and graph theory exercises
