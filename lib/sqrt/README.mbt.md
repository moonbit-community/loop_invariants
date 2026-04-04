# Sqrt Decomposition

Sqrt decomposition is a family of techniques that partition work into blocks of
size approximately sqrt(n). Each data structure in this package answers range
queries in **O(sqrt(n))** time by combining precomputed block aggregates with
element-level scans at block boundaries.

## Overview of techniques

| Technique      | Query       | Update         | Space  |
|----------------|-------------|----------------|--------|
| SqrtSum        | O(sqrt(n))  | O(1) per point | O(n)   |
| SqrtMin        | O(sqrt(n))  | O(sqrt(n))     | O(n)   |
| Mo's algorithm | O((n+q)sqrt(n)) total | offline   | O(n+q) |
| IntervalTree   | O(k) expected | O(k) expected | O(n)   |

Where k is the number of live intervals (shrinks rapidly under range assign).

---

## 1. The sqrt decomposition idea

Split an array of n elements into blocks of size B = ceil(sqrt(n)).

```
Array:   [a0  a1  a2  a3 | a4  a5  a6  a7 | a8  a9  a10  a11]
Index:     0   1   2   3    4   5   6   7    8   9   10   11
          |<-- block 0 -->| |<-- block 1 -->| |<--  block 2  -->|

block_size = 4  (ceil(sqrt(12)) = 4)
block_sum  = [  6          ,   22          ,   21           ]
```

A range query over [l, r] breaks into three parts:

```
Case: l = 1, r = 10

 index:  0   1   2   3 | 4   5   6   7 | 8   9  10  11
              ^                             ^
              l=1                          r=10
              [partial ]  [full block ]  [partial]
               left end    block 1        right
               block 0                   block 2
```

- Left partial: scan arr[1..3] element by element  (at most B steps)
- Middle: read block_sum[1] in O(1)
- Right partial: scan arr[8..10] element by element  (at most B steps)

Total cost: O(B + n/B). Setting B = sqrt(n) minimizes this to O(sqrt(n)).

---

## 2. Why B = sqrt(n) is optimal

Let B be the block size.

```
partial scan at boundaries = O(B)
number of full blocks       = O(n / B)
total per query             = O(B + n/B)
```

Take the derivative with respect to B and set to zero:

```
d/dB [B + n/B] = 1 - n/B^2 = 0
=> B = sqrt(n)
```

At B = sqrt(n):

```
cost = O(sqrt(n) + n/sqrt(n)) = O(sqrt(n) + sqrt(n)) = O(sqrt(n))
```

---

## 3. SqrtSum: range sum with O(1) point update

### Data layout

```
arr:         [1  2  3  |  4  5  6  |  7  8  9]   n=9, B=3
block_sum:   [   6     |    15     |    24    ]
block index:     0           1           2
```

### Range query [l=1, r=7]

```
left_block  = 1 / 3 = 0
right_block = 7 / 3 = 2

Since left_block != right_block:

  Step 1 (left partial)   : arr[1] + arr[2] = 2 + 3 = 5
                            (from l=1 to end of block 0 at index 2)
  Step 2 (middle blocks)  : block_sum[1] = 15
                            (full block 1, indices 3..5)
  Step 3 (right partial)  : arr[6] + arr[7] = 7 + 8 = 15
                            (from start of block 2 at index 6 to r=7)

  Total = 5 + 15 + 15 = 35
```

### Point update: update(i=4, val=100)

```
Before: arr = [1, 2, 3, 4,   5, 6, 7, 8, 9]
              block_sum = [6, 15, 24]

diff = 100 - arr[4] = 100 - 5 = 95
arr[4] = 100
block_sum[4/3] = block_sum[1] += 95  =>  15 + 95 = 110

After:  arr = [1, 2, 3, 4, 100, 6, 7, 8, 9]
              block_sum = [6, 110, 24]
```

Only the block aggregate changes. Cost: O(1).

---

## 4. SqrtMin: range minimum with lazy range add

### Lazy propagation for range updates

Full blocks get a pending add value stored separately. Partial blocks are
flushed (the pending add is applied element-by-element) before modification.

```
arr:     [5  2  8  |  1  9  3  |  7  4  6]   n=9, B=3
block_min: [2       |  1       |  4      ]
pending:   [0       |  0       |  0      ]
```

After range_add(3, 5, 10):

```
 index:  0  1  2 | 3   4   5 | 6  7  8
                   ^           ^
                   l=3         r=5

Block 0: partial (not involved)
Block 1: range [3..5] covers the full block, so just pending[1] += 10
Block 2: partial (not involved)

Result:
arr:     [5  2  8  |  1   9   3  |  7  4  6]  (arr unchanged)
pending: [0        |  10         |  0      ]
block_min: [2      |  1          |  4      ]   (still stores raw min)
```

Point query at index 4: arr[4] + pending[4/3] = 9 + 10 = 19.

For a range minimum query, the effective block minimum is block_min[b] + pending[b].

### State diagram for range_add

```
                     range_add(l, r, val)
                           |
          +----------------+----------------+
          |                                 |
    partial block                      full block
   (l or r splits it)              (entirely inside [l,r])
          |                                 |
   push_block(b)                   pending[b] += val
   apply to elements
   recompute_block(b)
```

---

## 5. Mo's algorithm: offline range queries in O((n+q)sqrt(n))

Mo's algorithm reorders a set of q offline range queries to minimize total
pointer movement. It answers queries like "how many distinct values in [l, r]?"

### Sorting key

Assign each query (l, r) to block b = l / sqrt(n). Sort queries by:
1. Primary: block index b (ascending)
2. Secondary: r (ascending within each block)

### Pointer movement analysis

```
Right pointer (r):
  Within a block, r is sorted ascending -> moves at most n per block.
  There are sqrt(n) blocks.
  Total right movement: O(n * sqrt(n))

Left pointer (l):
  Within a block, l stays in [b*B, (b+1)*B) -> moves at most B = sqrt(n)
  per query.
  Total left movement: O(q * sqrt(n))

Grand total: O((n + q) * sqrt(n))
```

### Sliding window state

```
Initial window: [cur_l, cur_r] = empty (cur_l=0, cur_r=-1)
count[v] = number of occurrences of value v in current window
distinct  = number of v with count[v] > 0

To extend right (cur_r -> cur_r + 1):
  v = arr[cur_r + 1]
  if count[v] == 0: distinct += 1
  count[v] += 1

To shrink right (cur_r -> cur_r - 1):
  v = arr[cur_r]
  count[v] -= 1
  if count[v] == 0: distinct -= 1

(Symmetric logic for left pointer)
```

### Example

```
arr = [1, 2, 1, 3, 2, 1, 4, 1, 2]   n=9, B=3

Queries:  (0,2)  (0,4)  (0,8)  (3,6)  (5,8)

Block of l:
  (0,2) -> block 0
  (0,4) -> block 0
  (0,8) -> block 0
  (3,6) -> block 1
  (5,8) -> block 1

Sorted: (0,2) (0,4) (0,8) (3,6) (5,8)
         [b0]  [b0]  [b0]  [b1]  [b1]

Process (0,2): window = [1,2,1], distinct = 2
Process (0,4): extend r to 4, window = [1,2,1,3,2], distinct = 3
Process (0,8): extend r to 8, distinct = 4
Process (3,6): shrink l to 3, shrink r to 6, distinct = 4
Process (5,8): extend r to 8, shrink l to 5, distinct = 3

Results (by original index): [2, 3, 4, 4, 3]
```

---

## 6. Interval tree (Chtholly Tree / ODT)

The interval tree stores the array as a list of maximal contiguous intervals
that share the same value. Range assign collapses many intervals into one,
keeping the total number of intervals small under random or assign-heavy input.

### Internal representation

```
arr = [1, 1, 5, 5, 5, 5, 1, 1]  (after assign(2, 5, 5))

Intervals:
  [0, 1, v=1]
  [2, 5, v=5]
  [6, 7, v=1]
```

### split_at(pos)

Ensures that pos is the left endpoint of some interval. If pos lands in the
middle of an interval [l, r], split it:

```
Before: [l ........... r, v]
After:  [l ... pos-1, v] [pos ... r, v]
```

### assign(l, r, v) in three steps

```
Step 1: split_at(r + 1)   <- do this first to avoid index drift
Step 2: split_at(l)       <- left_idx = index of interval starting at l
Step 3: remove all intervals in [left_idx .. right_idx]
        insert one interval [l, r, v]
```

```
Before assign(2, 5, 5):
  [0,1,v=1]  [2,2,v=3]  [3,4,v=7]  [5,6,v=2]  [7,7,v=9]
                ^                        ^
              split at 2             split at 6

After splits:
  [0,1,v=1]  [2,2,v=3]  [3,4,v=7]  [5,5,v=2]  [6,6,v=2]  [7,7,v=9]

Remove [2,2], [3,4], [5,5], insert [2,5,v=5]:
  [0,1,v=1]  [2,5,v=5]  [6,6,v=2]  [7,7,v=9]
```

### Complexity note

Under random operations, each assign merges O(n/q) intervals on average,
so the total interval count stays low. For adversarial input without assign
operations, the tree degrades to O(n) intervals.

---

## 7. isqrt_ceil: integer square root (ceiling)

Computes ceil(sqrt(n)) using Newton's method. The block size for all structures
above is chosen as isqrt_ceil(n).

```
Newton step: x_{k+1} = (x_k + n / x_k) / 2

Convergence for n=12:
  x0 = 12
  x1 = (12 + 12/12) / 2 = (12 + 1) / 2 = 6
  x2 = (6  + 12/6)  / 2 = (6  + 2) / 2 = 4
  x3 = (4  + 12/4)  / 2 = (4  + 3) / 2 = 3
  x4 = (3  + 12/3)  / 2 = (3  + 4) / 2 = 3  <- stable (floor = 3)

  3^2 = 9 < 12, so ceil = 4.  isqrt_ceil(12) = 4
```

---

## 8. Pseudocode for range sum query

```mbt nocheck
///|
fn range_sum(l : Int, r : Int) -> Int {
  for l = l, sum = 0 {
    if l > r {
      break sum
    } else if l % block_size != 0 {
      continue l + 1, sum + arr[l]
    } else if l + block_size - 1 <= r {
      continue l + block_size, sum + block_sum[l / block_size]
    } else {
      continue l + 1, sum + arr[l]
    }
  }
}
```

---

## 9. Example usage (conceptual)

This package is tutorial-oriented; all types are private.

```mbt nocheck
///|
let sd = SqrtSum::build([3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8])
sd.range_sum(2, 9)   // 35
sd.update(5, 0)
sd.range_sum(2, 9)   // 26
```

---

## 10. Complexity summary

```
Structure        Build       Query           Update          Space
-----------      --------    -----------     -----------     -----
SqrtSum          O(n)        O(sqrt(n))      O(1) point      O(n)
SqrtMin          O(n)        O(sqrt(n))      O(sqrt(n))      O(n)
Mo's algorithm   O(q log q)  O((n+q)sqrt(n)) offline only    O(n+q)
IntervalTree     O(n)        O(k)            O(k) expected   O(k)
```

---

## 11. Comparison with segment tree

```
Feature              Sqrt decomp     Segment tree
-----------          ----------      ------------
Implementation       Simple          Moderate
Query time           O(sqrt(n))      O(log n)
Update time          O(1) to O(sqrt(n))  O(log n)
Lazy range update    Straightforward  Requires careful design
Constant factor      Very small      Larger
Best for             Simple problems  Competitive programming
```

Sqrt decomposition is preferred when:
- O(sqrt(n)) is fast enough (n <= 10^5, queries <= 10^5 gives ~10^7 ops)
- The problem changes aggregate type (sum, min, max, XOR) and you want a
  quick prototype
- You need range assign, where the Chtholly Tree is simpler than lazy segtree

---

## 12. Beginner checklist

1. Choose block size B = ceil(sqrt(n)).
2. For sum: block aggregates are exact; point updates cost O(1).
3. For min/max: point updates require O(B) block recomputation.
4. For range updates: full blocks get a lazy tag; partial blocks are flushed.
5. For offline distinct queries: use Mo's algorithm.
6. For range assign problems: use the Chtholly Tree (IntervalTree).
