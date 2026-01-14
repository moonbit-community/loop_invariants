# Sqrt Decomposition

## Overview

**Sqrt Decomposition** is a technique that divides an array into √n blocks,
enabling O(√n) queries and updates. It's simpler than segment trees while
still being efficient for many range query problems.

- **Time**: O(√n) per query/update
- **Space**: O(n)
- **Key Feature**: Simple to implement, works for many aggregate functions

## The Key Insight

```
Problem: Range queries on an array (sum, min, max, etc.)

Segment Tree: O(log n) but complex to implement
Sqrt Decomposition: O(√n) but much simpler!

The insight: Split array into √n blocks of size √n

Array: [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9]
       |-------|-------|-------|-------|-------|
       Block 0 Block 1 Block 2 Block 3 Block 4

Block sums: [9,    16,     14,     16,    25]

Query [2, 11]:
  - Partial block 0: elements [2] = 4
  - Full blocks 1,2: sums = 16 + 14 = 30
  - Partial block 3: elements [9,10,11] = 3 + 5 + 8 = 16
  Total = 4 + 30 + 16 = 50

At most √n elements scanned + √n blocks checked = O(√n)
```

## Visual: Block Structure

```
Array indices:    0   1   2   3   4   5   6   7   8   9  10  11
Array values:   [ 3 | 1 | 4 | 1 | 5 | 9 | 2 | 6 | 5 | 3 | 5 | 8 ]
                |-----------|-----------|-----------|-----------|
                  Block 0     Block 1     Block 2     Block 3
                  sum=9       sum=16      sum=14      sum=16

block_size = ceil(sqrt(12)) = 4

For index i: block_id = i / block_size

Query range_sum(3, 9):
  Left partial:   i=3 (Block 0)     → scan element 3: value=1
  Middle blocks:  Block 1, Block 2  → use precomputed: 16+14=30
  Right partial:  i=9 (Block 3)     → scan element 9: value=3

  Answer: 1 + 30 + 3 = 34
```

## Algorithm: Range Query

```
range_sum(l, r):
  sum = 0

  // Phase 1: Left partial block
  while l <= r AND l % block_size != 0:
    sum += arr[l]
    l++

  // Phase 2: Full blocks in the middle
  while l + block_size - 1 <= r:
    sum += block_sum[l / block_size]
    l += block_size

  // Phase 3: Right partial block
  while l <= r:
    sum += arr[l]
    l++

  return sum
```

## Algorithm: Point Update

```
update(i, new_val):
  old_val = arr[i]
  arr[i] = new_val

  block_id = i / block_size
  block_sum[block_id] += (new_val - old_val)
```

## Common Patterns

### 1. Range Sum with Point Update

```
Precompute: block_sum[b] = sum of all elements in block b
Query: O(√n) using partial + full blocks
Update: O(1) - adjust one block sum
```

### 2. Range Minimum with Point Update

```
Precompute: block_min[b] = minimum in block b
Query: O(√n) - check partial elements + block minimums
Update: O(√n) - may need to recompute entire block minimum
```

### 3. Range Update with Point Query

```
Precompute: block_add[b] = value added to entire block b
Range Update [l,r] += v:
  - Partial blocks: update individual elements
  - Full blocks: update block_add[b]
Point Query: arr[i] + block_add[block_of(i)]
```

## Why √n is Optimal

```
With block size B:
  - Partial block scan: O(B) elements
  - Full blocks to check: O(n/B) blocks

Total: O(B + n/B)

Minimize by calculus: derivative = 1 - n/B² = 0
  → B² = n → B = √n

So O(√n + n/√n) = O(2√n) = O(√n)
```

## Common Applications

### 1. Range Queries
```
Sum, min, max, GCD over ranges.
Simpler than segment tree for basic operations.
```

### 2. Mo's Algorithm
```
Answer offline range queries by sorting queries
and using sqrt decomposition on query order.
```

### 3. Heavy-Light Decomposition Alternative
```
For simple tree path queries, sqrt decomposition
on the flattened tree can be easier to implement.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Build | O(n) | Compute block aggregates |
| Range Query | O(√n) | At most 2√n elements + √n blocks |
| Point Update | O(1) or O(√n) | Depends on aggregate |
| Range Update | O(√n) | Touch at most 2 partial blocks |

## Sqrt Decomposition vs Segment Tree

| Feature | Sqrt Decomposition | Segment Tree |
|---------|-------------------|--------------|
| Query Time | O(√n) | O(log n) |
| Update Time | O(1) to O(√n) | O(log n) |
| Implementation | Simple | Moderate |
| Memory | O(n) | O(n) |
| Lazy Propagation | Harder | Built-in |

**Choose Sqrt Decomposition when**:
- O(√n) is acceptable and you want simple code
- Building Mo's algorithm for offline queries
- Quick prototyping before optimizing to segment tree

## Implementation Notes

- Block size: use `(n + block_size - 1) / block_size` to get number of blocks
- Handle edge cases: empty ranges, single element ranges
- For non-associative operations, may need different approach
- Can combine with other techniques (e.g., lazy propagation per block)

