# Binary Trie for XOR Queries

## Problem

Store many integers and answer queries like:

- "What is the maximum XOR with x?"
- "What is the minimum XOR with x?"

Checking all numbers is too slow.

## Simple Idea

Store numbers bit-by-bit in a binary trie (MSB → LSB).
For **max XOR**, try the opposite bit at each level.
For **min XOR**, try the same bit.

## How It Works

For each bit from high to low:

- Let `b` be the current bit of query `x`
- Max XOR: go to child `1 - b` if possible
- Min XOR: go to child `b` if possible
- Otherwise, take the only available child

Each step decides one bit of the XOR result.

## Example

```mbt check
///|
test "binary trie xor quick start" {
  let trie = @binary_trie_xor.BinaryTrie::new(5) // bits [5..0]
  trie.insert(5L)
  trie.insert(1L)
  trie.insert(7L)
  inspect(trie.size(), content="3")
  inspect(trie.max_xor(2L), content="7")
  inspect(trie.min_xor(2L), content="3")
}
```

## Duplicates

Each node keeps a count. This lets you:

- Insert duplicates
- Remove safely
- Detect empty trie

## Choosing max_bits

If values are in `[0, 2^k - 1]`, use `max_bits = k - 1`.

Example:

- values up to 255 → `max_bits = 7`
- values up to 1e9 → `max_bits = 29`

## Complexity

- Insert/Remove/Query: **O(B)**
- Space: **O(N × B)**

`B` is the bit width (e.g., 32 or 64).
