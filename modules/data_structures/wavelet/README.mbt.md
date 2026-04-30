# Wavelet Tree

A wavelet tree is a data structure for fast **range queries** on a static array
of integers. It answers queries like:

- "How many times does value `x` appear in index range `[l, r)`?"
- "How many values are `< x` in index range `[l, r)`?"
- "What is the k-th smallest value in index range `[l, r)`?"

All queries run in **O(log S)** time, where **S** is the alphabet size
(number of distinct values).

This package contains a wavelet tree implementation used internally. The types
are private, so the examples below come from the package's own test suite.

---

## 1. Core idea: split by value, record direction with bits

At each tree node we split the current alphabet range `[lo, hi)` at the
midpoint `mid = (lo + hi) / 2`:

```
left  child  <- values in [lo, mid)   (bit = 0)
right child  <- values in [mid, hi)   (bit = 1)
```

Each node stores:

- **bits**: a boolean array recording where each element went (`false` = left,
  `true` = right).
- **rank**: a prefix-sum of bits, so `rank[i]` = number of `1`s in
  `bits[0..i)`. This lets us map any index range `[l, r)` into either child
  in O(1).

---

## 2. Tree structure for `A = [3, 0, 1, 2, 3, 1, 2, 0]`, alphabet `[0, 4)`

```
Indices:    0  1  2  3  4  5  6  7
Array A:    3  0  1  2  3  1  2  0

Level 0 - root, value range [0, 4), mid = 2
   Bit = 1 if value >= 2, else 0
   bits:   1  0  0  1  1  0  1  0
   rank:   0  1  1  1  2  3  3  4  4   (prefix sums)

   Elements going LEFT  (bit=0): [0, 1, 1, 0]   <- values in [0, 2)
   Elements going RIGHT (bit=1): [3, 2, 3, 2]   <- values in [2, 4)

Level 1 - left child, value range [0, 2), mid = 1
   bits:   0  1  1  0
   rank:   0  0  1  2  2

   Elements going LEFT  (bit=0): [0, 0]   <- values in [0, 1)
   Elements going RIGHT (bit=1): [1, 1]   <- values in [1, 2)

Level 1 - right child, value range [2, 4), mid = 3
   bits:   1  0  1  0
   rank:   0  1  1  2  2

   Elements going LEFT  (bit=0): [2, 2]   <- values in [2, 3)
   Elements going RIGHT (bit=1): [3, 3]   <- values in [3, 4)

Level 2 - leaves (range size 1, recursion stops):
   [0, 0]   leaf for value 0
   [1, 1]   leaf for value 1
   [2, 2]   leaf for value 2
   [3, 3]   leaf for value 3
```

Each position in the original array traces a unique path from root to a leaf,
with each step determined by one bit in that level's bitvector.

---

## 3. Range mapping via prefix sums

Given a node's `rank` array, we can map an index range `[l, r)` into either
child in O(1):

```
bits:   1  0  0  1  1  0  1  0
prefix: 0  1  1  1  2  3  3  4  4

For query range [l=2, r=6):
  ones  in range = rank[6] - rank[2] = 3 - 1 = 2   -> right child gets 2 elements
  zeros in range = (r - l) - ones    = 4 - 2 = 2   -> left  child gets 2 elements

Mapped range in right child: [rank[2], rank[6]) = [1, 3)
Mapped range in left  child: [2 - rank[2], 6 - rank[6]) = [1, 3)
```

---

## 4. Step-by-step: count occurrences of value 1 in `A[0, 8)`

```
Array: [3, 0, 1, 2, 3, 1, 2, 0], query: count(0, 8, v=1)

Step 1 - root, value range [0, 4), mid = 2:
  v=1 < mid=2, so go LEFT.
  zeros in [0, 8) = (8 - 0) - (rank[8] - rank[0]) = 8 - 4 = 4
  New range in left child: [0 - rank[0], 8 - rank[8]) = [0, 4)

Step 2 - left child, value range [0, 2), mid = 1:
  v=1 >= mid=1, so go RIGHT.
  ones in [0, 4) = rank[4] - rank[0] = 2 - 0 = 2
  New range in right child: [rank[0], rank[4]) = [0, 2)

Step 3 - reach leaf for value 1, range [0, 2):
  Answer = right - left = 2 - 0 = 2

Result: value 1 appears 2 times in A[0, 8). Correct (indices 2 and 5).
```

---

## 5. Step-by-step: quantile (k-th smallest) in `A[0, 8)`, k=4

The quantile query finds the k-th smallest value (1-indexed).

```
Array: [3, 0, 1, 2, 3, 1, 2, 0]
Sorted: [0, 0, 1, 1, 2, 2, 3, 3]
4th smallest = 1

Step 1 - root, value range [0, 4), mid = 2, range [0, 8), k=4:
  zeros in [0, 8) = 4
  k=4 <= zeros=4, so go LEFT (answer is in [lo, mid) = [0, 2)).
  New range in left child: [0, 4), k stays 4.

Step 2 - left child, value range [0, 2), mid = 1, range [0, 4), k=4:
  zeros in [0, 4) = rank for left-child level:
    bits: 0 1 1 0, rank: 0 0 1 2 2
    zeros in [0, 4) = (4 - 0) - (rank[4] - rank[0]) = 4 - 2 = 2
  k=4 > zeros=2, so go RIGHT (answer is in [mid, hi) = [1, 2)).
  New k = 4 - 2 = 2.
  New range in right child: [rank[0], rank[4]) = [0, 2).

Step 3 - reach leaf for value 1, range [0, 2), k=2:
  Answer = node.lo = 1

Result: 4th smallest value is 1. Correct.
```

---

## 6. Step-by-step: count_less (values < x) in `A[0, 4)`, x=3

```
Array slice A[0,4) = [3, 0, 1, 2], query: count_less(0, 4, v=3)
Expected answer: 3 (values 0, 1, 2 are all < 3)

Step 1 - root, value range [0, 4), mid = 2, range [0, 4), count=0:
  v=3 > mid=2, so go RIGHT, accumulate left count.
  zeros in [0, 4) = (4-0) - (rank[4] - rank[0]) = 4 - 2 = 2
  count = 0 + 2 = 2
  New range in right child: [rank[0], rank[4]) = [0, 2).

Step 2 - right child, value range [2, 4), mid = 3, range [0, 2), count=2:
  v=3 <= mid=3, so go LEFT, do not accumulate.
  bits: 1 0 1 0, rank for this subarray: 0 1 1 2 2
  zeros in [0, 2) = (2-0) - (rank[2] - rank[0]) = 2 - 1 = 1
  New range in left child: [0 - rank[0], 2 - rank[2]) = [0, 1).

Step 3 - reach leaf for value 2, range [0, 1), count=2:
  node.lo=2 < v=3, so answer = count + (right - left) = 2 + 1 = 3.

Result: 3 values < 3 in A[0, 4). Correct (values are 0, 1, 2).
```

---

## 7. How queries use the prefix-sum (rank) array

```
bits:   1  0  0  1  1  0  1  0
rank:   0  1  1  1  2  3  3  4  4   (rank[i] = number of 1s in bits[0..i))

For any range [l, r):
  right_count (ones)  = rank[r] - rank[l]
  left_count  (zeros) = (r - l) - right_count

Map [l, r) to right child: [rank[l], rank[r])
Map [l, r) to left  child: [l - rank[l], r - rank[r])
```

This O(1) mapping is what makes every query O(log S) overall.

---

## 8. Supported operations

| Operation       | Description                                 | Time     |
|-----------------|---------------------------------------------|----------|
| `build`         | Build wavelet tree from array               | O(n log S) |
| `access`        | Get value at position i                     | O(log S) |
| `count`         | Count occurrences of v in [l, r)            | O(log S) |
| `count_less`    | Count values < v in [l, r)                  | O(log S) |
| `count_range`   | Count values in [lo, hi) within [l, r)      | O(log S) |
| `quantile`      | k-th smallest value in [l, r)               | O(log S) |
| `select`        | Index of k-th occurrence of v in [l, r)     | O(log S * log n) |
| `mode`          | Most frequent value in [l, r)               | O(S log S) |
| `distinct_values` | All distinct values with counts in [l, r) | O(S log S) |

S = alphabet size (max value + 1). n = array length.

---

## 9. Complexity

```
Build:  O(n log S)
Queries: O(log S) each
Space:  O(n log S) bits
```

---

## 10. Common pitfalls

- Values must be in a known range `[0, S)`. Pass the correct `sigma` to `build`.
- The index range `[l, r)` is half-open: `l` is inclusive, `r` is exclusive.
- `quantile` uses 1-based k: `k=1` means the smallest element.
- The structure is best for static arrays. Updates require a full rebuild.
- Off-by-one errors in rank lookups are the most common source of bugs.
