# Fenwick Tree (Binary Indexed Tree)

## Overview

A Fenwick Tree (also called Binary Indexed Tree or BIT) supports:
- **Point updates**: add a value to index `i` in **O(log n)**
- **Prefix queries**: sum of elements `[0, i]` in **O(log n)**
- **Range queries**: sum of elements `[l, r]` in **O(log n)**

It is simpler and more cache-friendly than a segment tree for sum queries.

## Indexing Convention

The public API is **0-indexed** (`0..n-1`), but the internal storage is
**1-indexed** (`1..n`). Every public method adds 1 when entering and subtracts
1 when leaving.

```
External (you use):   0  1  2  3  4  5  6  7
Internal (tree uses): 1  2  3  4  5  6  7  8
```

## The Lowbit Primitive

The single operation that makes Fenwick Trees work is **lowbit**:

```
lowbit(x) = x & (-x)   // isolate the rightmost set bit

Binary walkthrough:
  x     =  0 1 1 0  (6 in decimal)
 -x     =  1 0 1 0  (two's complement of 6)
  x & -x = 0 0 1 0  (result = 2)

More examples:
  x    binary    lowbit
  1    0001      1      (0001)
  2    0010      2      (0010)
  3    0011      1      (0001)
  4    0100      4      (0100)
  5    0101      1      (0001)
  6    0110      2      (0010)
  7    0111      1      (0001)
  8    1000      8      (1000)
```

Each tree node at 1-indexed position `i` is responsible for exactly
`lowbit(i)` consecutive elements ending at `i`.

## Tree Structure

For an 8-element array (1-indexed), the coverage of each tree node is:

```
Index:     1    2    3    4    5    6    7    8
Lowbit:    1    2    1    4    1    2    1    8
Covers:   [1]  [1,2] [3] [1,4] [5] [5,6] [7] [1,8]

Parent-child relationships (child -> parent via i + lowbit(i)):

         8 [1..8]
         |
         4 [1..4] --------- 6 [5..6]
         |                  |
    2 [1..2]   3 [3]   5 [5]   7 [7]
    |
1 [1]

Reading bottom-up: leaf nodes cover single elements; each parent covers
the union of its children's ranges plus its own element.
```

Another way to see the structure - annotated with range widths:

```
Level 0 (width 1):  [1]       [3]       [5]       [7]
Level 1 (width 2):       [2]                 [6]
Level 2 (width 4):             [4]
Level 3 (width 8):                   [8]
```

## How Prefix Sum Works

To compute `prefix_sum(7)` (sum of elements 1 through 7 in 1-indexed terms),
repeatedly subtract `lowbit` until reaching 0:

```
Start at index 7.

Step 1:  idx = 7 (binary 0111)
         add tree[7]  (covers element 7)
         7 - lowbit(7) = 7 - 1 = 6

Step 2:  idx = 6 (binary 0110)
         add tree[6]  (covers elements 5-6)
         6 - lowbit(6) = 6 - 2 = 4

Step 3:  idx = 4 (binary 0100)
         add tree[4]  (covers elements 1-4)
         4 - lowbit(4) = 4 - 4 = 0

Step 4:  idx = 0  -> stop

Path:  7 -> 6 -> 4 -> 0
       |    |    |
      [7] [5,6] [1,4]   <- disjoint ranges that partition [1,7]

Result = tree[7] + tree[6] + tree[4]
```

The key property: the ranges are always **disjoint** and together cover
exactly `[1, i]`.  The number of steps is at most the number of set bits
in `i`, which is at most `log2(n)`.

## How Point Update Works

To update index 3 (1-indexed), repeatedly add `lowbit` to climb to every
ancestor node whose range contains index 3:

```
Start at index 3.

Step 1:  idx = 3 (binary 011)
         update tree[3]  (covers element 3)
         3 + lowbit(3) = 3 + 1 = 4

Step 2:  idx = 4 (binary 100)
         update tree[4]  (covers elements 1-4, includes 3)
         4 + lowbit(4) = 4 + 4 = 8

Step 3:  idx = 8 (binary 1000)
         update tree[8]  (covers elements 1-8, includes 3)
         8 + lowbit(8) = 8 + 8 = 16  > n=8  -> stop

Path:  3 -> 4 -> 8 -> (16, stop)
       |    |    |
      [3] [1,4] [1,8]   <- all ranges that contain index 3

Every ancestor that "covers" position 3 is updated, nothing else.
```

## Bit-Level Walkthrough: How the Paths Work

Query path from `i` (subtract lowbit, clears the rightmost 1 bit each time):
```
7 = 0111  ->  clear bit 0  ->  6 = 0110
6 = 0110  ->  clear bit 1  ->  4 = 0100
4 = 0100  ->  clear bit 2  ->  0 = 0000  (stop)
```

Update path from `i` (add lowbit, increments the position of the rightmost 1):
```
3 = 011  ->  set next bit  ->  4 = 100
4 = 100  ->  set next bit  ->  8 = 1000
8 = 1000 ->  set next bit  -> 16       (out of range, stop)
```

## Range Sum via Two Prefix Sums

```
range_sum(l, r) = prefix_sum(r) - prefix_sum(l - 1)

Example with arr = [3, 1, 4, 1, 5, 9] (0-indexed):
  prefix_sum(5) = 3+1+4+1+5+9 = 23
  prefix_sum(1) = 3+1         = 4
  range_sum(2, 5) = 23 - 4 = 19   (4+1+5+9 = 19, correct)
```

## Worked Example: Build and Query

Array (0-indexed input): `[3, 1, 4, 1, 5, 9, 2, 6]`

Internal tree (1-indexed) after `from_array`:
```
Index:    1    2    3    4    5    6    7    8
Value:    3    1    4    1    5    9    2    6
                 (raw array values copied in)

After O(n) build propagation:
Index:    1    2    3    4    5    6    7    8
Tree:     3    4    4    9    5   14    2   31
Covers:  [1]  [1,2] [3] [1,4] [5] [5,6] [7] [1,8]
```

Verify `prefix_sum(5)` (0-indexed 5 = 1-indexed 6, sum = 3+1+4+1+5+9 = 23):
```
idx=6: add tree[6]=14  (covers [5,6] = values 5 and 9)
       6 - lowbit(6) = 4
idx=4: add tree[4]=9   (covers [1,4] = values 3,1,4,1)
       4 - lowbit(4) = 0  -> stop
Total = 14 + 9 = 23  (correct)
```

## Building in O(n) vs O(n log n)

```
Naive build: call add(i, arr[i]) for each i  ->  O(n log n)

O(n) build using propagation:
  1. Copy arr into tree (1-indexed).
  2. For each i from 1 to n:
       parent = i + lowbit(i)
       if parent <= n: tree[parent] += tree[i]

Why O(n): parent > i always, so each node is visited exactly once.
Each element's value bubbles up the tree in a single pass.
```

## API Reference

```mbt check
///|
test "fenwick tree complete example" {
  // Build from array
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let ft = @fenwick.FenwickTree::from_array(arr)

  // Prefix sum queries
  debug_inspect(ft.prefix_sum(0), content="1") // sum[0..0] = 1
  debug_inspect(ft.prefix_sum(2), content="6") // sum[0..2] = 1+2+3 = 6
  debug_inspect(ft.prefix_sum(4), content="15") // sum[0..4] = 15

  // Range sum queries
  debug_inspect(ft.range_sum(1, 3), content="9") // sum[1..3] = 2+3+4 = 9

  // Point update
  ft.add(2, 7L) // arr[2] becomes 3+7=10
  debug_inspect(ft.prefix_sum(4), content="22") // 1+2+10+4+5 = 22

  // Get/set single values
  debug_inspect(ft.get(2), content="10")
  ft.set(2, 3L) // Reset to original
  debug_inspect(ft.prefix_sum(4), content="15")
}
```

## Variants

### Variant 1: Range Update + Point Query

Uses a **difference array** stored in a Fenwick Tree.  Adding `delta` to
`[l, r]` becomes two point adds; reading a single element becomes a prefix sum.

```
Encoding: diff[l] += delta,  diff[r+1] -= delta

Before any updates, all elements are 0.

After range_add(1, 3, 10):
  Difference array: [0, +10, 0, 0, -10, 0] (conceptually)

  query(0) = prefix_sum(diff, 0) = 0
  query(1) = prefix_sum(diff, 1) = 10
  query(2) = prefix_sum(diff, 2) = 10
  query(3) = prefix_sum(diff, 3) = 10
  query(4) = prefix_sum(diff, 4) = 10 + (-10) = 0
```

| Operation      | Time     |
|----------------|----------|
| range_add(l,r) | O(log n) |
| query(i)       | O(log n) |

### Variant 2: Range Update + Range Query

Uses **two Fenwick Trees** (`bit1` and `bit2`) to convert range updates into
prefix sum queries.

The math: let `b(k)` be a difference array.  Then:
```
prefix_sum(i) = (i+1) * BIT1.query(i) - BIT2.query(i)

where BIT1 stores b(k) and BIT2 stores b(k)*(k-1).

Example:
  range_add(0, 4, 1)  ->  all elements become 1
  range_sum(0, 4) = 5

  range_add(1, 3, 2)  ->  array is now [1, 3, 3, 3, 1]
  range_sum(0, 4) = 11
  range_sum(1, 3) = 9
```

| Operation        | Time     |
|------------------|----------|
| range_add(l,r)   | O(log n) |
| range_sum(l,r)   | O(log n) |

### Variant 3: 2D Fenwick Tree

Extends the 1D idea to a grid: node `(i, j)` covers a sub-rectangle of size
`lowbit(i) x lowbit(j)`.  Updates and queries walk both the row and column
lowbit chains.

```
Grid values (0-indexed):
  col:  0  1  2
row 0:  1  2  3
row 1:  4  5  6
row 2:  7  8  9

prefix_sum(1, 1) covers rows 0..1, cols 0..1:
  1 + 2 + 4 + 5 = 12

range_sum(1, 1, 2, 2) covers rows 1..2, cols 1..2:
  5 + 6 + 8 + 9 = 28

Inclusion-exclusion formula:
  range_sum(r1,c1,r2,c2)
    = prefix(r2,c2) - prefix(r1-1,c2)
                    - prefix(r2,c1-1)
                    + prefix(r1-1,c1-1)
```

| Operation           | Time                    |
|---------------------|-------------------------|
| add(r,c,delta)      | O(log rows * log cols)  |
| prefix_sum(r,c)     | O(log rows * log cols)  |
| range_sum(r1,c1,..) | O(log rows * log cols)  |

## Complexity Summary

| Operation         | 1D Time  | 2D Time                | Space |
|-------------------|----------|------------------------|-------|
| Build             | O(n)     | O(rows*cols)           | O(n)  |
| Point update      | O(log n) | O(log r * log c)       | -     |
| Prefix sum        | O(log n) | O(log r * log c)       | -     |
| Range sum         | O(log n) | O(log r * log c)       | -     |
| Range add         | O(log n) | -                      | -     |

## Common Pitfalls

- **Off-by-one**: internal indices are 1-based; the public API is 0-based.
  Always add 1 entering and subtract 1 leaving.
- **Negative indices**: `prefix_sum(-1)` returns 0 by convention.
- **Overflow**: use `Int64` when sums can exceed the `Int` range.
- **Range formula**: `range_sum(l, r) = prefix_sum(r) - prefix_sum(l-1)`,
  not `prefix_sum(r) - prefix_sum(l)`.
- **2D inclusion-exclusion sign**: add the corner term `prefix(r1-1, c1-1)`
  back (it is subtracted twice).

## Fenwick Tree vs Segment Tree

| Feature               | Fenwick Tree  | Segment Tree  |
|-----------------------|---------------|---------------|
| Space                 | O(n)          | O(2n) - O(4n) |
| Implementation        | ~20 lines     | ~60 lines     |
| Cache efficiency      | Better        | Worse         |
| Supported operations  | Sum, XOR, ... | Any monoid    |
| Native range updates  | No (tricks)   | Yes           |
| Min / Max queries     | No            | Yes           |

**Choose Fenwick** when you need sum or XOR queries and prefer simplicity.  
**Choose Segment Tree** when you need min/max, lazy propagation, or complex
interval operations.
