# Binary Trie for XOR Queries

## Overview

A **Binary Trie** stores integers by their binary representation, enabling
fast XOR-related queries. Find the number that gives maximum or minimum XOR
with a query value in O(B) time, where B is the bit width.

- **Time**: O(B) per operation
- **Space**: O(N · B)
- **Key Feature**: Fast maximum/minimum XOR queries

## The Key Insight

```
Problem: Find x in set S that maximizes x XOR q

Naive: Check all x in S → O(N)

Binary trie insight:
  Store numbers as paths in a binary tree (MSB to LSB).
  To maximize XOR, at each bit, try to go OPPOSITE direction of query bit!

Query q = 1010:
  Bit 3 (q=1): Want to go 0 branch (1 XOR 0 = 1)
  Bit 2 (q=0): Want to go 1 branch (0 XOR 1 = 1)
  Bit 1 (q=1): Want to go 0 branch
  Bit 0 (q=0): Want to go 1 branch

By going opposite at each bit, we maximize the XOR result!
If opposite branch doesn't exist, take the available one.
```

## Visual: Binary Trie Structure

```
Insert: 5 (101), 1 (001), 7 (111) with 3 bits

         root
        /    \
       0      1
       |     / \
       0    0   1
       |    |   |
       1    1   1
       ↓    ↓   ↓
      [1]  [5] [7]

Query max_xor(2) where 2 = 010:
  Bit 2 (q=0): Want 1-branch, exists! Go right → 1
  Bit 1 (q=1): Want 0-branch, exists! Go left → 0
  Bit 0 (q=0): Want 1-branch, exists! Go right → 1

  Found: 101 = 5
  XOR: 5 XOR 2 = 7 ✓ (maximum possible)
```

## Algorithm: Maximum XOR

```
max_xor(query):
  node = root
  result = 0

  for bit = max_bits downto 0:
    query_bit = (query >> bit) & 1
    want_bit = 1 - query_bit  // Opposite bit

    if child[want_bit] exists and has elements:
      // Go opposite direction to maximize XOR
      result |= (1 << bit)
      node = child[want_bit]
    else:
      // Must go same direction
      node = child[query_bit]

  return result
```

## Algorithm: Minimum XOR

```
min_xor(query):
  node = root
  result = 0

  for bit = max_bits downto 0:
    query_bit = (query >> bit) & 1

    if child[query_bit] exists and has elements:
      // Go same direction to minimize XOR
      node = child[query_bit]
    else:
      // Must go opposite direction
      result |= (1 << bit)
      node = child[1 - query_bit]

  return result
```

## Example Usage

```mbt check
///|
test "binary trie xor quick start" {
  // max_bits = 5 means the trie stores bits [5..0]
  let trie = @binary_trie_xor.BinaryTrie::new(5)
  trie.insert(5L) // 0b00101
  trie.insert(1L) // 0b00001
  trie.insert(7L) // 0b00111
  inspect(trie.size(), content="3")
  inspect(trie.max_xor(2L), content="7")
  inspect(trie.min_xor(2L), content="3")
}
```

```mbt check
///|
test "binary trie delete and duplicates" {
  let trie = @binary_trie_xor.BinaryTrie::new(5)
  trie.insert(5L)
  trie.insert(5L)
  inspect(trie.size(), content="2")
  inspect(trie.remove(5L), content="true")
  inspect(trie.size(), content="1")
  inspect(trie.remove(5L), content="true")
  inspect(trie.size(), content="0")
  inspect(trie.remove(5L), content="false")
}
```

## Algorithm Walkthrough

```
Trie contains: {5, 1, 7} with max_bits = 2

Tree structure (3 bits: positions 2, 1, 0):
       root [count=3]
      /    \
     0[1]   1[2]
     |     / \
     0[1] 0[1] 1[1]
     |    |    |
     1[1] 1[1] 1[1]
     ↓    ↓    ↓
    [1]  [5]  [7]

Query: max_xor(2), where 2 = 010

Bit 2: query_bit = 0, want 1
  1-branch has count=2, go right
  result = 100 (4)

Bit 1: query_bit = 1, want 0
  0-branch has count=1, go left
  result = 100 (4)

Bit 0: query_bit = 0, want 1
  1-branch has count=1, go right
  result = 101 (5)

Answer: XOR result = 5, meaning 5 XOR 2 = 7 (max XOR value)
Wait, the return should be the XOR VALUE not the number...

Actually max_xor returns the XOR value:
  We found number 5, and 5 XOR 2 = 7
  Return 7 ✓
```

## Handling Duplicates

```
Each node has a count field.
  insert(x): Increment count along path
  remove(x): Decrement count along path

A node exists for queries if count > 0.

This allows:
  - Multiple copies of same number
  - Safe removal (don't remove more than inserted)
  - Empty trie detection (root count = 0)
```

## Common Applications

### 1. Maximum XOR Pair
```
Given array, find two elements with maximum XOR.
Insert all elements, then query each element.
O(N·B) total.
```

### 2. Maximum XOR Subarray
```
Prefix XOR + binary trie.
For each prefix, find best previous prefix to XOR with.
```

### 3. Persistent XOR Queries
```
With version tracking, answer:
"Max XOR with x considering only first k insertions"
```

### 4. Range XOR Maximum
```
Combined with segment tree or other structures
for range-based XOR queries.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Insert | O(B) | Walk B bits |
| Remove | O(B) | Walk B bits |
| Max XOR | O(B) | Greedy traversal |
| Min XOR | O(B) | Greedy traversal |
| Space | O(N·B) | Up to 2N·B nodes |

## Choosing max_bits

```
max_bits determines the bit range [max_bits, 0].

For values in [0, 2^k - 1], use max_bits = k - 1.

Examples:
  Values up to 63 (2^6 - 1): max_bits = 5
  Values up to 255 (2^8 - 1): max_bits = 7
  Values up to 10^9 (≈ 2^30): max_bits = 29
  Values up to 10^18 (≈ 2^60): max_bits = 59
```

## Binary Trie vs Other Structures

| Structure | Max XOR Query | Insert | Space |
|-----------|---------------|--------|-------|
| Binary Trie | O(B) | O(B) | O(N·B) |
| Sorted Array | O(N) | O(N) | O(N) |
| Hash Set | O(N) | O(1) | O(N) |

**Choose Binary Trie when**: XOR queries are frequent and B is reasonable.

## Implementation Notes

- Process bits from MSB to LSB (high to low)
- Use node counts to track "existence" for queries
- Handle empty trie case (return 0 or sentinel)
- Can extend to handle negative numbers with care
- Memory can be optimized with path compression

## Variations

```
1. Persistent Binary Trie:
   Keep versions for historical queries.
   Useful for "max XOR with elements added before time t".

2. Deletable Binary Trie (this package):
   Track counts to support removal.

3. K-th Maximum XOR:
   Extend with subtree sizes to find k-th best XOR.

4. XOR Basis (different structure):
   For finding if XOR of some subset equals target.
   Uses Gaussian elimination, O(B²) space.
```

