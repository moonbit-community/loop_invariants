# Splay Tree (Self‑Adjusting BST)

This package documents **splay trees**, a self‑adjusting binary search tree.
Whenever a node is accessed, it is rotated to the root (splayed), giving
**amortized O(log n)** time without storing balance info.

---

## 1. Big idea (beginner friendly)

If you access the same keys often, you want them near the root.

Splaying achieves that:

```
access x -> rotate x to root
recent keys become fast
```

No explicit balancing is needed.

---

## 2. Rotation reminder

Right rotation:

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

Rotate x twice: first with parent, then with grandparent.

---

## 4. Step‑by‑step example

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

30 is right child of 25, and 25 is left child of 50 → zig‑zag.

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

Now 30’s parent is root → zig:

```
        30
       /  \
     25    50
    / \      \
   10 27      70
          /
         40
```

30 becomes the root.

---

## 5. Why it’s fast (amortized)

Splaying a deep node costs more now, but it makes the tree better for the
future. Over many operations, this averages to O(log n).

---

## 6. Typical operations

1. **Search**: find node, then splay it.
2. **Insert**: insert as BST, then splay.
3. **Delete**: splay node, delete root, join subtrees.
4. **Split/Join**: splay pivot, cut, or attach subtrees.

---

## 7. Example usage (conceptual)

This package is tutorial‑only; it does not export a concrete API.

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

## 8. Common applications

1. **Dynamic sequences** (split/join)
2. **Link‑cut trees** (splay trees inside)
3. **Adaptive caches** (recent items stay near root)

---

## 9. Complexity

```
Search / Insert / Delete: O(log n) amortized
Worst case for one op:    O(n)
Space:                   O(n)
```

---

## 10. Beginner checklist

1. Always splay after access.
2. Zig‑zig rotates grandparent first.
3. Zig‑zag rotates node twice.
4. One operation can be slow, but average is fast.

---

## 11. Summary

Splay trees are self‑adjusting BSTs:

- simple rotations,
- no balance metadata,
- adaptive performance with amortized log time.
