# Challenge: Persistent KD-Tree (2D)

A **KD-tree** is a binary space-partitioning tree for points in k dimensions.
This implementation is **persistent** and supports insertion + membership
queries for 2D points.

This package provides:

- `empty()` to create a tree
- `insert(t, p)` to insert a point (persistent)
- `contains(t, p)` to check membership
- `contains_iter(t, p)` (same behavior, recursive here)
- `from_array(arr)` to build by repeated inserts
- `size(t)` to count points

---

## Split rule (alternating axes)

Every node stores:

- a point `(x, y)`
- an axis: `0` means split by `x`, `1` means split by `y`

At depth 0 we split on x, depth 1 on y, depth 2 on x, etc.

Example:

```
Depth 0 (x):      [x < root.x] | [x >= root.x]
Depth 1 (y):      [y < node.y] | [y >= node.y]
```

---

## Insertion

To insert a point:

- Compare along the node's axis
- Go left if coordinate is smaller, right otherwise
- Create new nodes along the path (persistent)

Duplicate points are ignored.

---

## Persistence (path copying)

Insertion returns a new tree. Only the path to the inserted point is copied;
all other nodes are shared.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert p       B'  C
  / \                      / \
 D   E                    D   E
```

---

## Worked example

Insert points:

```
(2,2), (1,5), (4,1), (3,4)
```

- Root split on x
- Next level split on y
- Next level split on x

Resulting structure depends on insertion order. Membership search follows the
same axis decisions.

---

## Reference implementation

```mbt nocheck
///| pub fn empty() -> Kd

///| pub fn insert(t : Kd, p : Point) -> Kd

///| pub fn contains(t : Kd, p : Point) -> Bool

///| pub fn contains_iter(t : Kd, p : Point) -> Bool

///| pub fn from_array(arr : ArrayView[Point]) -> Kd

///| pub fn size(t : Kd) -> Int
```

---

## Tests and examples

### Basic membership

```mbt check
///|
test "kd tree basic" {
  let t0 = @challenge_persistent_kd_tree.empty()
  let t1 = @challenge_persistent_kd_tree.insert(t0, { x: 2, y: 2 })
  let t2 = @challenge_persistent_kd_tree.insert(t1, { x: 1, y: 5 })
  let t3 = @challenge_persistent_kd_tree.insert(t2, { x: 4, y: 1 })
  inspect(
    @challenge_persistent_kd_tree.contains(t3, { x: 1, y: 5 }),
    content="true",
  )
  inspect(
    @challenge_persistent_kd_tree.contains(t3, { x: 3, y: 3 }),
    content="false",
  )
}
```

### Build from array

```mbt check
///|
test "kd tree from array" {
  let pts : Array[@challenge_persistent_kd_tree.Point] = [
    { x: 2, y: 2 },
    { x: 3, y: 4 },
    { x: 1, y: 5 },
  ]
  let t = @challenge_persistent_kd_tree.from_array(pts[:])
  inspect(
    @challenge_persistent_kd_tree.contains(t, { x: 3, y: 4 }),
    content="true",
  )
  inspect(@challenge_persistent_kd_tree.size(t), content="3")
}
```

### Persistence across versions

```mbt check
///|
test "kd tree persistence" {
  let t0 = @challenge_persistent_kd_tree.empty()
  let t1 = @challenge_persistent_kd_tree.insert(t0, { x: 0, y: 0 })
  let t2 = @challenge_persistent_kd_tree.insert(t1, { x: 5, y: 5 })
  inspect(
    @challenge_persistent_kd_tree.contains(t0, { x: 0, y: 0 }),
    content="false",
  )
  inspect(
    @challenge_persistent_kd_tree.contains(t1, { x: 0, y: 0 }),
    content="true",
  )
  inspect(
    @challenge_persistent_kd_tree.contains(t2, { x: 5, y: 5 }),
    content="true",
  )
}
```

---

## Complexity

Let `h` be the tree height:

- Insert: `O(h)` time, `O(h)` extra memory
- Contains: `O(h)` time

The tree is not rebalanced, so worst-case `h = O(n)`.

---

## Takeaways

- KD-trees split space by alternating axes.
- Persistence keeps all versions available.
- Without balancing, insertion order affects performance.
