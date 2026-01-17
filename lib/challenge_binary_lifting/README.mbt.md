# Challenge: Binary Lifting

Binary lifting lets you jump upward in a tree by powers of two. After a
preprocessing step, any "k-th ancestor" query can be answered in O(log n)
by decomposing k into bits.

This package provides:

- `build_lift(parent)` -> jump table `up[k][v]`
- `lift(up, v, dist)` -> the `dist`-th ancestor of `v`

## Problem statement

You are given a rooted tree described by a parent array:

```
parent[v] = immediate parent of v, or -1 for the root
```

You need to answer queries:

```
What is the ancestor of node v after dist steps upward?
```

## Key idea: powers of two

Instead of jumping one step at a time, we precompute:

- `up[0][v]` = 1-step ancestor (the parent)
- `up[1][v]` = 2-step ancestor
- `up[2][v]` = 4-step ancestor
- ...

Then any distance can be written as a sum of powers of two. For example:

```
13 = 8 + 4 + 1
```

So to jump 13 steps, we jump 8, then 4, then 1.

## Diagram example

Consider this tree (parent array is shown below):

```
    0
   / \
  1   2
 / \   \
3   4   5
```

```
parent = [-1, 0, 0, 1, 1, 2]
```

The table begins like this:

```
up[0] (1 step): [-1, 0, 0, 1, 1, 2]
up[1] (2 steps): [-1, -1, -1, 0, 0, 0]
up[2] (4 steps): [-1, -1, -1, -1, -1, -1]
```

Now a query like "lift node 4 by 2 steps" is just `up[1][4] = 0`.

## Building the table

We compute `up[k][v]` from `up[k-1]`:

```
up[k][v] = up[k-1][ up[k-1][v] ]
```

This is dynamic programming: the 2^k ancestor is the 2^(k-1) ancestor of the
2^(k-1) ancestor.

## Lifting by distance

To lift by `dist`:

1. Look at the binary representation of `dist`.
2. For each bit that is 1, jump by that power of two.

Example: `dist = 6 = 4 + 2`

```
jump 4 (bit 2), then jump 2 (bit 1)
```

## Examples

### Example 1: basic tree

```mbt check
///|
test "binary lifting basic" {
  let parent : Array[Int] = [-1, 0, 0, 1, 1, 2]
  let up = @challenge_binary_lifting.build_lift(parent[:])
  inspect(@challenge_binary_lifting.lift(up, 4, 0), content="4")
  inspect(@challenge_binary_lifting.lift(up, 4, 1), content="1")
  inspect(@challenge_binary_lifting.lift(up, 4, 2), content="0")
  inspect(@challenge_binary_lifting.lift(up, 4, 3), content="-1")
}
```

### Example 2: a chain

```
0 - 1 - 2 - 3
```

```mbt check
///|
test "binary lifting chain" {
  let parent : Array[Int] = [-1, 0, 1, 2]
  let up = @challenge_binary_lifting.build_lift(parent[:])
  inspect(@challenge_binary_lifting.lift(up, 3, 1), content="2")
  inspect(@challenge_binary_lifting.lift(up, 3, 2), content="1")
  inspect(@challenge_binary_lifting.lift(up, 3, 3), content="0")
  inspect(@challenge_binary_lifting.lift(up, 3, 4), content="-1")
}
```

### Example 3: root behavior

```mbt check
///|
test "root stays -1" {
  let parent : Array[Int] = [-1, 0, 0]
  let up = @challenge_binary_lifting.build_lift(parent[:])
  inspect(@challenge_binary_lifting.lift(up, 0, 1), content="-1")
  inspect(@challenge_binary_lifting.lift(up, 0, 2), content="-1")
}
```

## Complexity

- Preprocessing: O(n log n)
- Query: O(log n)
- Memory: O(n log n)

## Practical notes and pitfalls

- If `dist` is larger than the height of the node, the result is `-1`.
- The parent array must form a tree (one root with parent -1).
- The jump table can also be reused for LCA if you also store node depths.
