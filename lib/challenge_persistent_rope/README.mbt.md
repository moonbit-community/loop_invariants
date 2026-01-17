# Challenge: Persistent Rope

A **rope** stores strings in a binary tree so that concatenation is cheap.
This implementation is **persistent**, so every concatenation returns a new
rope while old ropes remain valid and share structure.

This package provides:

- `empty()` to create an empty rope
- `leaf(value)` to create a rope from a string
- `concat(a, b)` to join two ropes
- `concat_many(ropes)` to join a list of ropes
- `length(r)` to get total length
- `to_string(r)` to flatten into a normal string

---

## Why ropes exist

If you concatenate many strings with `+`, you can end up copying large prefixes
repeatedly. Ropes avoid that by storing a **tree of pieces**.

Each internal node stores the total length, and leaves store actual string
chunks.

---

## Structure

```
        Node(len)
        /       \
     Rope       Rope
```

Example for "hello world":

```
           (len=11)
           /      \
      "hello"    " world"
```

Concatenation just creates a new parent node.

---

## Persistence (path sharing)

Concatenation does not copy the strings. It creates a new node pointing to the
old ropes:

```
Old ropes:               New rope:

   A        B               (A+B)
  / \      / \              /   \
 ...      ...             A       B
```

Old versions are still usable.

---

## Important note

This rope implementation does not rebalance. If you build a very skewed tree,
operations like `to_string` may become deep recursion. For large workloads,
balanced ropes or rope rebalancing are useful.

---

## Reference implementation

```mbt
///| pub fn empty() -> Rope

///| pub fn leaf(value : String) -> Rope

///| pub fn concat(a : Rope, b : Rope) -> Rope

///| pub fn concat_many(ropes : ArrayView[Rope]) -> Rope

///| pub fn length(r : Rope) -> Int

///| pub fn to_string(r : Rope) -> String
```

---

## Tests and examples

### Concatenate many

```mbt check
///|
test "persistent rope" {
  let r1 = @challenge_persistent_rope.leaf("hello")
  let r2 = @challenge_persistent_rope.leaf(" ")
  let r3 = @challenge_persistent_rope.leaf("world")
  let rope = @challenge_persistent_rope.concat_many([r1, r2, r3][:])
  inspect(@challenge_persistent_rope.to_string(rope), content="hello world")
  inspect(@challenge_persistent_rope.length(rope), content="11")
}
```

### Simple concat

```mbt check
///|
test "persistent rope concat" {
  let a = @challenge_persistent_rope.leaf("foo")
  let b = @challenge_persistent_rope.leaf("bar")
  let rope = @challenge_persistent_rope.concat(a, b)
  inspect(@challenge_persistent_rope.to_string(rope), content="foobar")
  inspect(@challenge_persistent_rope.length(rope), content="6")
}
```

### Persistence across versions

```mbt check
///|
test "persistent rope versions" {
  let r1 = @challenge_persistent_rope.leaf("a")
  let r2 = @challenge_persistent_rope.concat(
    r1,
    @challenge_persistent_rope.leaf("b"),
  )
  let r3 = @challenge_persistent_rope.concat(
    r2,
    @challenge_persistent_rope.leaf("c"),
  )
  inspect(@challenge_persistent_rope.to_string(r1), content="a")
  inspect(@challenge_persistent_rope.to_string(r2), content="ab")
  inspect(@challenge_persistent_rope.to_string(r3), content="abc")
}
```

---

## Complexity

Let `n` be the number of rope nodes.

- `concat`: `O(1)`
- `length`: `O(1)` (stored in node)
- `to_string`: `O(n)` (visits all nodes)

---

## Takeaways

- Ropes are great for lots of concatenations.
- Persistence makes sharing cheap.
- Flattening to a string is linear in the rope size.
