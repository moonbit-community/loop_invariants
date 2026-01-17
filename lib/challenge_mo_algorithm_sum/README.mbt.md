# Challenge: Mo's Algorithm (Offline Range Sum)

Mo's algorithm answers **many range queries** on a static array by reordering
queries so that the current window moves only a little each time.

This package implements the **range sum** version:

```
query(l, r) = sum of arr[l..r)
```

Ranges are **half-open**: `l` is inclusive, `r` is exclusive.

---

## Problem restatement (plain words)

You have an array `arr` and a list of queries `(l, r)`.
Each query asks for the sum of elements from index `l` up to (but not including)
index `r`.

The array never changes, but you have many queries.

We want to answer all queries faster than doing each one from scratch.

---

## Why naive is slow

If you compute each query by looping from `l` to `r-1`, you spend `O(n)` per
query.

With `q` queries, that is `O(n * q)`.

Mo's algorithm reduces this to about:

```
O((n + q) * sqrt(n))
```

when each add/remove is `O(1)` (as it is for sums).

---

## Key idea (reorder queries)

We keep a **current window** `[cur_l, cur_r)` and its sum.
When we move from one query to the next, we adjust the window:

- Move left boundary to the new `l`
- Move right boundary to the new `r`
- Update the sum by adding/removing only the elements that changed

To make these moves small on average, we **sort queries** by blocks:

1) Divide the array into blocks of size about `sqrt(n)`.
2) Sort queries by `(block(l), r)`.

This makes consecutive queries have similar `l`, so the window moves a little.

---

## Window movement (diagram)

Suppose the array is:

```
index: 0 1 2 3 4 5 6
value: 2 1 3 4 5 1 2
```

Current window `[1, 5)` covers indices 1..4:

```
            [1------5)
index: 0 1 2 3 4 5 6
value: 2 1 3 4 5 1 2
```

If the next query is `[2, 6)`, we:

- Move left from 1 to 2 (remove arr[1])
- Move right from 5 to 6 (add arr[5])

Only two elements change.

---

## Step-by-step example

Array and queries:

```
arr = [1, 2, 3, 4, 5]
queries = [(0, 3), (1, 4), (2, 5), (0, 5)]
```

We reorder queries by Mo's rule, then sweep:

```
start: cur = [0, 0), sum = 0

query (0, 3): add 0,1,2 -> sum = 6
query (1, 4): remove 0, add 3 -> sum = 9
query (2, 5): remove 1, add 4 -> sum = 12
query (0, 5): add 1,0 -> sum = 15
```

The answers in the **original query order** are:

```
[6, 9, 12, 15]
```

---

## Implementation details

- We store queries with their original index, so we can reorder and then restore
  the answers.
- We keep a running `sum` and update it as the window moves.
- Block size is `ceil(sqrt(n))`.

---

## Reference implementation

```mbt
///| pub fn mo_range_sum(arr : ArrayView[Int], queries : ArrayView[(Int, Int)]) -> Array[Int]
```

The implementation is in `challenge_mo_algorithm_sum.mbt`.

---

## Tests and examples

### Example with increasing window

```mbt check
///|
test "mo example" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let qs : Array[(Int, Int)] = [(0, 3), (1, 4), (2, 5), (0, 5)]
  let ans = @challenge_mo_algorithm_sum.mo_range_sum(arr[:], qs[:])
  inspect(ans, content="[6, 9, 12, 15]")
}
```

### Smaller array

```mbt check
///|
test "mo example small" {
  let arr : Array[Int] = [2, 4, 6, 8]
  let qs : Array[(Int, Int)] = [(0, 2), (1, 3), (0, 4)]
  let ans = @challenge_mo_algorithm_sum.mo_range_sum(arr[:], qs[:])
  inspect(ans, content="[6, 10, 20]")
}
```

### Includes negative values

```mbt check
///|
test "mo example negatives" {
  let arr : Array[Int] = [3, -2, 5, -1, 4]
  let qs : Array[(Int, Int)] = [(0, 5), (1, 4), (2, 3)]
  let ans = @challenge_mo_algorithm_sum.mo_range_sum(arr[:], qs[:])
  inspect(ans, content="[9, 2, 5]")
}
```

### Single-element ranges

```mbt check
///|
test "mo example single element" {
  let arr : Array[Int] = [7, 8, 9]
  let qs : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
  let ans = @challenge_mo_algorithm_sum.mo_range_sum(arr[:], qs[:])
  inspect(ans, content="[7, 8, 9]")
}
```

---

## Complexity

Let `n = arr.length()` and `q = queries.length()`.

- Sorting queries: `O(q log q)`
- Moving window: `O((n + q) * sqrt(n))` in practice
- Memory: `O(q)` for stored queries and answers

---

## Takeaways

- Mo's algorithm is for **offline** queries (you can reorder them).
- The current window moves only a little between nearby queries.
- Range sum works well because adding/removing one element is `O(1)`.
- Ranges are half-open: `[l, r)`.
