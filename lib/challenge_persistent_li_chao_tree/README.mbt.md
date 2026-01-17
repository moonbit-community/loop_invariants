# Challenge: Persistent Li Chao Tree

A **Li Chao tree** stores lines and answers minimum value queries at a point.
This implementation is **persistent**: every insertion returns a new tree while
old versions remain valid.

This package provides:

- `empty()` to create a tree
- `insert(tree, line, l, r)` to add a line over a fixed domain `[l, r)`
- `query(tree, x, l, r)` to get the minimum value at `x`
- `from_array(lines, l, r)` to build by repeated inserts
- `size(tree)` to count stored lines

---

## Problem restatement (plain words)

You have a set of linear functions:

```
line(x) = m*x + b
```

You need to answer queries like:

```
min over all lines of line(x)
```

The domain of `x` is a fixed integer range `[l, r)`.

---

## Core idea of Li Chao

Each node represents a segment `[l, r)` and stores **one line** that is best at
some part of the segment. When inserting a line, we compare it to the stored
line at the midpoint, keep the better one there, and push the worse one to the
side where it can still win.

Algorithm sketch:

```
insert(line, node [l, r)):
  mid = (l + r) / 2
  if line(mid) < node.line(mid): swap(line, node.line)
  if r - l == 1: stop
  if line(l) < node.line(l): insert line into left child
  else if line(r-1) < node.line(r-1): insert line into right child
```

This guarantees correctness while keeping only one line per node.

---

## Why it works (intuition)

If a new line is better at the midpoint, we keep it at this node. The old line
can still be better on one side, but only one side. That is why we recurse only
into left **or** right.

This keeps insertion time at `O(log domain)`.

---

## Small diagram

Imagine domain [0, 8):

```
[0,8)
  / \
[0,4) [4,8)
```

At each node, we keep the line that is best at the midpoint. The other line is
pushed down to the side where it could still win.

---

## Persistence (path copying)

Inserting a line creates a new tree by copying only the nodes on the path that
changes. All other nodes are shared.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert L       B'  C
  / \                      / \
 D   E                    D   E
```

---

## Reference implementation

```mbt
///| pub fn empty() -> Node

///| pub fn insert(tree : Node, line : Line, l : Int, r : Int) -> Node

///| pub fn query(tree : Node, x : Int, l : Int, r : Int) -> Int

///| pub fn from_array(lines : ArrayView[Line], l : Int, r : Int) -> Node

///| pub fn size(tree : Node) -> Int
```

---

## Tests and examples

### Example from the README

```mbt check
///|
test "persistent li chao" {
  let lines = [
    @challenge_persistent_li_chao_tree.Line::{ m: 1, b: 0 },
    @challenge_persistent_li_chao_tree.Line::{ m: -1, b: 10 },
    @challenge_persistent_li_chao_tree.Line::{ m: 2, b: -5 },
  ]
  let tree = @challenge_persistent_li_chao_tree.from_array(lines[:], 0, 10)
  inspect(
    @challenge_persistent_li_chao_tree.query(tree, 0, 0, 10),
    content="-5",
  )
  inspect(@challenge_persistent_li_chao_tree.query(tree, 5, 0, 10), content="5")
  inspect(@challenge_persistent_li_chao_tree.query(tree, 9, 0, 10), content="1")
  inspect(@challenge_persistent_li_chao_tree.size(tree), content="3")
}
```

### Incremental inserts

```mbt check
///|
test "persistent li chao insert" {
  let t0 = @challenge_persistent_li_chao_tree.empty()
  let t1 = @challenge_persistent_li_chao_tree.insert(
    t0,
    @challenge_persistent_li_chao_tree.Line::{ m: 1, b: 0 },
    0,
    5,
  )
  let t2 = @challenge_persistent_li_chao_tree.insert(
    t1,
    @challenge_persistent_li_chao_tree.Line::{ m: -1, b: 4 },
    0,
    5,
  )
  let t3 = @challenge_persistent_li_chao_tree.insert(
    t2,
    @challenge_persistent_li_chao_tree.Line::{ m: 0, b: 1 },
    0,
    5,
  )
  inspect(@challenge_persistent_li_chao_tree.query(t2, 2, 0, 5), content="2")
  inspect(@challenge_persistent_li_chao_tree.query(t3, 2, 0, 5), content="1")
}
```

### Persistence across versions

```mbt check
///|
test "persistent li chao versions" {
  let t0 = @challenge_persistent_li_chao_tree.empty()
  let t1 = @challenge_persistent_li_chao_tree.insert(
    t0,
    @challenge_persistent_li_chao_tree.Line::{ m: 2, b: 0 },
    0,
    6,
  )
  let t2 = @challenge_persistent_li_chao_tree.insert(
    t1,
    @challenge_persistent_li_chao_tree.Line::{ m: -1, b: 7 },
    0,
    6,
  )
  inspect(
    @challenge_persistent_li_chao_tree.query(t0, 3, 0, 6),
    content="1073741823",
  )
  inspect(@challenge_persistent_li_chao_tree.query(t1, 3, 0, 6), content="6")
  inspect(@challenge_persistent_li_chao_tree.query(t2, 3, 0, 6), content="4")
}
```

Note: querying an empty tree returns `0x3fffffff` (a large sentinel).

---

## Complexity

Let `D = r - l` be the domain width.

- Insert: `O(log D)`
- Query: `O(log D)`
- Memory per insert: `O(log D)` new nodes

---

## Takeaways

- Li Chao trees store one line per segment and swap at midpoints.
- Persistence keeps all versions after inserts.
- Domain `[l, r)` must be fixed and used consistently across inserts/queries.
