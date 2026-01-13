# Challenge: Binary Lifting

Precompute 2^k ancestors to jump up a tree in O(log n) time.

## Core Idea

- Build a **jump table** where `up[k][v]` is the 2^k-th ancestor of `v`.
- Decompose a distance into bits and jump by powers of two.
- Each query climbs in O(log n) using the precomputed table.

## What you learn

- Building the jump table `up[k][v]`
- Using bit decomposition to lift by k steps
- Loop invariants for table construction

## Pseudocode sketch

```mbt nocheck
for k in 1..LOG:
  up[k][v] = up[k-1][ up[k-1][v] ]

lift(v, dist):
  for k in 0..LOG:
    if dist has bit k: v = up[k][v]
```

## Example

```mbt check
///|
test "binary lifting basic" {
  let parent : Array[Int] = [-1, 0, 0, 1, 1, 2]
  let up = @challenge_binary_lifting.build_lift(parent[:])
  inspect(@challenge_binary_lifting.lift(up, 4, 1), content="1")
  inspect(@challenge_binary_lifting.lift(up, 4, 2), content="0")
}
```

## Another Example

```mbt check
///|
test "binary lifting chain" {
  let parent : Array[Int] = [-1, 0, 1, 2]
  let up = @challenge_binary_lifting.build_lift(parent[:])
  inspect(@challenge_binary_lifting.lift(up, 3, 1), content="2")
  inspect(@challenge_binary_lifting.lift(up, 3, 2), content="1")
}
```

## Notes

- Preprocessing: O(n log n)
- Query: O(log n)
