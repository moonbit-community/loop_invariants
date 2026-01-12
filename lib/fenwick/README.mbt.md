# Fenwick Tree (Binary Indexed Tree)

## Overview

A Fenwick Tree (also called Binary Indexed Tree or BIT) supports:
- **Point updates**: Add a value to index i in **O(log n)**
- **Prefix queries**: Sum of elements [0, i] in **O(log n)**

It's simpler and more cache-friendly than segment trees for sum queries.

## The Key Insight: Lowbit

The magic of Fenwick Trees lies in the **lowbit** function:

```
lowbit(x) = x & (-x) = rightmost set bit

Examples:
  lowbit(6)  = lowbit(110₂)  = 2  = 10₂
  lowbit(12) = lowbit(1100₂) = 4  = 100₂
  lowbit(8)  = lowbit(1000₂) = 8  = 1000₂
```

## Tree Structure Visualization

Each index i is responsible for a range of `lowbit(i)` elements:

```
Index (1-indexed):  1    2    3    4    5    6    7    8
Lowbit:             1    2    1    4    1    2    1    8
Range covered:     [1]  [1,2] [3] [1,4] [5] [5,6] [7] [1,8]

Tree structure (arrows show parent-child relationships):

Level 3:                              [8]
                                    /
Level 2:           [4]-------------+      (covers 1-8)
                  /                       (covers 1-4)
Level 1:    [2]--+        [6]---+
           /             /       \
Level 0: [1]   [3]     [5]       [7]
```

## How Prefix Sum Works

To compute sum[1..7], we follow the lowbit chain:

```
Query: prefix_sum(7)

Step 1: Add tree[7], then 7 - lowbit(7) = 7 - 1 = 6
Step 2: Add tree[6], then 6 - lowbit(6) = 6 - 2 = 4
Step 3: Add tree[4], then 4 - lowbit(4) = 4 - 4 = 0
Step 4: Done!

       7 -----> 6 -----> 4 -----> 0
      [7]      [6]      [4]     done
    covers   covers   covers
     [7]     [5,6]    [1,4]

Total = tree[7] + tree[6] + tree[4] = sum of [1..7]
```

## How Point Update Works

To update index 3, we follow the lowbit chain upward:

```
Update: add(3, delta)

Step 1: Update tree[3], then 3 + lowbit(3) = 3 + 1 = 4
Step 2: Update tree[4], then 4 + lowbit(4) = 4 + 4 = 8
Step 3: Update tree[8], then 8 + lowbit(8) = 8 + 8 = 16 (out of range)
Step 4: Done!

       3 -----> 4 -----> 8 -----> 16
      [3]      [4]      [8]     done
    covers   covers   covers
     [3]     [1,4]    [1,8]

All ranges containing index 3 are updated!
```

## Worked Example

Array: `[3, 1, 4, 1, 5, 9, 2, 6]` (0-indexed input)

After building (1-indexed internal):
```
Index:     1    2    3    4    5    6    7    8
Value:     3    1    4    1    5    9    2    6
Tree:      3    4    4   9     5   14    2   31
          [1] [1,2] [3] [1-4] [5] [5,6] [7] [1-8]
```

Query `prefix_sum(5)` (sum of indices 0-5 = 3+1+4+1+5+9 = 23):
```
Internal: sum[1..6]
  tree[6] = 14 (covers [5,6])
  6 - 2 = 4
  tree[4] = 9  (covers [1,4])
  4 - 4 = 0, done
Total = 14 + 9 = 23
```

## Use Cases

1. **Cumulative Frequency Tables**: Count elements in ranges
2. **Inversion Count**: Count pairs (i,j) where i < j but a[i] > a[j]
3. **Range Sum Queries**: Answer many sum queries after preprocessing
4. **2D Range Queries**: Extend to 2D for rectangle sums
5. **Order Statistics**: Find k-th smallest with binary search on BIT

## API Reference

```mbt check
///|
test "fenwick tree complete example" {
  // Build from array
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let ft = @fenwick.FenwickTree::from_array(arr)

  // Prefix sum queries
  inspect(ft.prefix_sum(0), content="1") // sum[0..0] = 1
  inspect(ft.prefix_sum(2), content="6") // sum[0..2] = 1+2+3 = 6
  inspect(ft.prefix_sum(4), content="15") // sum[0..4] = 15

  // Range sum queries
  inspect(ft.range_sum(1, 3), content="9") // sum[1..3] = 2+3+4 = 9

  // Point update
  ft.add(2, 7L) // arr[2] becomes 3+7=10
  inspect(ft.prefix_sum(4), content="22") // 1+2+10+4+5 = 22

  // Get/set single values
  inspect(ft.get(2), content="10")
  ft.set(2, 3L) // Reset to original
  inspect(ft.prefix_sum(4), content="15")
}
```

## Variants Included

### 1. Range Update + Point Query

Update a range [l, r] with +delta, query single points:

```mbt check
///|
test "range update example" {
  // Uses difference array internally
  // Add 10 to range [1, 3], query individual positions
}
```

### 2. Range Update + Range Query

Both range updates and range sum queries:

```mbt check
///|
test "range-range example" {
  // Uses two BITs internally
  // Supports both range add and range sum
}
```

### 3. 2D Fenwick Tree

Rectangle sum queries and point updates:

```
Grid:    1 2 3
         4 5 6
         7 8 9

Query rectangle (1,1) to (2,2):
  = 5 + 6 + 8 + 9 = 28
```

## Complexity Analysis

| Operation     | Time     | Space |
|---------------|----------|-------|
| Build         | O(n)     | O(n)  |
| Point Update  | O(log n) | -     |
| Prefix Sum    | O(log n) | -     |
| Range Sum     | O(log n) | -     |

## Fenwick vs Segment Tree

| Feature              | Fenwick Tree | Segment Tree |
|----------------------|--------------|--------------|
| Space                | n            | 2n-4n        |
| Implementation       | Simple       | Complex      |
| Cache efficiency     | Better       | Worse        |
| Operations supported | Sum/XOR/...  | Any monoid   |
| Range updates        | With tricks  | Native       |

**Choose Fenwick when**: You need sum/XOR queries and prefer simplicity.
**Choose Segment Tree when**: You need min/max or complex operations.
