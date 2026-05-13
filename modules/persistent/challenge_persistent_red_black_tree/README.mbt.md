# Challenge: Persistent Red-Black Tree

A **red-black tree** is a binary search tree where every node carries a
single `Red` / `Black` bit. The bit is enough to bound the tree height by
`2 * log2(n + 1)`, so search and insert run in `O(log n)`. This
implementation is **persistent**: every `insert` returns a fresh tree and
every previous version remains valid and reusable.

This package provides:

- `empty()` to create a tree
- `insert(tree, key)` to insert (persistent, ignores duplicates)
- `contains(tree, key)` to test membership
- `inorder(tree)` to list keys in sorted order
- `size(tree)` to count keys
- `from_array(arr)` to build by repeated insertion

---

## The four red-black invariants

| Invariant | Statement                                                    |
|-----------|--------------------------------------------------------------|
| RB1       | Every node is red or black.                                  |
| RB2       | The root is black.                                           |
| RB3       | No red node has a red child (no two reds in a row).          |
| RB4       | Every root-to-leaf path has the same number of black nodes.  |

RB3 and RB4 together force the tree height to be bounded by twice the
black-height, which is itself bounded by `log2(n + 1)`. So the tree is
always close to balanced even though only one bit of balance information
lives on each node.

---

## Okasaki's `balance` step

When `insert` recurses down the tree it places the new key as a *red* leaf,
which preserves RB4 (black heights are unchanged) but may violate RB3 if
the parent is also red. Exactly four shapes can produce a red-red pair
when looking at a black grandparent:

```
        Z              Z              X              X
       / \            / \            / \            / \
      Y   d          X   d          a   Z          a   Y
     / \            / \                / \            / \
    X   c          a   Y              Y   d          b   Z
   / \                / \            / \                / \
  a   b              b   c          b   c              c   d
  (LL)               (LR)           (RL)               (RR)
```

In every case, the four subtrees `a, b, c, d` are black (their roots) and
appear in the same left-to-right order. `balance` rewrites all four shapes
into the same canonical balanced form:

```
            Y                   (Y becomes the new local root, painted red)
           / \
          X   Z                 (the two former endpoints become its black
         / \ / \                 children)
        a  b c  d
```

The recursion now returns this red `Y` to its grandparent. If that
grandparent is also red, the same red-red violation arises one level
higher and is fixed by another `balance` on the way up. The root-painting
step at the top of `insert` then enforces RB2.

This is **the entire balancing logic**: no rotations, no auxiliary fields
beyond the color bit. The price is repainting the four cases on every
step; the gain is a structure that is trivial to verify and easy to make
persistent.

---

## Persistence (path copying)

Persistent data structures do not mutate old versions. Insertion creates a
new path from the root to the updated leaf and reuses everything else.

```
Old version v0:             New version v1 after insert(v0, 7):

       (10,B)                          (10,B)'                |
       /    \                          /    \                 |
   (5,R)   (15,R)                  (5,R)'  (15,R)             | shared
   /  \    /   \                   /  \    /   \              | with v0
 (3,B)(8,B)(12,B)(20,B)         (3,B)(8,B)'(12,B)(20,B)       |
                                         \
                                        (7,R)' new
```

Nodes marked `'` are freshly allocated; everything else is shared with
`v0`. The new path costs `O(log n)` extra memory per insert.

---

## Worked insertion example

Insert `4, 1, 7, 3` into an empty tree.

1. Insert 4 — new red leaf, repainted black at root:
   ```
   (4,B)
   ```
2. Insert 1 — descends left, lands as red leaf, RB3 holds:
   ```
       (4,B)
       /
   (1,R)
   ```
3. Insert 7 — descends right, lands as red leaf:
   ```
       (4,B)
       /   \
   (1,R)  (7,R)
   ```
4. Insert 3 — descends left, then right. Lands as red leaf, but its
   parent `(1,R)` is also red. That triggers the **LR** case at
   grandparent `(4,B)`: the local subtree
   `Black(4, Red(1, _, Red(3, _, _)), 7)` is rewritten into
   `Red(3, Black(1, _, _), Black(4, _, 7))`. The root is then repainted
   black:
   ```
        (3,B)
        /   \
    (1,B)  (4,B)
              \
             (7,R)
   ```

Both RB3 (no red-red) and RB4 (black-heights match: 2 on every path) are
preserved.

---

## Search

`contains` is plain BST search and ignores colors entirely. Its loop
invariant is the standard BST bracket: a `(lo, hi)` open interval that
contains the target key, with both bounds tightening on every step:

```
  (lo, hi) shrinks toward the leaf as we descend
```

The colors are irrelevant for correctness here — they only bound the
number of iterations to `O(log n)` via the height bound from RB3 and RB4.

---

## Reference operations

```
pub fn[T] empty() -> RB[T]
pub fn[T : Compare] insert(t : RB[T], key : T) -> RB[T]
pub fn[T : Compare] contains(t : RB[T], key : T) -> Bool
pub fn[T] inorder(t : RB[T]) -> Array[T]
pub fn[T] size(t : RB[T]) -> Int
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> RB[T]
```

---

## Tests and examples

### Inserts keep the tree balanced and ordered

```mbt check
///|
test "rb basic" {
  let s = @challenge_persistent_red_black_tree.from_array([
    3, 1, 4, 1, 5, 9, 2, 6,
  ])
  debug_inspect(@challenge_persistent_red_black_tree.size(s), content="7")
  debug_inspect(
    @challenge_persistent_red_black_tree.contains(s, 4),
    content="true",
  )
  debug_inspect(
    @challenge_persistent_red_black_tree.contains(s, 7),
    content="false",
  )
  debug_inspect(
    @challenge_persistent_red_black_tree.inorder(s),
    content="[1, 2, 3, 4, 5, 6, 9]",
  )
}
```

### Old versions are independent of new ones

```mbt check
///|
test "rb persistent versions" {
  let t0 = @challenge_persistent_red_black_tree.empty()
  let t1 = @challenge_persistent_red_black_tree.insert(t0, 10)
  let t2 = @challenge_persistent_red_black_tree.insert(t1, 5)
  let t3 = @challenge_persistent_red_black_tree.insert(t2, 20)
  // t0 never saw 10
  debug_inspect(
    @challenge_persistent_red_black_tree.contains(t0, 10),
    content="false",
  )
  // t1 only knows 10
  debug_inspect(
    @challenge_persistent_red_black_tree.contains(t1, 10),
    content="true",
  )
  debug_inspect(
    @challenge_persistent_red_black_tree.contains(t1, 5),
    content="false",
  )
  // t3 knows everything
  debug_inspect(@challenge_persistent_red_black_tree.size(t3), content="3")
}
```

### Duplicates are ignored (set semantics)

```mbt check
///|
test "rb duplicates" {
  let t0 = @challenge_persistent_red_black_tree.empty()
  let t1 = @challenge_persistent_red_black_tree.insert(t0, 42)
  let t2 = @challenge_persistent_red_black_tree.insert(t1, 42)
  debug_inspect(@challenge_persistent_red_black_tree.size(t1), content="1")
  debug_inspect(@challenge_persistent_red_black_tree.size(t2), content="1")
}
```

### Sequential inserts of `0..20` produce a balanced tree

```mbt check
///|
test "rb sequential ascending" {
  let arr : ReadOnlyArray[Int] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  ]
  let t = @challenge_persistent_red_black_tree.from_array(arr)
  debug_inspect(@challenge_persistent_red_black_tree.size(t), content="20")
}
```

---

## Complexity

For `n` keys in the tree:

| Operation | Time         | Extra memory   |
|-----------|--------------|----------------|
| `empty`   | `O(1)`       | `O(1)`         |
| `insert`  | `O(log n)`   | `O(log n)`     |
| `contains`| `O(log n)`   | `O(1)`         |
| `size`    | `O(n)`       | `O(log n)` stk |
| `inorder` | `O(n)`       | `O(n)`         |

Compared to AVL, red-black trees rebalance using a simpler pattern match
(no explicit rotations) and need only one color bit per node instead of an
`Int` height. They are slightly less strictly balanced (worst-case height
`2 log n` vs AVL's `~1.44 log n`), which is rarely measurable in practice.

---

## Takeaways

- Red-black trees encode balance in a single color bit per node.
- Okasaki's pattern-matching `balance` covers all four red-red shapes
  with one rewrite rule, making the implementation tiny and easy to
  inspect.
- Path-copying makes the structure fully persistent for free: a chain of
  `insert` calls produces a chain of versions that all coexist and share
  the bulk of their nodes.
