# Disjoint Sparse Table

## Overview

**Disjoint Sparse Table** is a variant of sparse table that supports O(1) range
queries for any associative operation (not just idempotent ones like min/max).
It achieves this by clever block decomposition.

- **Build**: O(n log n)
- **Query**: O(1)
- **Space**: O(n log n)

## The Problem with Regular Sparse Table

```
Regular sparse table stores answers for ranges of length 2^k.
For min/max (idempotent), we can overlap: min(0..7) = min(min(0..3), min(4..7))

But for sum or product (non-idempotent), overlap counts elements twice!
  sum(0..7) ≠ sum(0..3) + sum(4..7) when ranges overlap

Disjoint Sparse Table solves this by ensuring ranges never overlap.
```

## The Key Insight

```
At each level k, divide array into blocks of size 2^k.
Within each block, precompute prefix and suffix operations.

Level 2 (block size 4):
Array: [1, 2, 3, 4, 5, 6, 7, 8]
        └─block 0─┘ └─block 1─┘

Block 0: prefix sums from left: [1, 3, 6, 10]
         suffix sums from right: [10, 9, 7, 4]
Block 1: prefix sums: [5, 11, 18, 26]
         suffix sums: [26, 21, 15, 8]

Query [1, 6] spans blocks 0 and 1:
  Answer = suffix[1 in block 0] + prefix[6-4 in block 1]
         = 9 + 18 = 27 ✓
```

## Algorithm Walkthrough

```
Array: [3, 1, 4, 1, 5, 9, 2, 6]
        0  1  2  3  4  5  6  7

Build level 1 (block size 2):
  Block 0: [3,1] → prefix: [3, 4], suffix: [4, 1]
  Block 1: [4,1] → prefix: [4, 5], suffix: [5, 1]
  Block 2: [5,9] → prefix: [5,14], suffix: [14, 9]
  Block 3: [2,6] → prefix: [2, 8], suffix: [8, 6]

Build level 2 (block size 4):
  Block 0: [3,1,4,1] → prefix: [3,4,8,9], suffix: [9,6,5,1]
  Block 1: [5,9,2,6] → prefix: [5,14,16,22], suffix: [22,17,8,6]

Build level 3 (block size 8):
  Block 0: entire array → prefix/suffix sums

Query sum(2, 5):  indices 2,3,4,5
  Bit diff: 2 XOR 5 = 7, highest bit = 2
  Use level 2, mid point at index 4
  Answer = suffix[2] + prefix[5-4]
         = 5 + 14 = 19
  Check: 4 + 1 + 5 + 9 = 19 ✓
```

## Visual: Block Structure

```
Level 0: (no precomputation needed for single elements)
[3] [1] [4] [1] [5] [9] [2] [6]

Level 1 (block size 2):
[3, 1] [4, 1] [5, 9] [2, 6]
  ↓       ↓       ↓       ↓
 P S     P S     P S     P S

Level 2 (block size 4):
[3, 1, 4, 1] [5, 9, 2, 6]
      ↓             ↓
  →  3  4  8  9    5 14 16 22  (prefix →)
  ←  9  6  5  1   22 17  8  6  (← suffix)

Query (l, r): Find level where l and r are in different blocks,
              then combine suffix[l] with prefix[r].
```

## Finding the Right Level

```
The level to use is determined by the highest bit position
where l and r differ (after XOR).

l = 2 (010), r = 5 (101)
l XOR r = 111

Highest bit position = 2
Use level 2, where l and r are in different blocks.

This is O(1) using bit operations:
  level = highest_bit(l XOR r)
```

## Example Usage

```mbt check
///|
test "disjoint sparse sum example" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let dst = @disjoint_sparse.DisjointSparseSum::new(arr)
  inspect(dst.query(0, 3), content="Some(10)")
  inspect(dst.query(2, 5), content="Some(18)")
}
```

## The Query Algorithm

```
def query(l, r):
    if l == r:
        return arr[l]

    # Find level where l and r cross a block boundary
    level = highest_bit(l XOR r)

    # Combine suffix from l's block with prefix from r's block
    return combine(suffix[level][l], prefix[level][r])
```

## Common Applications

### 1. Range Sum Queries
```
Unlike segment tree, achieves O(1) query time.
Useful when queries vastly outnumber updates.
```

### 2. Range Product Queries
```
Compute product of elements in range.
Works for any associative operation.
```

### 3. Range GCD
```
While GCD is idempotent, DST works too.
Sometimes simpler than sparse table logic.
```

### 4. Matrix Chain Queries
```
For associative matrix multiplication,
DST gives O(1) per range product query.
```

## Complexity Analysis

| Operation | Time | Space |
|-----------|------|-------|
| Build | O(n log n) | O(n log n) |
| Query | O(1) | - |
| Update | Not supported | - |

## Sparse Table vs Disjoint Sparse Table

| Feature | Sparse Table | Disjoint Sparse |
|---------|--------------|-----------------|
| Build | O(n log n) | O(n log n) |
| Query | O(1) | O(1) |
| Operations | Idempotent only | Any associative |
| Space | O(n log n) | O(n log n) |

**Sparse Table**: Only min, max, gcd, bitwise OR/AND
**Disjoint Sparse**: Also +, ×, matrix multiply, etc.

**Choose Disjoint Sparse Table when**: You need O(1) queries for non-idempotent operations like sum or product.

## Why "Disjoint"?

```
The name comes from how ranges are combined:
they never overlap, so no double-counting.

Query [l, r] decomposes into:
  [l ... mid-1] (suffix) + [mid ... r] (prefix)

These are disjoint ranges within their blocks!
```

## Extension: 2D Disjoint Sparse Table

```
For 2D range queries:
- Build DST on rows
- Build DST on columns of row results
- Query: O(1) for rectangle sums

Space: O(n² log² n)
```

## Implementation Notes

- Use 0-indexed arrays for clean bit manipulation
- Store prefix and suffix separately for cache efficiency
- `highest_bit(x)` can use builtin `clz` (count leading zeros)
- Handle l == r case separately (no block crossing)
- Precompute logs table for faster highest bit calculation

