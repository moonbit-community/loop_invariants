# 2D Fenwick Tree (Binary Indexed Tree)

## Overview

The **2D Fenwick Tree** extends the 1D BIT to support efficient point updates
and 2D prefix/rectangle sum queries. It achieves O(log² n) per operation.

- **Update**: O(log n × log m)
- **Query**: O(log n × log m)
- **Space**: O(n × m)

## Indexing Note

```
This API uses 1-indexed coordinates:
  update(1,1,delta) modifies the top-left cell.
  prefix_sum(r,c) returns sum of rows 1..r and cols 1..c.

If your data is 0-indexed, convert by adding 1 to row/col.
```

## The Key Insight

```
Apply 1D Fenwick logic in both dimensions.
Each cell tree[i][j] stores a partial sum covering
a region determined by lowbit(i) and lowbit(j).

Update path: both i and j traverse upward via lowbit
Query path: both i and j traverse downward via lowbit
```

## 1D Fenwick Review

```
1D Fenwick: tree[i] covers range [i - lowbit(i) + 1, i]

Index:    1    2    3    4    5    6    7    8
lowbit:   1    2    1    4    1    2    1    8
Covers:  [1]  [1,2] [3] [1,4] [5] [5,6] [7] [1,8]

Query prefix sum: add tree[i], then i -= lowbit(i)
Update: add to tree[i], then i += lowbit(i)
```

## 2D Extension

```
tree[i][j] covers rectangle:
  rows [i - lowbit(i) + 1, i]
  cols [j - lowbit(j) + 1, j]

2D prefix sum(r, c):
  for i = r downto 1 (via lowbit):
    for j = c downto 1 (via lowbit):
      sum += tree[i][j]

2D update(r, c, delta):
  for i = r upto n (via lowbit):
    for j = c upto m (via lowbit):
      tree[i][j] += delta
```

## Algorithm Walkthrough

```
3×3 grid, update (2, 2) with value 5:

Initial:        After update (2,2):
0 0 0           0 0 0
0 0 0    →      0 5 5
0 0 0           0 5 5

tree[2][2] += 5  (covers [1-2][1-2])
tree[2][4] would be updated if m ≥ 4
tree[4][2] would be updated if n ≥ 4
tree[4][4] would be updated if n,m ≥ 4

Query prefix(2, 3) after update:
  Start i=2, j=3
  tree[2][3]: covers [1-2][3], but that's 0
  tree[2][2]: covers [1-2][1-2], has 5
  i=2, j=2: add tree[2][2] = 5
  j=0: inner loop done
  i=0: outer loop done
  Result: 5 ✓
```

## Visual: Update Pattern

```
Update cell (r, c) = (2, 2):

  j→  1   2   3   4
i↓
  1   ·   ·   ·   ·
  2   ·   ★   ★   ★     ★ = cells modified
  3   ·   ·   ·   ·
  4   ·   ★   ★   ★

Pattern: all (i', j') where i' and j' are
         reachable from (r, c) by adding lowbit
```

## Example Usage

```mbt check
///|
test "fenwick2d example" {
  let fw = @fenwick2d.Fenwick2D::new(3, 3)
  fw.update(1, 1, 5)
  fw.update(2, 3, 2)
  inspect(fw.range_sum(1, 1, 3, 3), content="7")
}
```

```mbt check
///|
test "fenwick2d prefix and single cell" {
  let fw = @fenwick2d.Fenwick2D::new(3, 3)
  fw.update(1, 1, 4)
  fw.update(1, 2, 1)
  fw.update(2, 1, 2)
  inspect(fw.prefix_sum(2, 2), content="7") // 4+1+2
  inspect(fw.get(1, 2), content="1")
}
```

## Rectangle Sum via Inclusion-Exclusion

```
Range sum for rectangle [r1, c1] to [r2, c2]:

sum = prefix(r2, c2)
    - prefix(r1-1, c2)
    - prefix(r2, c1-1)
    + prefix(r1-1, c1-1)

  c1    c2
  ↓     ↓
  +-----+-------+
  |  A  |   B   |   r1-1
  +-----+-------+ ←
  |     |       |
  |  C  | query |   r2
  |     |       |
  +-----+-------+ ←

prefix(r2,c2) = A + B + C + query
prefix(r1-1,c2) = A + B
prefix(r2,c1-1) = A + C
prefix(r1-1,c1-1) = A

query = (A+B+C+query) - (A+B) - (A+C) + A
      = prefix(r2,c2) - prefix(r1-1,c2) - prefix(r2,c1-1) + prefix(r1-1,c1-1)
```

### Numeric Example

```
Grid (1-indexed):
  1  2  3
  4  5  6
  7  8  9

Query rectangle (2,2) to (3,3):
  values = 5 + 6 + 8 + 9 = 28

Using inclusion-exclusion:
  prefix(3,3) = 45
  prefix(1,3) = 1 + 2 + 3 = 6
  prefix(3,1) = 1 + 4 + 7 = 12
  prefix(1,1) = 1

  45 - 6 - 12 + 1 = 28
```

## Common Applications

### 1. 2D Range Sum Queries
```
Given: Grid of values with point updates
Query: Sum of rectangle [r1,c1] to [r2,c2]
Time: O(log n × log m) per operation
```

### 2. Count Points in Rectangle
```
Each point contributes +1 at its position.
Query sum in rectangle = count of points.
```

### 3. 2D Frequency Counting
```
Count elements with value in [a,b] and position in [l,r].
Use coordinate compression + 2D BIT.
```

### 4. Online 2D Statistics
```
Maintain running statistics on a 2D grid
with efficient updates and queries.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| Build (from matrix) | O(nm log n log m) |
| Point update | O(log n × log m) |
| Prefix sum query | O(log n × log m) |
| Rectangle sum query | O(log n × log m) |

## 2D Fenwick vs 2D Segment Tree

| Feature | 2D Fenwick | 2D Segment Tree |
|---------|------------|-----------------|
| Update | O(log² n) | O(log² n) |
| Query | O(log² n) | O(log² n) |
| Space | O(nm) | O(4nm) or more |
| Code complexity | Simple | Complex |
| Operations | Sum only | Any associative |

**Choose 2D Fenwick when**: You need sum queries with simple code and good constant factors.

## Extension: Range Update, Point Query

```
To support range updates and point queries:
1. Store differences instead of values
2. Range update [r1,c1] to [r2,c2] with value v:
   - update(r1, c1, v)
   - update(r1, c2+1, -v)
   - update(r2+1, c1, -v)
   - update(r2+1, c2+1, v)
3. Point query(r, c) = prefix(r, c)
```

## Common Pitfalls

- **Off-by-one**: internal coordinates are 1-based.
- **Large grids**: memory is O(n×m); for sparse data, use coordinate compression.
- **Negative updates**: allowed, but keep sums in `Int64`.
- **Empty rectangles**: handle r1 > r2 or c1 > c2 as sum 0.

## Implementation Notes

- Use 1-indexed arrays for clean lowbit operations
- lowbit(x) = x & (-x)
- For range sum, handle r1=0 or c1=0 edge cases
- Can be generalized to higher dimensions (3D, etc.)
- Memory access pattern: column-major for inner loop often faster
