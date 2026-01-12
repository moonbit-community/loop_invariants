# Segment Tree

## Overview

A **Segment Tree** is a binary tree for efficient:
- **Range queries**: Get aggregate (sum, min, max) of range [l, r] in **O(log n)**
- **Point updates**: Update element at index i in **O(log n)**

Unlike Fenwick Trees, Segment Trees support any associative operation (min, max, GCD, etc.).

## Tree Structure

For array `[1, 2, 3, 4, 5]`:

```
                    [0-4]=15
                   /        \
              [0-2]=6      [3-4]=9
             /      \       /    \
         [0-1]=3  [2]=3  [3]=4  [4]=5
         /     \
      [0]=1  [1]=2

Each node stores the SUM of its range.
```

## How Range Query Works

Query sum of range [1, 3]:

```
                    [0-4]=15
                   /        \
              [0-2]=6      [3-4]=9
             /      \       /    \
         [0-1]=3  [2]=3  [3]=4  [4]=5
         /     \
      [0]=1  [1]=2

Step 1: At root [0-4], range [1,3] overlaps both children
        -> Go left to [0-2] and right to [3-4]

Step 2: At [0-2], range [1,3] partially overlaps
        -> [0-1]: only [1] overlaps -> Go to [1]=2
        -> [2]: fully inside [1,3] -> Return 3

Step 3: At [3-4], range [1,3] partially overlaps
        -> [3]: fully inside [1,3] -> Return 4
        -> [4]: outside [1,3] -> Return 0

Result: 2 + 3 + 4 = 9
```

## How Point Update Works

Update index 2 to value 10:

```
Before:                 After:
    [0-4]=15               [0-4]=22
   /        \             /        \
[0-2]=6  [3-4]=9     [0-2]=13   [3-4]=9
   \                     \
  [2]=3               [2]=10

Path: root -> [0-2] -> [2]
Updates propagate back up the tree.
```

## Use Cases

### 1. Range Sum Queries
Find sum of elements in any range:

```mbt check
///|
test "range sum queries" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = @segment_tree.SegmentTree::new(arr)
  inspect(st.query(0, 4), content="15") // 1+2+3+4+5
  inspect(st.query(1, 3), content="9") // 2+3+4
  inspect(st.query(2, 2), content="3") // just element 2
}
```

### 2. Dynamic Updates
Update elements and query efficiently:

```mbt check
///|
test "dynamic updates" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L]
  let st = @segment_tree.SegmentTree::new(arr)
  inspect(st.query(0, 3), content="10")
  st.update(2, 10L) // Change arr[2] from 3 to 10
  inspect(st.query(0, 3), content="17") // 1+2+10+4
  inspect(st.query(2, 3), content="14") // 10+4
}
```

### 3. Range Minimum/Maximum

The module includes min/max variants:

```
For array [3, 1, 4, 1, 5]:

Min Tree:               Max Tree:
    [0-4]=1                [0-4]=5
   /       \              /       \
[0-2]=1  [3-4]=1     [0-2]=4   [3-4]=5
```

## Common Applications

1. **Range Statistics**: Sum, min, max, GCD of ranges
2. **Computational Geometry**: Counting points in rectangles
3. **Database Indexing**: Range queries on sorted data
4. **Graphics**: Bounding box queries
5. **Competitive Programming**: Classic data structure problem

## Complexity Analysis

| Operation     | Time     | Space |
|---------------|----------|-------|
| Build         | O(n)     | O(n)  |
| Point Update  | O(log n) | -     |
| Range Query   | O(log n) | -     |
| Range Update* | O(log n) | -     |

*With lazy propagation

## Segment Tree vs Fenwick Tree

| Feature           | Segment Tree | Fenwick Tree |
|-------------------|--------------|--------------|
| Space             | 4n           | n            |
| Operations        | Any monoid   | Sum/XOR only |
| Implementation    | More complex | Simple       |
| Range updates     | Native       | With tricks  |
| Constants         | Larger       | Smaller      |

**Choose Segment Tree when**: You need min/max or other non-invertible operations.
**Choose Fenwick Tree when**: You only need sum/XOR and want simplicity.

## Variants Available

### 1. Lazy Propagation
For range updates (add value to all elements in [l, r]):

```
Without lazy: O(n) per range update
With lazy:    O(log n) per range update

Key idea: Defer updates until needed ("lazy" propagation)
```

### 2. 2D Segment Tree
For 2D range queries:

```
Query rectangle (x1,y1) to (x2,y2):
  - Outer tree over x-coordinates
  - Each node contains inner tree over y-coordinates
```

## Building Intuition

Think of a segment tree as a **tournament bracket**:

```
Array:     [5] [3] [7] [2]
           ╲ ╱   ╲ ╱
Round 1:   [8]   [9]     <- combine children
            ╲   ╱
Final:      [17]         <- root has total
```

For minimum queries, imagine a tournament where the winner (minimum) advances:

```
Array:     [5] [3] [7] [2]
           ╲ ╱   ╲ ╱
Round 1:   [3]   [2]     <- min of each pair
            ╲   ╱
Final:      [2]          <- overall minimum
```

## Implementation Notes

- Tree size is typically 4n for safety (can be 2n with careful indexing)
- Node numbering: root=1, left child=2i, right child=2i+1
- Each node stores aggregate of its range [start, end]
