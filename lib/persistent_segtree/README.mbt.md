# Persistent Segment Tree (Versioned Range Queries)

This package is a **tutorial** package (no exported functions). It explains
how a persistent segment tree keeps **every historical version** after updates
while sharing most of the structure.

If a regular segment tree is a tree of ranges, a **persistent** segment tree is
the same tree, but you keep **all old roots** and only copy the update path.

---

## 1. One picture: what changes on an update

Update index 3 in version 1:

```
Version 1:               Version 2:
    [0..7]                  [0..7]'   <- new root
    /    \                  /    \
 [0..3] [4..7]        [0..3]'  [4..7]  <- right shared
 /   \                 /   \
[0..1][2..3]       [0..1][2..3]' <- left-left shared
      /  \                /  \
    [2]  [3]            [2]  [3]' <- updated leaf
```

Only nodes along the path to the leaf are copied (O(log n) nodes).
Everything else is shared.

---

## 2. Why it works (path copying)

For a balanced segment tree:

- height is O(log n),
- updating a single index touches exactly one node per level,
- so we only create O(log n) new nodes per update.

Old nodes remain intact, so previous versions are still queryable.

---

## 3. A tiny worked example (sum)

Initial array:

```
v0 = [1, 2, 3, 4, 5]
sum(0..4) = 15
```

Update index 2 to 10:

```
v1 = [1, 2, 10, 4, 5]
sum(0..4) = 22
```

Queries on versions:

```
query(v0, 1..3) = 2 + 3 + 4  = 9
query(v1, 1..3) = 2 + 10 + 4 = 16
```

Both versions exist at the same time.

---

## 4. Version tree (branching history)

Every update can branch from any version:

```
v0 --update(2, 10)--> v1 --update(4, 0)--> v2
 |
 +--update(0, 7)--> v3 --update(1, 8)--> v4
```

Each version is an independent root into the same shared node pool.

---

## 5. Beginner-friendly pseudocode (conceptual)

This shows the pattern, not a public API.

```mbt nocheck
///|
struct Node {
  left : Int
  right : Int
  sum : Int
}

// Update one position, return new root

///|
fn update(node : Int, lo : Int, hi : Int, idx : Int, val : Int) -> Int {
  if lo == hi {
    return new_node(left=-1, right=-1, sum=val)
  }
  let mid = (lo + hi) / 2
  let old = nodes[node]
  if idx <= mid {
    let new_left = update(old.left, lo, mid, idx, val)
    let new_sum = nodes[new_left].sum + nodes[old.right].sum
    return new_node(left=new_left, right=old.right, sum=new_sum)
  } else {
    let new_right = update(old.right, mid + 1, hi, idx, val)
    let new_sum = nodes[old.left].sum + nodes[new_right].sum
    return new_node(left=old.left, right=new_right, sum=new_sum)
  }
}
```

Key idea: only the modified path is rebuilt.

---

## 6. Diagram: range query on a version

The query works exactly like a normal segment tree, but you pick which root:

```
query(v2, L, R)
  |
  +-- uses root of version 2
  +-- traverses tree as usual
```

So query is still O(log n).

---

## 7. Application 1: time‑travel range sum

```
You process updates over time:
  v0: initial
  v1: after update #1
  v2: after update #2

Now ask:
  "What was the sum in [l, r] after update #1?"

Answer = query(v1, l, r)
```

---

## 8. Application 2: k‑th smallest in subarray

Classic trick:

1. Coordinate-compress values.
2. Build version i as the frequency tree of prefix [0..i-1].
3. For range [l, r], compare two versions:
   - counts in prefix r+1
   - counts in prefix l
4. Walk down the tree by counts to find the k‑th smallest.

This gives O(log n) per query after O(n log n) preprocessing.

---

## 9. Application 3: 2D offline counting

```
Points (x, y), queries ask:
  "How many points have x in [x1, x2] and y in [y1, y2]?"

Sort points by x.
Build version i with first i points inserted by y.

Answer = query(version x2) - query(version x1 - 1)
```

Persistent segtrees are a standard tool for offline 2D queries.

---

## 10. Complexity summary

```
Build:   O(n)
Update:  O(log n)
Query:   O(log n)
Space:   O(n + updates * log n)
```

---

## 11. Comparison: regular vs persistent

```
Regular segtree:
  - only latest version
  - O(n) space

Persistent segtree:
  - all versions kept
  - O(n + updates * log n) space
```

Use persistent when you need **historical queries** or **branching updates**.

---

## 12. Common pitfalls

1. **Mutating nodes**: If you mutate a shared node, you break persistence.
2. **Too many versions**: Memory grows with each update.
3. **Large value ranges**: For frequency trees, compress values first.

---

## 13. Summary

A persistent segment tree is just a segment tree with **versioned roots**:

- Updates copy only the path to the leaf.
- Queries work the same as usual, just pick a version.
- Perfect for time‑travel and offline range problems.
