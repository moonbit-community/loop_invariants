# Challenge: Persistent Binary Trie (Max XOR)

A **binary trie** stores integers by their bits. This persistent version
supports path-copying inserts and fast maximum-xor queries.

This package provides:

- `empty()` to create a trie
- `insert(trie, value, bit)` to insert a number and return a new trie
- `max_xor(trie, value, max_bit)` to find the maximum xor with `value`
- `count(trie)` to see how many values are stored

---

## What is a binary trie?

Each number is written in binary, and each bit is a step left/right:

```
bit = 2  bit = 1  bit = 0

value 5 = 101
path: 1 -> 0 -> 1
```

A node has two children:

- `zero`: bit 0
- `one`: bit 1

Example with values 2 (010) and 5 (101):

```
(bit 2)
        *
       / \
      0   1
     /     \
(bit1)      (bit1)
   1          0
   |          |
(bit0)      (bit0)
   0          1
```

---

## Max XOR query

To maximize `value XOR x`, we want to pick the **opposite bit** at each level
if possible:

- If bit of `value` is 0, we prefer a `1` child
- If bit of `value` is 1, we prefer a `0` child

This greedy choice works because higher bits are more significant.

---

## Persistence (path copying)

Every insertion creates a new trie version. Only the nodes along the updated
path are copied; all other nodes are shared.

```
Old version:               New version:

    root                     root'
    /  \                     /   \
   A    B     insert x      A'    B
  / \                       / \
 C   D                     C   D
```

This gives `O(max_bit)` extra memory per insertion.

---

## Choosing max_bit

You must supply the highest bit you care about:

- For values up to 10^9, use `max_bit = 30`
- For non-negative 32-bit values, use `max_bit = 31`
- For signed 64-bit values, use `max_bit = 62` or `63`

The trie stores only those bits. Queries should use the same `max_bit`.

---

## Reference implementation

```mbt
///| pub fn empty() -> Node

///| pub fn count(node : Node) -> Int

///| pub fn insert(node : Node, value : Int, bit : Int) -> Node

///| pub fn max_xor(root : Node, value : Int, max_bit : Int) -> Int
```

---

## Tests and examples

### Basic max xor

```mbt check
///|
test "binary trie max xor" {
  let t0 = @challenge_persistent_binary_trie.empty()
  let t1 = @challenge_persistent_binary_trie.insert(t0, 2, 3)
  let t2 = @challenge_persistent_binary_trie.insert(t1, 5, 3)
  // value 2 (0010) xor 5 (0101) = 7
  let best = @challenge_persistent_binary_trie.max_xor(t2, 2, 3)
  inspect(best, content="7")
}
```

### Persistence across versions

```mbt check
///|
test "binary trie persistence" {
  let t0 = @challenge_persistent_binary_trie.empty()
  let t1 = @challenge_persistent_binary_trie.insert(t0, 1, 2)
  let t2 = @challenge_persistent_binary_trie.insert(t1, 3, 2)
  let best1 = @challenge_persistent_binary_trie.max_xor(t1, 2, 2)
  let best2 = @challenge_persistent_binary_trie.max_xor(t2, 2, 2)
  inspect(best1, content="3")
  inspect(best2, content="3")
  inspect(@challenge_persistent_binary_trie.count(t0), content="0")
  inspect(@challenge_persistent_binary_trie.count(t2), content="2")
}
```

### Duplicates

```mbt check
///|
test "binary trie duplicates" {
  let t0 = @challenge_persistent_binary_trie.empty()
  let t1 = @challenge_persistent_binary_trie.insert(t0, 4, 3)
  let t2 = @challenge_persistent_binary_trie.insert(t1, 4, 3)
  inspect(@challenge_persistent_binary_trie.count(t1), content="1")
  inspect(@challenge_persistent_binary_trie.count(t2), content="2")
}
```

---

## Complexity

Let `B = max_bit + 1`:

- Insert: `O(B)` time, `O(B)` extra memory
- Max XOR query: `O(B)` time

---

## Takeaways

- Binary tries maximize xor by preferring opposite bits.
- Persistence shares structure between versions with low memory overhead.
- The `max_bit` parameter controls the depth and must be consistent.
