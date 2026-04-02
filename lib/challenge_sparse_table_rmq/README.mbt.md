# Challenge: Sparse Table RMQ

A **sparse table** answers static range minimum queries (RMQ) in **O(1)** after
**O(n log n)** preprocessing.

This package provides:

- `build_sparse_table(arr)`
- `range_min(st, l, r)` for half-open ranges `[l, r)`

---

## Core idea

Precompute minimums for ranges of length `2^k`:

```
st[k][i] = min(arr[i .. i + 2^k))
```

Then any range `[l, r)` can be covered by two overlapping blocks of length
`2^k`, where:

```
k = floor(log2(r - l))
```

So:

```
min(arr[l..r)) = min(st[k][l], st[k][r - 2^k])
```

Because `min` is idempotent, overlap is fine.

---

## Visual intuition

Array:

```
index:  0  1  2  3  4  5  6  7
value:  5  2  4  7  1  3  6  0
```

Suppose we query `[1, 5)` (values `[2,4,7,1]`).

Length is 4, so `k = log2(4) = 2` and `2^k = 4`.

We use:

```
st[2][1] = min(arr[1..5))
```

Which directly gives the answer `1`.

For a non-power-of-two length, say `[1, 6)` (length 5), we use two blocks of
length 4:

```
st[2][1] covers [1..5)
st[2][2] covers [2..6)
```

The minimum of those two blocks is the answer.

---

## API summary

- Build: `O(n log n)` time, `O(n log n)` memory
- Query: `O(1)` time

---

## Example 1: Basic query

```mbt check
///|
test "sparse table example" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let st = @challenge_sparse_table_rmq.build_sparse_table(arr[:])
  inspect(@challenge_sparse_table_rmq.range_min(st, 1, 5), content="1")
}
```

---

## Example 2: Short range

```mbt check
///|
test "sparse table short range" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let st = @challenge_sparse_table_rmq.build_sparse_table(arr[:])
  inspect(@challenge_sparse_table_rmq.range_min(st, 2, 4), content="4")
}
```

---

## Example 3: Full range

```mbt check
///|
test "sparse table full range" {
  let arr : Array[Int] = [5, 2, 4, 7, 1, 3, 6, 0]
  let st = @challenge_sparse_table_rmq.build_sparse_table(arr[:])
  inspect(@challenge_sparse_table_rmq.range_min(st, 0, 8), content="0")
}
```

---

## When to use this structure

Use a sparse table when:

- the array is **static** (no updates)
- you need many fast queries
- the operation is **idempotent** (min, max, gcd)

If you need updates, use a segment tree instead.

---

## Reference implementation

```mbt nocheck
///| pub fn build_sparse_table(arr : ArrayView[Int]) -> SparseTable

///| pub fn range_min(st : SparseTable, l : Int, r : Int) -> Int
```
