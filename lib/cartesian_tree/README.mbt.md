# Cartesian Tree

A Cartesian tree turns an array into a binary tree that satisfies two invariants
simultaneously:

1. **BST / in-order property** -- left-to-right (in-order) traversal reproduces
   the original array exactly.
2. **Min-heap property** -- every node's value is less than or equal to both of
   its children.

These two invariants together uniquely determine the tree shape for any array
with distinct values. The structure is the foundation for O(log n) range minimum
queries (RMQ) via lowest common ancestor (LCA).

## Dual-property visualization

Given the array:

```
index:  0   1   2   3   4
value:  3   2   6   1   9
```

The Cartesian tree looks like this:

```
                  1          <- global minimum, index 3
                 / \
                2   9        <- min of [0..2] and [4..4]
               / \
              3   6          <- leaves
           (i=0) (i=2)
```

Reading this diagram top to bottom shows the heap property: each parent is
smaller than its children. Reading left to right shows the BST property:
in-order traversal gives `3, 2, 6, 1, 9` -- the original array.

The same tree with array indices annotated at each node:

```
                [3]          (index 3, value 1)
                 |
         .-------'-------.
        [1]              [4]
   (idx 1, val 2)   (idx 4, val 9)
        |
   .----'----.
  [0]        [2]
(val 3)    (val 6)
```

## O(n) construction with a monotonic stack

We maintain a stack that always holds the rightmost path of the tree built so
far. Values on the stack are non-decreasing from bottom to top (a min-heap
rightmost spine).

**Algorithm:**

```
stack = []
for i = 0 to n-1:
    last_popped = -1
    while stack not empty AND stack.top().value > arr[i]:
        last_popped = stack.pop()
    if last_popped != -1:
        node[i].left = last_popped      // absorb popped subtree
    if stack not empty:
        stack.top().right = node[i]     // attach to current rightmost path
    stack.push(node[i])
```

**Step-by-step trace for `[3, 2, 6, 1, 9]`:**

```
Step 0  -- insert 3
  stack: [3]
  tree:   3

Step 1  -- insert 2  (pop 3 because 3 > 2; 3 becomes left child of 2)
  pop:  3
  stack: [2]
  tree:   2
         /
        3

Step 2  -- insert 6  (stack top is 2 <= 6, no pop; 6 becomes right child of 2)
  stack: [2, 6]
  tree:   2
         / \
        3   6

Step 3  -- insert 1  (pop 6 because 6 > 1; pop 2 because 2 > 1;
                       last popped (2) becomes left child of 1)
  pop:  6, then 2
  stack: [1]
  tree:     1
           /
          2
         / \
        3   6

Step 4  -- insert 9  (stack top is 1 <= 9, no pop; 9 becomes right child of 1)
  stack: [1, 9]
  tree:     1
           / \
          2   9
         / \
        3   6

Final tree (same as above, root = node with value 1).
```

Each index is pushed exactly once and popped at most once, so total work is
**O(n)**.

**Loop invariant for the stack loop:**

At the start of each iteration, `last_popped` is the index of the most recently
popped node (or -1 if nothing has been popped yet). The stack contains nodes
whose values are all <= `arr[i]`, preserving the min-heap property on the
rightmost path.

## RMQ via LCA

After building the tree, a range minimum query on `[l, r]` reduces to finding
the lowest common ancestor (LCA) of the nodes at positions `l` and `r`:

```
RMQ(l, r) = value at LCA(node[l], node[r])
```

Why this works:

- The heap property guarantees that every node holds the minimum value of its
  entire subtree.
- The in-order property guarantees that the subtree rooted at the LCA of
  `node[l]` and `node[r]` contains exactly the elements at positions `[l, r]`.

Therefore the LCA node holds `min(arr[l..=r])`.

### LCA with binary lifting

Binary lifting preprocesses the tree in O(n log n) time and answers each LCA
query in O(log n):

```
ancestors[0][v] = parent of v
ancestors[k][v] = ancestors[k-1][ ancestors[k-1][v] ]
                = 2^k-th ancestor of v
```

To answer LCA(u, v):
1. Lift the deeper node until both are at the same depth.
2. Lift both simultaneously in decreasing powers of 2 until they would
   diverge; stop just below the LCA.
3. The parent of either node is the LCA.

## Public API

```
@cartesian_tree.range_min(arr, l, r) -> Int64?
```

Returns `Some(min)` for the minimum value in `arr[l..=r]`, or `None` if the
range is invalid.

## Examples

### Example 1: basic RMQ

```mbt check
///|
test "basic rmq" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  inspect(@cartesian_tree.range_min(arr[:], 1, 3), content="Some(1)")
  inspect(@cartesian_tree.range_min(arr[:], 0, 2), content="Some(2)")
}
```

### Example 2: duplicates and tie-breaking

This implementation only pops **strictly larger** values. Equal values keep
their original order, so the leftmost occurrence of a duplicate minimum sits
higher in the tree.

```mbt check
///|
test "duplicates" {
  let arr : Array[Int64] = [5L, 5L, 2L, 5L]
  inspect(@cartesian_tree.range_min(arr[:], 0, 1), content="Some(5)")
  inspect(@cartesian_tree.range_min(arr[:], 0, 2), content="Some(2)")
}
```

### Example 3: ascending and descending arrays

An ascending array produces a right-skewed tree (each new element becomes the
rightmost child); a descending array produces a left-skewed tree.

```mbt check
///|
test "ascending and descending" {
  let asc : Array[Int64] = [1L, 2L, 3L, 4L]
  let desc : Array[Int64] = [4L, 3L, 2L, 1L]
  inspect(@cartesian_tree.range_min(asc[:], 1, 3), content="Some(2)")
  inspect(@cartesian_tree.range_min(desc[:], 1, 3), content="Some(1)")
}
```

### Example 4: invalid ranges

```mbt check
///|
test "invalid range" {
  let arr : Array[Int64] = [3L, 2L, 6L]
  inspect(@cartesian_tree.range_min(arr[:], -1, 1), content="None")
  inspect(@cartesian_tree.range_min(arr[:], 2, 1), content="None")
  inspect(@cartesian_tree.range_min(arr[:], 0, 10), content="None")
}
```

## Applications

| Application | How the Cartesian tree helps |
|---|---|
| Range minimum query | RMQ(l,r) = value at LCA(node[l], node[r]) |
| All nearest smaller values | Left/right parent pointers give nearest smaller |
| Largest rectangle in histogram | Width bounded by nearest smaller bars on each side |
| Treap | BST by key, heap by random priority -- same structure |
| Suffix array construction | DC3 / skew algorithm uses Cartesian trees internally |

## Complexity

| Operation | Time | Space |
|---|---|---|
| Build tree | O(n) | O(n) |
| Binary lifting preprocessing | O(n log n) | O(n log n) |
| RMQ query (binary lifting LCA) | O(log n) | -- |
| RMQ query (Euler tour + sparse table) | O(1) | O(n log n) |

## Practical notes and pitfalls

- **Tie-breaking rule**: when values repeat, define whether left or right
  occurrence wins. This implementation keeps the **leftmost** minimum higher
  by only popping strictly larger values.
- **Inclusive range**: both `l` and `r` are inclusive; `[l, r]` is valid when
  `0 <= l <= r < n`.
- **Tree-only use**: the monotonic-stack build step can be reused standalone
  (without LCA preprocessing) whenever only the parent/child relationships are
  needed.
- **Stack depth**: the recursive `verify_inorder` and `verify_heap` helpers use
  O(n) call-stack space; replace with an iterative traversal for very large
  inputs.

## When to use it

Use a Cartesian tree when you need fast RMQ and want a tree representation that
preserves array order. For offline batch queries the simpler sparse table (also
O(n log n) preprocessing, O(1) query) may be easier to implement; the Cartesian
tree shines when you need the explicit tree structure (e.g. for LCA queries,
treap operations, or nearest-smaller-value problems).
