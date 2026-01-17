# Splay Tree (Self‑Adjusting BST)

This package documents **splay trees**, a self‑adjusting binary search tree.
Every access **splays** the node to the root using rotations.

Key idea: the tree adapts to access patterns — frequently accessed keys stay
near the top.

---

## 1. Why splay trees?

A plain BST can become a chain (O(n) per operation).  
Splay trees fix this **without storing balance info**:

- every search/insert/delete splays to the root,
- amortized **O(log n)** per operation,
- great when access patterns are skewed.

---

## 2. Basic rotation reminder

Right rotation at x:

```
      y                x
     / \              / \
    x   C   --->     A   y
   / \                  / \
  A   B                B   C
```

Left rotation is symmetric.

BST order is preserved.

---

## 3. The three splay cases

### Zig (parent is root)

```
Before:            After:
   p                 x
  / \               / \
 x   C   --->      A   p
/ \                   / \
A  B                 B   C
```

Single rotation.

---

### Zig‑Zig (same direction)

```
Before:                  After:
      g                     x
     / \                   / \
    p   D   --->          A   p
   / \                       / \
  x   C                     B   g
 / \                           / \
A  B                          C   D
```

Rotate **grandparent first**, then parent.

---

### Zig‑Zag (different direction)

```
Before:                  After:
    g                        x
   / \                      / \
  A   p        --->         g   p
     / \                   / \ / \
    x   D                 A  B C  D
   / \
  B   C
```

Rotate x with parent, then with grandparent.

---

## 4. Why zig‑zig is important

Zig‑zig reduces tree depth faster than a single rotation.
That is what gives splay trees their amortized O(log n) guarantee.

---

## 5. Step-by-step example

Tree before splay(30):

```
          50
         /  \
       25    70
      /  \
     10   30
         /  \
        27   40
```

30 is a **right child** of 25, and 25 is a **left child** of 50 -> zig-zag.

After zig‑zag:

```
          50
         /  \
       30    70
      /  \
     25   40
    /  \
   10   27
```

Now 30's parent is root -> zig:

```
        30
       /  \
     25    50
    / \      \
   10 27      70
          /
         40
```

30 is now at the root.

---

## 6. Access on a miss (important detail)

If a key is not found, splay the **last accessed** node on the search path.
This still helps future queries because nearby keys become faster.

Example: search for 26 in the tree above.

- The search ends at node 27 (closest greater key on the path).
- Splay 27 to root.
- The tree becomes better for keys around 26-30.

Think of it as "cache the boundary" even when the target is missing.

---

## 7. Access sequence example (adaptive behavior)

Start with the same tree and access keys: **30, 27, 30, 30**.

```
Access 30 -> 30 becomes root
Access 27 -> 27 becomes root, 30 becomes child
Access 30 -> 30 is near root, fast
Access 30 -> already root, near zero cost
```

Repeated access patterns naturally move hot keys near the top.

---

## 8. Split and join, step by step

Split by key `k`:

1. Find `k` (or the last node on its path).
2. Splay that node to root.
3. Left subtree is `< k`, right subtree is `> k`.

```
Before split:
        (root)
        /    \
     < k     > k

After splay(k):
        k
      /   \
   < k   > k
```

Join two trees A and B where all keys in A are smaller:

1. Splay the maximum node in A to root.
2. Attach B as the right subtree.

```
A max to root:        Join:
     max                max
    /   \              /   \
  ...  (nil)   +      A     B
```

---

## 9. Deletion example (intuitive)

To delete key `x`:

1. Splay `x` to root.
2. Remove the root.
3. Join the left and right subtrees.

If `x` is not present, the last accessed node is splayed instead. That still
improves the tree for nearby keys.

---

## 10. Amortized O(log n) intuition

Splaying may take O(depth) rotations, but it also improves the tree:

```
deep nodes move up
shallow nodes move down
```

Over many operations, total cost averages to O(log n).

---

## 11. Typical operations

1. **Search**: find node, splay it to root.
2. **Insert**: BST insert, then splay new node.
3. **Delete**: splay node, remove root, merge subtrees.
4. **Split/Join**: splay pivot, then split at root.

---

## 12. Example usage (conceptual)

This package is tutorial-only; it does not export a concrete API.

```mbt nocheck
///|
let tree = SplayTree::new()

tree.insert(5)
tree.insert(3)
tree.insert(7)
tree.insert(1)

tree.find(1) // splayed to root

tree.delete(3)

let (left, right) = tree.split(4)
tree = left.join(right)
```

---

## 13. Common applications

1. **Dynamic sequences** (split, join, reverse)
2. **Link‑cut trees** (splay trees inside)
3. **Adaptive caches** (frequent keys stay near root)

---

## 14. Complexity

```
Search / Insert / Delete: O(log n) amortized
Worst-case for one op:    O(n)
Space:                   O(n)
```

---

## 15. Beginner checklist

1. Always splay after access.
2. Zig‑zig: rotate grandparent first.
3. Zig‑zag: rotate node twice.
4. Amortized ≠ worst case; one operation can still be slow.

---

## 16. Summary

Splay trees are simple, adaptive BSTs:

- no balance factors,
- good amortized performance,
- excellent for access‑biased workloads.
