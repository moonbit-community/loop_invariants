# Fenwick Range Add + Range Sum

## Overview

This package supports **range add** and **range sum** on a 0‑indexed array
using two Fenwick trees. While a standard Fenwick tree supports point updates
and prefix queries, this variant uses a clever transformation to support
range updates and range queries efficiently.

- **Time**: O(log n) per update/query
- **Space**: O(n)
- **Key Feature**: Both range updates AND range queries

## The Key Insight

```
Standard Fenwick Tree:
  - Point update: a[i] += v      O(log n)
  - Prefix query: sum(0, i)      O(log n)
  - Range query: sum(l, r)       O(log n)  (using prefix difference)
  - Range update: ??? slow ???

The trick: Use difference arrays!

If we add v to range [l, r]:
  - At position l: "start adding v"
  - At position r+1: "stop adding v"

With TWO Fenwick trees, we can track this!
```

## Understanding the Math

```
For range add of value v to [l, r], we want:
  prefix(x) = { 0       if x < l
              { v*(x-l+1) if l ≤ x ≤ r
              { v*(r-l+1) if x > r

Key insight: prefix(x) = v*x - v*(l-1) for l ≤ x ≤ r

So we use two Fenwick trees:
  bit1: stores coefficients for x
  bit2: stores constant terms

prefix(x) = sum(bit1, x) * x - sum(bit2, x)

To add v to [l, r]:
  bit1.add(l, v)    bit2.add(l, v*(l-1))
  bit1.add(r+1, -v) bit2.add(r+1, -v*r)
```

## Visual: How the Two Trees Work

```
Array: [0, 0, 0, 0, 0] (5 elements)
Operation: range_add(1, 3, 5)  // Add 5 to positions 1,2,3

After update:
  bit1: [0, 5, 0, 0, -5]  (at l and r+1)
  bit2: [0, 0, 0, 0, -15] (v*(l-1)=0 at l, -v*r=-15 at r+1)

Query prefix(2):
  sum(bit1, 2) = 5
  sum(bit2, 2) = 0
  prefix(2) = 5 * 2 - 0 = 10  ✓ (positions 1,2 have +5 each)

Query prefix(4):
  sum(bit1, 4) = 5 + (-5) = 0
  sum(bit2, 4) = 0 + (-15) = -15
  prefix(4) = 0 * 4 - (-15) = 15  ✓ (positions 1,2,3 have +5 each)
```

## Algorithm Walkthrough

```
Array: [1, 2, 3, 4, 5], Operation: range_add(1, 3, 2)

Initial array: [1, 2, 3, 4, 5]
After add:     [1, 4, 5, 6, 5]  (added 2 to positions 1,2,3)

Implementation:
  bit1.update(1, +2)   // start adding 2 at position 1
  bit1.update(4, -2)   // stop adding 2 after position 3
  bit2.update(1, +2*0) // constant term at l
  bit2.update(4, -2*3) // constant term at r+1

Query range_sum(1, 3):
  = prefix(3) - prefix(0)
  = (sum(bit1,3)*3 - sum(bit2,3)) - (sum(bit1,0)*0 - sum(bit2,0))
  = (2*3 - 0) - (0 - 0) + original_prefix
  = 6 + (2+3+4) = 6 + 9 = 15  ✓
```

## Quick Start

```mbt check
///|
test "fenwick range add range sum example" {
  let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::from_array([
    1L, 2L, 3L, 4L, 5L,
  ])
  st.range_add(1, 3, 2L)
  inspect(st.range_sum(0, 4), content="21")
  inspect(st.range_sum(1, 3), content="15")
}
```

## More Examples

```mbt check
///|
test "fenwick range add point query" {
  let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::new(4)
  st.range_add(0, 3, 5L)
  inspect(st.range_sum(2, 2), content="5")
}
```

```mbt check
///|
test "fenwick multiple range adds" {
  let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::new(5)
  st.range_add(0, 2, 10L) // [10, 10, 10, 0, 0]
  st.range_add(2, 4, 5L) // [10, 10, 15, 5, 5]
  inspect(st.range_sum(0, 4), content="45")
  inspect(st.range_sum(1, 3), content="30")
}
```

## Common Applications

### 1. Range Updates + Range Queries
```
The classic use case: both update and query are ranges.
Standard Fenwick only does point update + range query.
```

### 2. Difference Array Operations
```
Many problems can be solved by marking "start" and "end"
of ranges. This structure handles that efficiently.
```

### 3. Online Range Increment
```
Process range increments online (not known in advance),
while answering range sum queries.
```

## Complexity Analysis

| Operation | Time |
|-----------|------|
| range_add(l, r, v) | O(log n) |
| range_sum(l, r) | O(log n) |
| Build from array | O(n log n) |

## Fenwick Range Add vs Other Approaches

| Structure | Point Update | Range Update | Range Query |
|-----------|--------------|--------------|-------------|
| Array | O(1) | O(n) | O(n) |
| Standard Fenwick | O(log n) | O(n log n) | O(log n) |
| **Fenwick Range Add** | O(log n) | O(log n) | O(log n) |
| Segment Tree + Lazy | O(log n) | O(log n) | O(log n) |

**Choose Fenwick Range Add when**: You need both range updates and range queries
with simpler code than lazy segment tree.

## The Mathematical Formula

```
To compute prefix(x) with range add [l, r, v]:

prefix(x) = Σ (v for each active range covering position x)

We decompose this as:
  prefix(x) = A(x) * x - B(x)

Where:
  A(x) = sum of v for ranges starting at ≤ x
  B(x) = sum of v*(l-1) for ranges starting at ≤ x

bit1 maintains A(x), bit2 maintains B(x)
```

## Implementation Notes

- Uses 0-indexed arrays (adjust for 1-indexed problems)
- `range_add` and `range_sum` use inclusive indices `[l, r]`
- Need to handle the "end" marker at r+1 carefully
- Two Fenwick trees of the same size
- Can combine with other Fenwick tricks (2D, etc.)

