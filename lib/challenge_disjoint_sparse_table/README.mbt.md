# Challenge: Disjoint Sparse Table

A disjoint sparse table answers range queries in O(1) after O(n log n)
preprocessing. It is similar to a sparse table, but it supports any associative
operation (min, max, gcd, sum, etc.) without requiring idempotence.

This challenge uses **range minimum query** as the concrete example.

## Problem statement

Given an array `arr`, preprocess it so you can answer:

```
min(arr[l..r))
```

in O(1) time per query.

## Core idea

For each level k, we divide the array into blocks of size `2^(k+1)` and treat
the midpoint as a split. We precompute:

- left prefix minima moving left from the midpoint
- right prefix minima moving right from the midpoint

Any query `[l, r)` crosses exactly one midpoint at the highest bit where `l`
and `r-1` differ. The answer is the min of two precomputed values.

## Diagram: one block at level k

Block size = 8, midpoint = 4

```
indices: 0 1 2 3 | 4 5 6 7
values : a b c d | e f g h

left prefixes (from mid-1):
L[3]=d
L[2]=min(c,d)
L[1]=min(b,c,d)
L[0]=min(a,b,c,d)

right prefixes (from mid):
R[4]=e
R[5]=min(e,f)
R[6]=min(e,f,g)
R[7]=min(e,f,g,h)
```

A query that crosses this midpoint uses:

```
min(L[l], R[r-1])
```

## How queries choose a level

Let:

```
k = highest_bit(l ^ (r - 1))
```

This is the highest bit where `l` and `r-1` differ, which identifies the
unique midpoint they cross at level k.

## Examples

### Example 1: basic queries

```mbt check
///|
test "disjoint sparse example" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let dst = @challenge_disjoint_sparse_table.build_disjoint_sparse_table(arr[:])
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 1, 5), content="1")
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 2, 4), content="4")
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 5, 8), content="0")
}
```

### Example 2: single element and full range

```mbt check
///|
test "disjoint sparse edge ranges" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let dst = @challenge_disjoint_sparse_table.build_disjoint_sparse_table(arr[:])
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 3, 4), content="7")
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 0, 8), content="0")
}
```

### Example 3: different array

```mbt check
///|
test "disjoint sparse different array" {
  let arr : Array[Int] = [9, 8, 7, 6, 5, 4]
  let dst = @challenge_disjoint_sparse_table.build_disjoint_sparse_table(arr[:])
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 1, 4), content="6")
  inspect(@challenge_disjoint_sparse_table.range_min(dst, 2, 6), content="4")
}
```

## Complexity

- Build: O(n log n)
- Query: O(1)
- Space: O(n log n)

## Practical notes and pitfalls

- Queries are **half-open**: `[l, r)`.
- The operation must be associative. Min is associative, so it works.
- For invalid ranges (l >= r), behavior is undefined; check before calling.

## When to use it

Use a disjoint sparse table when you need many static range queries with
O(1) query time and can afford O(n log n) preprocessing.
