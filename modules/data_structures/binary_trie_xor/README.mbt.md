# Binary Trie for XOR Queries

A binary trie stores integers bit by bit and answers XOR queries quickly. It is
especially useful for problems like:

- "What is the maximum XOR value with x?"
- "What is the minimum XOR value with x?"

Brute force checks all numbers and costs O(n) per query. The trie reduces this
to O(B), where B is the number of bits.

## Trie structure

Each integer is stored as a path from the root down through B+1 nodes, one node
per bit from the most significant to the least significant. A `Node` has two
child slots (`next0` for bit 0, `next1` for bit 1) and a `count` that tracks
how many inserted values pass through it.

The following diagram shows a trie with `max_bits = 2` (bits 2, 1, 0) after
inserting 5 (101), 1 (001), and 7 (111):

```
                   root (count=3)
                  /               \
          bit2=0 (c=1)      bit2=1 (c=2)
              |              /         \
          bit1=0 (c=1)  bit1=0 (c=1)  bit1=1 (c=1)
              |              |              |
          bit0=1 (c=1)  bit0=1 (c=1)  bit0=1 (c=1)
            = 001           = 101          = 111
             (1)             (5)            (7)
```

Shared prefixes merge into the same node. The `count` field at every node equals
the number of currently inserted values whose bit path passes through that node.
Removing a value decrements every count along its path; a count reaching zero
means that subtree is logically empty even though the nodes remain allocated.

## Key idea: greedily choose bits

XOR is decided bit by bit from most significant to least significant. At each
bit position:

- To **maximize** XOR, choose the child whose bit **differs** from the
  corresponding bit of the query value (so that XOR bit = 1).
- To **minimize** XOR, choose the child whose bit **matches** the corresponding
  bit of the query value (so that XOR bit = 0).

Fall back to the only available child when the preferred one is absent or empty.

## Step-by-step: max_xor(2) on the trie above

Query value: 2 = 010 in binary (bits 2, 1, 0 = 0, 1, 0).

```
Bit 2: query bit = 0, prefer opposite = 1
        root has next1 (count=2) -> go right, XOR bit 2 = 1

Bit 1: query bit = 1, prefer opposite = 0
        node has next0 (count=1) -> go left, XOR bit 1 = 1

Bit 0: query bit = 0, prefer opposite = 1
        node has next1 (count=1) -> go right, XOR bit 0 = 1

Result: XOR = 1*4 + 1*2 + 1*1 = 7   (matched key = 5 = 101)
        2 XOR 5 = 7 [correct]
```

## Step-by-step: min_xor(2) on the trie above

Query value: 2 = 010 (bits 2, 1, 0 = 0, 1, 0).

```
Bit 2: query bit = 0, prefer same = 0
        root has next0 (count=1) -> go left, XOR bit 2 = 0

Bit 1: query bit = 1, prefer same = 1
        node has no next1 -> fall back to next0 (count=1), XOR bit 1 = 1

Bit 0: query bit = 0, prefer same = 0
        node has no next0 -> fall back to next1 (count=1), XOR bit 0 = 1

Result: XOR = 0*4 + 1*2 + 1*1 = 3   (matched key = 1 = 001)
        2 XOR 1 = 3 [correct]
```

## What this package provides

`BinaryTrie` supports:

- `insert(x)` and `remove(x)`
- `max_xor(x)` and `min_xor(x)`
- `size()`

Duplicates are supported by reference counts in each node.

## Example 1: basic usage

```mbt check
///|
test "basic xor queries" {
  let trie = @binary_trie_xor.BinaryTrie(3) // bits 3..0
  trie.insert(5L) // 0101
  trie.insert(1L) // 0001
  trie.insert(7L) // 0111
  debug_inspect(trie.size(), content="3")
  debug_inspect(trie.max_xor(2L), content="7") // 2 xor 5 = 7
  debug_inspect(trie.min_xor(2L), content="3") // 2 xor 1 = 3
}
```

Note: `max_xor` and `min_xor` return the **XOR value**, not the actual key.

## Example 2: duplicates and removal

```mbt check
///|
test "duplicates and remove" {
  let trie = @binary_trie_xor.BinaryTrie(2)
  trie.insert(3L) // 11
  trie.insert(3L) // duplicate
  trie.insert(1L) // 01
  debug_inspect(trie.size(), content="3")
  debug_inspect(trie.max_xor(0L), content="3")
  debug_inspect(trie.remove(3L), content="true")
  debug_inspect(trie.size(), content="2")
  debug_inspect(trie.max_xor(0L), content="3") // still present once
  debug_inspect(trie.remove(3L), content="true")
  debug_inspect(trie.size(), content="1")
  debug_inspect(trie.max_xor(0L), content="1")
}
```

## Example 3: empty trie behavior

```mbt check
///|
test "empty trie" {
  let trie = @binary_trie_xor.BinaryTrie(4)
  debug_inspect(trie.size(), content="0")
  debug_inspect(trie.max_xor(10L), content="0")
  debug_inspect(trie.min_xor(10L), content="0")
  debug_inspect(trie.remove(10L), content="false")
}
```

## Choosing `max_bits`

`max_bits` is the index of the highest bit you want to store. If all numbers
are in `[0, 2^k - 1]`, use `max_bits = k - 1`.

Examples:

- values up to 255 (8 bits) -> `max_bits = 7`
- values up to 1e9 (30 bits) -> `max_bits = 29`
- values up to 2^63 - 1 -> `max_bits = 62`

If you use too few bits, high bits are ignored and results are wrong. If you
use too many bits, the trie is still correct but uses more memory.

## Practical notes and pitfalls

- This trie assumes non-negative values (or that you treat Int64 as an unsigned
  bit pattern). For signed negatives, set `max_bits` high enough to include the
  sign bit.
- `remove` only decrements counts along a path that was previously inserted; it
  returns `false` if the path does not exist or is already empty.
- The structure stores only the XOR value, not which key produced it.
- Node memory is never freed after removal; only counts are decremented. The
  allocated node array grows monotonically with distinct inserted prefixes.

## Complexity

- Insert / Remove / Query: O(B)
- Space: O(N * B)

Here, `B = max_bits + 1`.
