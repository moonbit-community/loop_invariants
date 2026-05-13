# Challenge: Persistent Patricia Trie (Okasaki, Big-Endian)

A **Patricia trie** is a binary trie that *compresses unary chains*: rather
than allocating one tree level per key bit, it allocates one level per
*distinguishing* bit. The result is a much smaller tree without losing the
"each step picks left or right by one bit" structure that makes lookup so
predictable.

This package provides:

- `empty()` to create a trie
- `insert(trie, key)` to insert (persistent, ignores duplicates)
- `contains(trie, key)` to test membership
- `size(trie)` to count keys
- `from_array(arr)` to build by repeated insertion

The trie is persistent: `insert` returns a new version that shares every
off-path subtree with its input.

---

## What is a Patricia trie?

Consider a plain binary trie storing the keys `4` (`100`) and `5` (`101`):

```
            *
           /
          0
         /
        *
       /
      0
     /
    *
   / \
  0   1
  |   |
  4   5
```

Most of those interior nodes are *unary*: they have a single child and add
no information. A Patricia trie collapses every such chain into a single
`Branch` node that records exactly the bit position where the two subtrees
diverge:

```
   Branch(prefix=0b100, mask=0b001)
        /                \
      4 (0b100)        5 (0b101)
```

Both children share the prefix `100` in the bits above `mask = 001`; they
disagree at the bit selected by `mask`.

---

## How `prefix` + `mask` encode the branching position

Each `Branch` node stores two integers:

- `mask`   : a power of two, i.e. an integer with exactly one bit set. That
             bit identifies the *branching position* — every key in `left`
             has `0` there, every key in `right` has `1`.
- `prefix` : the common bits of every key in the subtree, with the
             branching bit and everything below it cleared. Equivalently,
             `mask_key(k, mask)` is the same for every key `k` in the
             subtree.

```
    bit:  31 ............ b+1   b   b-1 ........ 0
          [-- common prefix --][ * ][-- diverges --]
                                ^
                                mask bit; left has 0, right has 1
          [---- prefix -------][ 0 ][----- 0 -----]   <- stored prefix
```

Two helper predicates extract these fields:

- `zero_bit(key, mask) = (key & mask) == 0`     — which child a key falls into.
- `match_prefix(key, prefix, mask)`             — does `key` even belong in
                                                   this subtree?

---

## Big-endian vs little-endian Patricia

Okasaki's paper considers two orderings:

| Variant       | Root branches on            | Used here? |
|---------------|-----------------------------|------------|
| Big-endian    | The *most* significant differing bit  | yes |
| Little-endian | The *least* significant differing bit | no  |

Big-endian Patricia keeps lexicographic / numerical neighbours close in the
tree and is the right choice when keys are interpreted as integers. (It
also matches the natural reading of the bit pattern from left to right.)

---

## The `join` algorithm (four lines)

When `insert` reaches a `Branch` whose prefix does **not** match the new
key, the two subtrees must be merged at their highest disagreeing bit. The
`join` helper does this in four lines:

```
fn join(p1, t1, p2, t2):
  let m = branching_bit(p1, p2)      // single-bit Int: the highest
                                     // position where p1 and p2 differ
  let p = mask_key(p1, m)            // common prefix above bit m
  if zero_bit(p1, m): Branch(p, m, t1, t2)
  else:               Branch(p, m, t2, t1)
```

ASCII view:

```
   p1, t1 ---+
             |             Branch(prefix = p, mask = m)
             |              /                       \
             +-->     (subtree whose `m` bit     (subtree whose `m` bit
   p2, t2 ---+         is zero, i.e. t1 or t2)    is one)
```

`branching_bit(p1, p2)` is the highest set bit of `p1 XOR p2`. Since `p1`
and `p2` agree above bit `m` and disagree at `m`, `mask_key(p1, m) ==
mask_key(p2, m)`, so the freshly built `prefix` is valid.

---

## Worked example: insert `4, 1, 5, 7`

Keys in binary:

| key | binary  |
|-----|---------|
| 4   | `100`   |
| 1   | `001`   |
| 5   | `101`   |
| 7   | `111`   |

1. Insert `4` into the empty trie:

   ```
   Leaf(4)
   ```

2. Insert `1`. Branching bit between `4 = 100` and `1 = 001` is `100` (bit
   2). `zero_bit(4, 100)` is false, so `4` goes right; `1` goes left.

   ```
                Branch(prefix=000, mask=100)
                /                \
            Leaf(1)             Leaf(4)
   ```

3. Insert `5`. `match_prefix(5=101, 000, 100)` is false (`5 & ~111 = 000`
   matches the prefix; actually `mask_key(5, 100) = 000` matches, so yes
   it does match), so we descend right (`zero_bit(5, 100)` is false). At
   `Leaf(4)`: branching bit between `4 = 100` and `5 = 101` is `001`.

   ```
                Branch(prefix=000, mask=100)
                /                \
            Leaf(1)         Branch(prefix=100, mask=001)
                              /                \
                          Leaf(4)            Leaf(5)
   ```

4. Insert `7`. `match_prefix(7=111, 000, 100)` holds, descend right.
   `match_prefix(7, 100, 001)` is false (`mask_key(7, 001) = 110` ≠
   `100`), so `join(7, Leaf(7), 100, Branch(...))`. Branching bit between
   `7 = 111` and `100` is `010`.

   ```
                Branch(prefix=000, mask=100)
                /                \
            Leaf(1)         Branch(prefix=100, mask=010)
                              /                \
                  Branch(p=100, m=001)        Leaf(7)
                      /          \
                  Leaf(4)      Leaf(5)
   ```

Every interior node carries exactly one bit's worth of branching, and the
tree has exactly four leaves — one per inserted key.

---

## Reference operations

```
pub fn empty() -> Trie
pub fn insert(t : Trie, key : Int) -> Trie
pub fn contains(t : Trie, key : Int) -> Bool
pub fn size(t : Trie) -> Int
pub fn from_array(arr : ArrayView[Int]) -> Trie
```

---

## Tests and examples

### Basic insert / contains round-trip

```mbt check
///|
test "patricia basic" {
  let t = @challenge_persistent_patricia_trie.from_array([4, 1, 5, 7])
  debug_inspect(@challenge_persistent_patricia_trie.size(t), content="4")
  debug_inspect(
    @challenge_persistent_patricia_trie.contains(t, 4),
    content="true",
  )
  debug_inspect(
    @challenge_persistent_patricia_trie.contains(t, 6),
    content="false",
  )
}
```

### Old versions are independent of new ones

```mbt check
///|
test "patricia persistent versions" {
  let t0 = @challenge_persistent_patricia_trie.empty()
  let t1 = @challenge_persistent_patricia_trie.insert(t0, 10)
  let t2 = @challenge_persistent_patricia_trie.insert(t1, 5)
  let t3 = @challenge_persistent_patricia_trie.insert(t2, 20)
  // t0 never saw 10
  debug_inspect(
    @challenge_persistent_patricia_trie.contains(t0, 10),
    content="false",
  )
  // t1 only knows 10
  debug_inspect(
    @challenge_persistent_patricia_trie.contains(t1, 10),
    content="true",
  )
  debug_inspect(
    @challenge_persistent_patricia_trie.contains(t1, 5),
    content="false",
  )
  debug_inspect(@challenge_persistent_patricia_trie.size(t3), content="3")
}
```

### Duplicates are ignored (set semantics)

```mbt check
///|
test "patricia duplicates" {
  let t0 = @challenge_persistent_patricia_trie.empty()
  let t1 = @challenge_persistent_patricia_trie.insert(t0, 42)
  let t2 = @challenge_persistent_patricia_trie.insert(t1, 42)
  debug_inspect(@challenge_persistent_patricia_trie.size(t1), content="1")
  debug_inspect(@challenge_persistent_patricia_trie.size(t2), content="1")
}
```

### Mixed positive and negative keys

```mbt check
///|
test "patricia signed keys" {
  let t = @challenge_persistent_patricia_trie.from_array([3, -1, 0, -5, 7])
  debug_inspect(@challenge_persistent_patricia_trie.size(t), content="5")
  debug_inspect(
    @challenge_persistent_patricia_trie.contains(t, -5),
    content="true",
  )
  debug_inspect(
    @challenge_persistent_patricia_trie.contains(t, -2),
    content="false",
  )
}
```

---

## Complexity

Let `k` be the key bit width (32 for `Int`) and `n` the number of keys
currently in the trie.

| Operation  | Time              | Extra memory    |
|------------|-------------------|-----------------|
| `empty`    | `O(1)`            | `O(1)`          |
| `insert`   | `O(min(k, log n))`| `O(min(k, log n))` |
| `contains` | `O(min(k, log n))`| `O(1)`          |
| `size`     | `O(n)`            | `O(log n)` stk  |

For sparse key sets the height is bounded by `O(log n)` because every
interior node has two non-empty subtrees of disjoint prefix; for dense
sets it is bounded by the bit width `k`. In practice both bounds are
small and `O(log n)` is a good rule of thumb.

---

## Comparison with `@challenge_persistent_binary_trie`

`@challenge_persistent_binary_trie` is a plain *uniform-depth* binary trie:
every key descends exactly `max_bit + 1` levels, with one node per bit
regardless of whether keys actually disagree at that level. That structure
is ideal for max-XOR queries — every greedy step picks the opposite bit if
available — but allocates one interior node per bit per inserted key.

A Patricia trie keeps the same one-bit-per-step descent semantics but
*collapses unary chains*: if every key passing through a level agrees on
the next several bits, those bits are bundled into the `prefix` of a single
`Branch` node and only one allocation is made for the entire run. So:

| Aspect                       | Uniform binary trie | Patricia trie      |
|------------------------------|---------------------|--------------------|
| Nodes per `insert`           | `Θ(k)`              | `O(min(k, log n))` |
| Supports max-XOR efficiently | Yes (counts at each bit) | Not directly  |
| Branching bit explicit       | No (implicit in depth) | Yes (`mask`)  |
| Keys are                     | non-negative integers + given bit width | arbitrary 32-bit Ints |

For a set-membership data structure on integer keys, Patricia tries are
usually the better choice; for max-XOR / digit-DP style queries on a
known bit width, the uniform trie is more convenient.

---

## Takeaways

- A Patricia trie is a binary trie with unary chains collapsed.
- Each `Branch` records the single-bit `mask` where its two subtrees
  diverge and the `prefix` shared above that bit.
- `join` builds a new branch from two distinct prefixes in four lines:
  compute the branching bit, compute the common prefix, decide which
  side each subtree falls on.
- Path copying makes the structure fully persistent at `O(min(k, log n))`
  extra memory per `insert`.
