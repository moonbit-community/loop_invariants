# Sparse Table (Range Minimum Query)

This package implements a **Sparse Table** for fast **range minimum queries**
on a static array.

Key properties:

- Build once in **O(n log n)**
- Query any range in **O(1)**
- Works for **idempotent** operations (min, max, gcd)

---

## 1. Big idea (beginner friendly)

Precompute answers for ranges whose length is a power of two.

For each level `j` and starting index `i`:

```
table[i][j] = min over range [i, i + 2^j - 1]
```

Then any query `[l, r]` can be answered by **two overlapping blocks** of
length `2^k` where `k = floor(log2(r - l + 1))`.

---

## 2. Structure diagram

The array below has 8 elements.  Each row of the sparse table covers intervals
of one particular power-of-2 length.

```
Array:  index  0    1    2    3    4    5    6    7
        value  3    1    4    1    5    9    2    6

j=0  (len 1):  [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]
                3    1    4    1    5    9    2    6

j=1  (len 2):  [0,1][1,2][2,3][3,4][4,5][5,6][6,7]
                1    1    1    1    5    2    2

j=2  (len 4):  [0,3][1,4][2,5][3,6][4,7]
                1    1    1    1    2

j=3  (len 8):  [0,7]
                1
```

Each cell at level `j` is built from two half-length cells at level `j-1`:

```
table[i][j] = min( table[i][j-1],  table[i + 2^(j-1)][j-1] )
              |____left half____|   |______right half________|
```

---

## 3. Build example (step by step)

Array: `3  1  4  1  5  9  2  6`

**Level 0** — copy the array directly:

```
table[i][0]:  3  1  4  1  5  9  2  6
```

**Level 1** — each cell covers 2 elements:

```
table[0][1] = min(3, 1) = 1      covers [0, 1]
table[1][1] = min(1, 4) = 1      covers [1, 2]
table[2][1] = min(4, 1) = 1      covers [2, 3]
table[3][1] = min(1, 5) = 1      covers [3, 4]
table[4][1] = min(5, 9) = 5      covers [4, 5]
table[5][1] = min(9, 2) = 2      covers [5, 6]
table[6][1] = min(2, 6) = 2      covers [6, 7]
```

**Level 2** — each cell covers 4 elements, built from two level-1 cells:

```
table[0][2] = min(table[0][1], table[2][1]) = min(1, 1) = 1   covers [0, 3]
table[1][2] = min(table[1][1], table[3][1]) = min(1, 1) = 1   covers [1, 4]
table[2][2] = min(table[2][1], table[4][1]) = min(1, 5) = 1   covers [2, 5]
table[3][2] = min(table[3][1], table[5][1]) = min(1, 2) = 1   covers [3, 6]
table[4][2] = min(table[4][1], table[6][1]) = min(5, 2) = 2   covers [4, 7]
```

**Level 3** — one cell covers the whole array:

```
table[0][3] = min(table[0][2], table[4][2]) = min(1, 2) = 1   covers [0, 7]
```

---

## 4. O(1) query idea

To answer `min(l, r)`:

1. Let `len = r - l + 1`
2. Find `k = floor(log2(len))`
3. Use two blocks of length `2^k`:

```
block A = [l,          l + 2^k - 1]
block B = [r - 2^k + 1,          r]

answer = min(table[l][k], table[r - 2^k + 1][k])
```

The two blocks together always cover the full query range, and may overlap in
the middle.  Because `min(x, x) = x`, any overlap is harmless.

---

## 5. Query walkthrough

Query: minimum of `arr[1..5]`  (values `1  4  1  5  9`)

```
l=1, r=5
len = r - l + 1 = 5
k   = floor(log2(5)) = 2   (since 2^2 = 4 <= 5 < 8 = 2^3)

Block A starts at l=1, length 2^k=4:   covers indices [1, 4]
Block B ends   at r=5, length 2^k=4:   covers indices [2, 5]

             index: 0   1   2   3   4   5   6   7
             value: 3   1   4   1   5   9   2   6
                        |_______A_______|
                            |_______B_______|

answer = min( table[1][2], table[2][2] )
       = min( 1,           1           )
       = 1

Indices 2 and 3 are covered by both A and B -- that overlap is safe because
min is idempotent.
```

---

## 6. Example usage (public API)

```mbt check
///|
test "sparse table range minimum" {
  let arr : Array[Int64] = [5L, 2L, 4L, 7L, 1L, 3L]
  let st = @sparse_table.SparseTableMin(arr)
  inspect(st.query(1, 4), content="1") // min of [2,4,7,1]
  inspect(st.query(0, 2), content="2") // min of [5,2,4]
  inspect(st.query(3, 3), content="7") // single element
}
```

---

## 7. Why it works (idempotent operations)

We rely on:

```
min(x, x) = x
```

So overlapping ranges do not affect the answer.

This works for:

- min, max, gcd, bitwise AND/OR

It does **not** work for sum.

---

## 8. Why not for sum? (quick demo)

```
Array: [1, 2, 3, 4, 5]
Query sum [1,4] = 2 + 3 + 4 = 9

Overlapping blocks:
  [1,2] sum = 3
  [2,4] sum = 9
  total = 12  (wrong -- elements 2 and 3 are counted twice)
```

Sum is not idempotent, so the sparse table trick is invalid for it.

---

## 9. Complexity

```
Build:  O(n log n)
Query:  O(1)
Space:  O(n log n)
```

---

## 10. Common applications

1. **Range minimum query (RMQ)**
2. **LCA via Euler tour + RMQ**
3. **Range max / gcd / AND / OR**

---

## 11. Beginner checklist

1. Input is static (no updates).
2. Query range is inclusive `[l, r]`.
3. Use log table for O(1) `k` lookup.
4. Only idempotent operations are valid.

---

## 12. Summary

Sparse tables are the best choice for **static RMQ**:

- O(1) queries
- simple build
- perfect for min/max/gcd on immutable arrays
