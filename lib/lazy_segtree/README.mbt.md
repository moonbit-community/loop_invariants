# Lazy Segment Tree (Range Update + Range Query)

## What It Solves

A **lazy segment tree** supports **range updates** and **range queries** on an
array in **O(log n)** time. It is the standard data structure for problems like:

- Add `x` to all values in a range
- Set all values in a range
- Query sum/min/max over a range

A normal segment tree would require O(n) for range updates; lazy propagation
avoids that by deferring work.

## Indexing Convention (Important)

This implementation uses **inclusive indices**:

```
range_add(l, r, val)  updates l..r (inclusive)
range_sum(l, r)       queries l..r (inclusive)
```

So `[l, r]` is closed, not half‑open.

## Core Idea in One Picture

When a segment is fully covered by an update, store the update at that node and
**do not** immediately touch its children.

```
Update: add +5 to [0, 3]

          [0..7]
            |
          [0..3]  <-- fully covered
            |
        lazy += 5

Children of [0..3] are not updated yet.
When a query descends into them, we push the lazy value down.
```

## Why It Works

Every node represents a segment `[L..R]` and stores an aggregate (here: sum).
If we add `x` to the entire segment:

```
sum += x * (R - L + 1)
```

So we can update the node **without** touching leaves. The lazy tag remembers
what to push to children later.

## Build and Query Structure

Example array: `[1, 2, 3, 4]`

```
          [0..3] sum=10
         /               \
   [0..1] sum=3       [2..3] sum=7
   /     \            /     \
[0]1    [1]2        [2]3    [3]4
```

## Step‑by‑Step Update Example

Operation: `range_add(0, 2, +5)`

```
Step 1: Visit [0..3] (partial overlap)
        -> push_down (nothing pending)

Step 2: Visit [0..1] (fully covered)
        sum += 5 * 2 = 10 => sum becomes 13
        lazy += 5

Step 3: Visit [2..3] (partial)
        -> visit [2] (fully covered)
           sum += 5 * 1 => 3 -> 8, lazy += 5
        -> visit [3] (no overlap)

Step 4: Recompute parents
```

Resulting sums:

```
          [0..3] sum=25
         /               \
   [0..1] sum=13      [2..3] sum=12
   lazy=5                lazy=0
```

The children of `[0..1]` still look unchanged, but the lazy tag stores the
pending update.

## Push Down (Lazy Propagation)

Before we go deeper from a node, we apply its pending update to its children:

```
if lazy[node] != 0:
  tree[left]  += lazy * size(left)
  tree[right] += lazy * size(right)
  lazy[left]  += lazy
  lazy[right] += lazy
  lazy[node] = 0
```

This makes sure children are correct whenever you need to read them.

## Example Usage

```mbt check
///|
test "lazy segtree example" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L]
  let st = @lazy_segtree.LazySegTreeSum::new(arr)

  // add 2 to indices 1..3
  st.range_add(1, 3, 2L)
  inspect(st.range_sum(0, 3), content="Some(16)")
  inspect(st.point_query(2), content="Some(5)")
}
```

```mbt check
///|
test "lazy segtree multiple updates" {
  let st = @lazy_segtree.LazySegTreeSum::new([5L, 1L, 4L, 2L, 3L])

  // add +3 to [0..2]
  st.range_add(0, 2, 3L)
  // add +1 to [2..4]
  st.range_add(2, 4, 1L)

  // array becomes [8, 4, 8, 3, 4]
  inspect(st.range_sum(0, 4), content="Some(27)")
  inspect(st.point_query(3), content="Some(3)")
}
```

## What This Package Implements

This package exposes a **range‑add / range‑sum** lazy segment tree:

- `LazySegTreeSum::new(arr)`
- `range_add(l, r, val)`
- `range_sum(l, r) -> Int64?`
- `point_query(i)`
- `point_set(i, val)`
- `length()`

Internally, it also has a range‑assign variant (private).

## Types of Lazy Tags (Conceptual)

### Range Add (this package)

```
lazy = pending addition
sum  = sum + lazy * size
compose: lazy = lazy + new_add
```

### Range Assign (conceptual)

```
lazy = pending assignment
sum  = lazy * size
compose: new assignment overrides old
```

### Range Multiply + Add (conceptual)

```
(x -> x*m + b)
compose: (m1, b1) then (m2, b2)
        = (m1*m2, b1*m2 + b2)
```

## Common Pitfalls

- **Inclusive ranges**: `[l, r]` not `[l, r)`.
- **Forgetting push_down**: children become stale.
- **Overflow**: sum uses `Int64`; guard large updates.
- **Empty tree**: this implementation returns `None` for queries.
- **Recomputing parent**: always update after recursing to children.

## Complexity

| Operation | Time | Space |
|----------|------|-------|
| Build | O(n) | O(n) |
| Range add | O(log n) | O(n) |
| Range sum | O(log n) | O(n) |
| Point query | O(log n) | O(n) |

## When to Use Lazy Segment Tree

Use it when you need **range updates** plus **range queries** on the same array.
If you only need prefix sums, a Fenwick tree is simpler.

## Visual Summary

```
Lazy segment tree = segment tree + delayed updates

Update range:
  fully covered node -> update node sum + store lazy
  partial overlap    -> push_down + recurse

Query range:
  fully covered node -> return sum
  partial overlap    -> push_down + combine children
```
