# Mo's Algorithm

## Overview

**Mo's Algorithm** is a technique for answering offline range queries efficiently.
By cleverly ordering queries, it achieves O((n + q) × √n) time complexity for
problems where adding/removing elements is O(1).

- **Time**: O((n + q) × √n)
- **Space**: O(n)
- **Requirement**: Queries must be offline (known in advance)

## The Key Insight

```
Instead of processing queries in input order, sort them to minimize
pointer movement between consecutive queries.

Naive approach: Reset window for each query → O(n) per query → O(nq) total

Mo's approach: Sort queries so consecutive ones have similar [l, r]
              → Total pointer movement is O((n + q) × √n)

Query order matters!
  Bad:  [0,100], [50,60], [0,100], [55,65]
  Good: [0,100], [0,100], [50,60], [55,65]  ← sorted by (l/√n, r)
```

## Block-Based Sorting

```
Divide array into √n blocks. Sort queries by:
  1. Primary: block of left endpoint (l / √n)
  2. Secondary: right endpoint (r)

Array: [_, _, _, | _, _, _, | _, _, _]  (√n ≈ 3)
       Block 0    Block 1    Block 2

Queries sorted:
  Block 0: [0,5], [1,8], [2,3]  ← all have l in [0,3), sorted by r
  Block 1: [3,7], [4,9], [5,6]  ← all have l in [3,6), sorted by r
  Block 2: [6,8], [7,9], [8,9]  ← all have l in [6,9), sorted by r
```

## Algorithm Walkthrough

```
Array: [1, 2, 1, 3, 2, 1, 2, 3]  (n = 8, block size = 3)
Queries: count distinct in ranges
  Q0: [0, 3], Q1: [2, 5], Q2: [1, 7], Q3: [4, 6]

After sorting by (l/3, r):
  Q0: [0, 3] (block 0, r=3)
  Q2: [1, 7] (block 0, r=7)
  Q1: [2, 5] (block 0, r=5) <- wait, 5 < 7, so actually:

Re-sort:
  Block 0 (l in [0,3)): Q0[0,3], Q1[2,5], Q2[1,7] sorted by r
  → [0,3] r=3, [2,5] r=5, [1,7] r=7

Initial: cur_l = 0, cur_r = -1 (empty window)

Process Q0 [0,3]:
  Expand right: add 1,2,1,3 → window = [1,2,1,3]
  Distinct count = 3 (values 1,2,3)

Process Q1 [2,5]:
  Shrink left: remove 1,2 → window = [1,3]
  Expand right: add 2,1 → window = [1,3,2,1]
  Distinct count = 3

Process Q2 [1,7]:
  Expand left: add 2 → window = [2,1,3,2,1,2,3]
  Expand right: add 2,3 → ...
  Distinct count = 3
```

## Visual: Pointer Movement

```
Array indices:  0   1   2   3   4   5   6   7
                [───────────────────────────]

Query [0,3]:    [═══════]
                L       R

Query [2,5]:        [═══════]
                    L       R
                ←─L moves 2 steps, R moves 2 steps

Query [1,7]:      [═════════════════]
                  L                 R
                ←─L moves 1 step, R moves 2 steps

Total movement: O(√n) per query on average
```

## Maintaining Window State

```
For distinct count, maintain frequency array:

add(x):
  freq[x]++
  if freq[x] == 1: distinct++

remove(x):
  freq[x]--
  if freq[x] == 0: distinct--

Both operations are O(1)!
```

## Example Usage

```mbt nocheck
// Define add/remove operations
fn add(x : Int, freq : Array[Int], distinct : Ref[Int]) -> Unit {
  freq[x] += 1
  if freq[x] == 1 {
    distinct.val += 1
  }
}

fn remove(x : Int, freq : Array[Int], distinct : Ref[Int]) -> Unit {
  freq[x] -= 1
  if freq[x] == 0 {
    distinct.val -= 1
  }
}

// Sort queries, process with Mo's algorithm
let block_size = sqrt(n)
queries.sort_by((a, b) =>
  if a.l / block_size != b.l / block_size { (a.l / block_size) - (b.l / block_size) }
  else { a.r - b.r })

// Process queries...
```

## Common Applications

### 1. Distinct Elements in Range
```
Count unique values in [l, r].
Maintain frequency array, O(1) add/remove.
```

### 2. Mode Query (Most Frequent)
```
Find most frequent element in [l, r].
Maintain frequency of frequencies.
```

### 3. Range XOR/Sum with Updates
```
Combine with block decomposition.
Rebuild every √n updates.
```

### 4. Tree Queries (Mo on Trees)
```
Flatten tree with Euler tour.
Handle paths using LCA.
```

## Complexity Analysis

```
Why O((n + q) × √n)?

Right pointer (R):
  Within each block, R only moves forward → O(n) per block
  √n blocks × O(n) movement = O(n × √n)

Left pointer (L):
  Between queries in same block, L moves at most √n
  q queries × O(√n) movement = O(q × √n)

Total: O((n + q) × √n)
```

## Mo's Algorithm vs Other Approaches

| Approach | Time | Requirements |
|----------|------|--------------|
| **Mo's Algorithm** | O((n+q)√n) | Offline, O(1) add/remove |
| Segment Tree | O((n+q) log n) | Online, associative operation |
| Sqrt Decomposition | O(q√n) | Online, block-decomposable |
| Heavy precomputation | O(n² + q) | Lots of memory |

**Choose Mo's when**: Queries are offline and no good segment tree exists.

## Optimizations

```
Alternating sort order:
  For even blocks: sort by r ascending
  For odd blocks:  sort by r descending

This reduces total R movement by ~50%!

Block size tuning:
  Default: √n
  Sometimes n^(2/3) or empirically tuned values work better
```

## Implementation Notes

- Queries must be known in advance (offline)
- Store original query indices to output answers in order
- Handle edge cases: empty ranges, single elements
- For tree queries, flatten with Euler tour first
- Consider the "alternating sort" optimization for speed
