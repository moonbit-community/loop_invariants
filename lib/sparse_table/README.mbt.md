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

For each k:

```
st[k][i] = min over range [i, i + 2^k - 1]
```

Then any query [l, r] can be answered by **two overlapping blocks** of length
2^k.

---

## 2. Tiny build example

Array:

```
index: 0  1  2  3  4  5  6  7
value: 3  1  4  1  5  9  2  6
```

Length 1 blocks (2^0):

```
st[0]: 3  1  4  1  5  9  2  6
```

Length 2 blocks (2^1):

```
st[1]: min(3,1)=1
       min(1,4)=1
       min(4,1)=1
       min(1,5)=1
       min(5,9)=5
       min(9,2)=2
       min(2,6)=2
```

Length 4 blocks (2^2):

```
st[2]: min(st[1][0], st[1][2]) = min(1,1)=1
       min(st[1][1], st[1][3]) = min(1,1)=1
       min(st[1][2], st[1][4]) = min(1,5)=1
       min(st[1][3], st[1][5]) = min(1,2)=1
       min(st[1][4], st[1][6]) = min(5,2)=2
```

---

## 3. O(1) query idea

To answer `min(l, r)`:

1. Let `len = r - l + 1`
2. Find `k = floor(log2(len))`
3. Use two blocks of length `2^k`:

```
block A = [l, l + 2^k - 1]
block B = [r - 2^k + 1, r]

answer = min(st[k][l], st[k][r - 2^k + 1])
```

The blocks may overlap, but **min** is idempotent, so overlap is safe.

---

## 4. Query walkthrough

Query min of [1, 5]:

```
values: [1, 4, 1, 5, 9]
len = 5 -> k = 2 (since 2^2 = 4)

block A: [1..4]  (length 4)
block B: [2..5]  (length 4)

min = min(st[2][1], st[2][2]) = min(1,1) = 1
```

---

## 5. Example usage (public API)

```mbt check
///|
test "sparse table range minimum" {
  let arr : Array[Int64] = [5L, 2L, 4L, 7L, 1L, 3L]
  let st = @sparse_table.SparseTableMin::new(arr)
  inspect(st.query(1, 4), content="1") // min of [2,4,7,1]
  inspect(st.query(0, 2), content="2") // min of [5,2,4]
  inspect(st.query(3, 3), content="7") // single element
}
```

---

## 6. Why it works (idempotent operations)

We rely on:

```
min(x, x) = x
```

So overlapping ranges do not affect the answer.

This works for:

- min, max, gcd, bitwise AND/OR

It does **not** work for sum.

---

## 7. Why not for sum? (quick demo)

```
Array: [1, 2, 3, 4, 5]
Query sum [1,4] = 2 + 3 + 4 = 9

Overlapping blocks:
  [1,2] sum = 3
  [2,4] sum = 9
  total = 12 (wrong!)
```

Sum is not idempotent, so sparse table is unsuitable.

---

## 8. Complexity

```
Build:  O(n log n)
Query:  O(1)
Space:  O(n log n)
```

---

## 9. Common applications

1. **Range minimum query (RMQ)**
2. **LCA via Euler tour + RMQ**
3. **Range max / gcd / AND / OR**

---

## 10. Beginner checklist

1. Input is static (no updates).
2. Query range is inclusive [l, r].
3. Use log table for O(1) k lookup.
4. Only idempotent operations are valid.

---

## 11. Summary

Sparse tables are the best choice for **static RMQ**:

- O(1) queries
- simple build
- perfect for min/max/gcd on immutable arrays
