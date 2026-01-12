# Lazy Segment Tree

## Overview

A **Lazy Segment Tree** extends the regular segment tree to support efficient
range updates. Instead of updating every element in a range, it defers updates
using "lazy" propagation.

- **Range Update**: O(log n)
- **Range Query**: O(log n)
- **Space**: O(n)

## The Problem

```
Regular segment tree: O(n) for range update (must touch every element)
Lazy segment tree: O(log n) for range update!

Operation: Add 5 to all elements in range [2, 5]

Before: [1, 3, 2, 7, 4, 6, 1, 8]
After:  [1, 3, 7, 12, 9, 11, 1, 8]
              ↑   ↑   ↑   ↑
            +5  +5  +5  +5
```

## The Key Insight

```
Don't update nodes immediately. Store pending updates
and propagate them only when needed.

Range add [0, 3] with value 5:

           [0-7]           ← Don't update children yet!
          lazy=0
         /      \
      [0-3]    [4-7]
     lazy=5   lazy=0       ← Mark lazy=5, done!
     /    \
  [0-1]  [2-3]             ← Never touched

When querying [1, 2] later, push lazy value down.
```

## Lazy Propagation

```
Before query or update on a node, push lazy value to children:

push_down(node):
    if lazy[node] != 0:
        # Apply to left child
        sum[left] += lazy[node] * size[left]
        lazy[left] += lazy[node]

        # Apply to right child
        sum[right] += lazy[node] * size[right]
        lazy[right] += lazy[node]

        # Clear lazy
        lazy[node] = 0
```

## Algorithm Walkthrough

```
Array: [1, 2, 3, 4]  →  Initial tree:

         [0-3]
         sum=10
        /      \
     [0-1]    [2-3]
     sum=3    sum=7
     /   \    /   \
   [0]  [1] [2]  [3]
   s=1  s=2 s=3  s=4

Operation: range_add(0, 2, 5)  (add 5 to indices 0,1,2)

Step 1: Visit [0-3], not fully covered, push down (nothing to push)
Step 2: Visit [0-1], fully covered!
        sum[0-1] += 5 * 2 = 10  →  sum = 13
        lazy[0-1] = 5
        Return (don't go to children)
Step 3: Visit [2-3], not fully covered
Step 4: Visit [2], fully covered!
        sum[2] += 5 * 1 = 5  →  sum = 8
        lazy[2] = 5
Step 5: Back to [2-3]: update sum = 8 + 4 = 12
Step 6: Back to [0-3]: update sum = 13 + 12 = 25

After:
         [0-3]
         sum=25
        /      \
     [0-1]    [2-3]
     sum=13   sum=12
     lazy=5   lazy=0
     /   \    /   \
   [0]  [1] [2]  [3]
   s=1  s=2 s=8  s=4
         lazy=5
```

## Example Usage

```mbt check
///|
test "lazy segtree example" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L]
  let st = @lazy_segtree.LazySegTreeSum::new(arr)
  let _ = st.range_add(1, 3, 2L)
  inspect(st.range_sum(0, 3), content="Some(16)")
  inspect(st.point_query(2), content="Some(5)")
}
```

## Types of Lazy Updates

### Range Add
```
lazy[node] = pending addition
Apply: sum += lazy * size
Combine: new_lazy = old_lazy + update
```

### Range Assign (Set)
```
lazy[node] = assigned value (use sentinel for "no update")
Apply: sum = lazy * size
Combine: new_lazy = update (overwrites)
```

### Range Multiply
```
lazy[node] = pending multiplier
Apply: sum *= lazy
Combine: new_lazy = old_lazy * update
```

## Common Applications

### 1. Range Add, Range Sum
```
Add value to all elements in range.
Query sum of any range.
```

### 2. Range Assign, Range Min
```
Set all elements in range to a value.
Query minimum in any range.
```

### 3. Interval Scheduling
```
Mark intervals as occupied.
Query if an interval is free.
```

### 4. Lazy Tag Composition
```
Multiple update types (add AND multiply).
Compose lazy tags carefully!

For ax + b transformations:
(a₁x + b₁) then (a₂x + b₂) = a₁a₂x + a₂b₁ + b₂
```

## Complexity Analysis

| Operation | Regular Segtree | Lazy Segtree |
|-----------|-----------------|--------------|
| Point update | O(log n) | O(log n) |
| Range update | O(n) | O(log n) |
| Range query | O(log n) | O(log n) |
| Build | O(n) | O(n) |

## Visual: Push Down

```
Before push_down on node with lazy=5:

    [0-3]
   lazy=5
   sum=10
   /    \
[0-1]  [2-3]
 s=3    s=7

After push_down:

    [0-3]
   lazy=0       ← cleared
   sum=10
   /    \
[0-1]  [2-3]
 s=13   s=17    ← updated
lazy=5 lazy=5   ← received
```

## Lazy Segment Tree vs Alternatives

| Structure | Update | Query | Use Case |
|-----------|--------|-------|----------|
| **Lazy Segtree** | O(log n) | O(log n) | Range updates |
| Regular Segtree | O(n) range | O(log n) | Point updates |
| Fenwick + diff | O(log n) | O(log n) | Range add, point query |
| Sqrt decomposition | O(√n) | O(√n) | Simpler code |

**Choose Lazy Segment Tree when**: You need both range updates and range queries.

## Multiple Lazy Tags

```
For range add + range multiply:
Store lazy as (multiplier, addend).

Composition: (m₁, a₁) then (m₂, a₂)
           = (m₁ * m₂, a₁ * m₂ + a₂)

Apply to sum: sum = sum * m + a * size

Order matters! Usually: multiply first, then add.
```

## Implementation Notes

- Push down before accessing children
- Push down in both query and update
- Update parent sum after modifying children
- Use 0 (or identity) for "no pending update"
- For range assign, use sentinel (e.g., -∞) for "no update"
- Careful with lazy tag composition order
- 4n space is typically enough (2n nodes, each with value + lazy)

