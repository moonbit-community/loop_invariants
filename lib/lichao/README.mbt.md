# Li Chao Tree (Line Container)

## What It Solves

A **Li Chao Tree** maintains a set of lines

```
 y = m x + b
```

and answers queries:

```
What is the minimum (or maximum) y at x = k?
```

It supports **arbitrary insert order** and **arbitrary query order** in
**O(log C)** time, where `C` is the x‑coordinate range.

## Why Not Just Check All Lines?

If you have `n` lines and `q` queries, the naive solution is O(n) per query.
Li Chao brings it down to O(log C) per query.

Example:

```
Lines: y = 2x + 1, y = -x + 5, y = 0.5x + 2

x = 1: values = 3, 4, 2.5  => min = 2.5
x = 4: values = 9, 1, 4    => min = 1
```

## Core Insight (Winner vs Loser)

For an interval `[l, r]`, compare two lines at the midpoint `m`:

- The **winner** is better at `m` and stays in this node.
- The **loser** might still win on **one side** and is pushed there.

Why only one side?

```
If line A is better at mid, and line B is better at left endpoint,
then B can only win on the left half. It cannot win on both halves
because A dominates at the mid.
```

## Visual: Two Lines on an Interval

```
Line A (dashed), Line B (solid)

 y
 4 |  A
 3 |   \       B
 2 |    \     /
 1 |     \   /
 0 |------\-/-------- x
      0    2    4

A wins at mid=2, B wins at left end, so B is pushed to the left child.
```

## Insert Algorithm (High Level)

```
insert(line, node [l, r]):
  mid = (l + r) / 2

  if node has no line:
      node.line = line; return

  if line better at mid:
      swap(line, node.line)

  if l == r: return

  if line better at l:
      insert(line, left child)
  else:
      insert(line, right child)
```

## Query Algorithm

To query at x:

```
Start at root:
  evaluate node.line at x
  move to child containing x
  take min/max along the path
```

The true answer is always on the root‑to‑leaf path for that x.

## Example Walkthrough

Range: `[0, 4]`
Lines:

```
A: y = -x + 4
B: y = x
```

Insert A (first line becomes root).
Insert B:

```
mid = 2
A(2) = 2
B(2) = 2 (tie)
keep A at root

compare at left endpoint:
A(0)=4, B(0)=0 -> B wins on left
push B to left child
```

Query x=1:

```
root: A(1)=3
left: B(1)=1
answer = 1
```

## API Examples

### Maximum queries

```mbt check
///|
test "lichao max" {
  let lc = @lichao.LiChaoTree::new(0, 10)
  lc.insert(2, 1) // y = 2x + 1
  lc.insert(-1, 5) // y = -x + 5
  inspect(lc.query(3), content="7") // max(7, 2)
}
```

### Minimum queries

```mbt check
///|
test "lichao min" {
  let lc = @lichao.LiChaoTreeMin::new(0, 10)
  lc.insert(2, 1) // y = 2x + 1
  lc.insert(-1, 5) // y = -x + 5
  inspect(lc.query(3), content="2") // min(7, 2)
}
```

## Common Applications

### 1) Convex Hull Trick (Dynamic)

```
DP form: dp[i] = min_j (a[j] * x[i] + b[j])
Insert line (a[j], b[j]), query at x[i].
```

### 2) Shortest Path with Linear Costs

```
Edge cost depends linearly on a state value x.
Li Chao picks cheapest line at that x.
```

### 3) Lower/Upper Envelope of Lines

```
Maintain minimum (or maximum) over all lines at any x.
```

## Handling Line Segments (Conceptual)

You can restrict a line to an interval `[L, R]`:

```
insert_segment(line, node interval):
  if no overlap: return
  if fully covered: insert(line)
  else recurse both children
```

This costs O(log^2 C) per segment.

## Complexity

| Operation | Time | Space |
|----------|------|-------|
| Insert | O(log C) | O(n log C) nodes created |
| Query | O(log C) | O(1) extra |

## Common Pitfalls

- **Coordinate range**: must cover all query x values.
- **Overflow**: line evaluation uses `Int64`.
- **Ties**: consistent tie handling keeps correctness.
- **Min vs max**: use the correct tree (`LiChaoTreeMin` for min).

## Li Chao vs Convex Hull Trick

| Feature | Li Chao | CHT (sorted slopes) |
|---------|---------|---------------------|
| Insert order | any | sorted by slope |
| Query order | any | often sorted |
| Complexity | O(log C) | O(log n) or amortized O(1) |
| Implementation | simpler | trickier |

Li Chao is usually the best choice when operations are online and order is
arbitrary.

## Implementation Notes (This Package)

- `LiChaoTree` answers **maximum** queries.
- `LiChaoTreeMin` answers **minimum** queries.
- Uses a dynamic node array (nodes created on demand).
- Sentinel lines represent “no line yet”.
