# Sparse Table

## Overview

A **Sparse Table** answers static range queries (min, max, GCD) in **O(1)** time
after **O(n log n)** preprocessing. It works for **idempotent** operations where
`f(a, a) = a` (min, max, GCD, OR, AND - but NOT sum).

## The Key Insight

Precompute answers for all ranges of length 2^k:

```
Array: [3, 1, 4, 1, 5, 9, 2, 6]

Length 1 (2^0):  [3] [1] [4] [1] [5] [9] [2] [6]
Length 2 (2^1):  [1] [1] [1] [1] [5] [2] [2]
Length 4 (2^2):  [1] [1] [1] [1] [2]
Length 8 (2^3):  [1]

st[k][i] = min of arr[i..i+2^k-1]
```

## Query in O(1)

For range [l, r], find largest k where 2^k ≤ (r - l + 1):

```
Query min of [1, 5]:
  Length = 5, k = 2 (since 2^2 = 4 ≤ 5)

  Use two overlapping ranges:
  [1, 4] and [2, 5]

        1   4   1   5   9
        [-------]           st[2][1] = 1
            [-------]       st[2][2] = 1

  Answer = min(1, 1) = 1

Overlapping is OK because min(a, a) = a (idempotent)
```

## Why It Works

For idempotent operations, overlapping ranges give correct answer:

```
min(min([l, l+2^k-1]), min([r-2^k+1, r])) = min([l, r])

Because:
1. Both ranges are within [l, r]
2. Together they cover [l, r]
3. Overlap doesn't change min/max/GCD
```

## Building the Table

```
Recurrence:
st[0][i] = arr[i]                          (single elements)
st[k][i] = min(st[k-1][i], st[k-1][i + 2^(k-1)])

Visual:
        i           i+2^(k-1)      i+2^k-1
        |              |              |
        [----st[k-1]---][---st[k-1]---]
        [----------st[k]-------------]
```

## Example Usage

```mbt check
///|
test "sparse table range minimum" {
  let arr : Array[Int64] = [5L, 2L, 4L, 7L, 1L, 3L]
  let st = @sparse_table.SparseTableMin::new(arr)

  // Query minimum in range [1, 4] (indices 1 to 4 inclusive)
  inspect(st.query(1, 4), content="1") // min of [2, 4, 7, 1]

  // Query minimum in range [0, 2]
  inspect(st.query(0, 2), content="2") // min of [5, 2, 4]
}
```

## Common Applications

1. **Range Minimum Query (RMQ)**
   - Foundation for LCA algorithms
   - Competitive programming staple

2. **Range Maximum Query**
   - Stock price analysis
   - Signal processing

3. **Range GCD**
   - Number theory problems
   - Array analysis

4. **LCA via RMQ**
   - Convert tree to Euler tour
   - LCA = node with minimum depth in range

## Complexity Analysis

| Operation | Time | Space |
|-----------|------|-------|
| Build     | O(n log n) | O(n log n) |
| Query     | O(1) | - |

## Sparse Table vs Other Structures

| Structure     | Build    | Query    | Update | Best For |
|---------------|----------|----------|--------|----------|
| **Sparse Table** | O(n log n) | O(1) | N/A | Static RMQ |
| Segment Tree  | O(n)     | O(log n) | O(log n) | Dynamic |
| Fenwick Tree  | O(n)     | O(log n) | O(log n) | Sum only |
| Block Decomp  | O(n)     | O(√n)    | O(1)   | Simple |

**Choose Sparse Table when**: Data is static and you need many O(1) queries.

## Why Not For Sum?

Sum is not idempotent: `sum(a, a) = 2a ≠ a`

```
Array: [1, 2, 3, 4, 5]
Query sum [1, 4]:

  Overlapping ranges [1,2] and [2,4]:
  sum([1,2]) = 3
  sum([2,4]) = 9
  Total = 12  WRONG! (actual = 2+3+4 = 9)

The overlap (element 2) is counted twice!
```

For range sum, use Fenwick Tree or Segment Tree.

## The Log Table Optimization

Precompute log2 values to avoid computing them at query time:

```
log2[1] = 0
log2[2] = 1
log2[3] = 1
log2[4] = 2
...

log2[i] = log2[i/2] + 1  (for i >= 2)
```

This makes queries truly O(1) without any log computation.
