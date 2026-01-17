# Sqrt Decomposition (Block Decomposition)

Sqrt decomposition splits an array into blocks of size about √n.
It gives **O(√n)** queries and updates with very simple code.

This is a great tool when:

- you want something simpler than a segment tree,
- O(√n) is fast enough,
- the data is mostly static or updates are local.

---

## 1. Big idea (beginner friendly)

Split the array into equal‑size blocks and store a summary per block.

Example:

```
Array: [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8]
Index:  0  1  2  3  4  5  6  7  8  9 10 11

Block size = 4 (≈ √12)

Block 0: [3, 1, 4, 1]  sum = 9
Block 1: [5, 9, 2, 6]  sum = 22
Block 2: [5, 3, 5, 8]  sum = 21
```

Now a range query can add:

- partial elements at the edges
- full block sums in the middle

---

## 2. Range sum example

Query sum of [2, 9]:

```
Array: [3, 1, 4, 1 | 5, 9, 2, 6 | 5, 3, 5, 8]
         ^     ^     ^           ^
         l=2         full block   r=9
```

Steps:

1. Left partial: indices 2..3 → 4 + 1 = 5
2. Full blocks: block 1 → 22
3. Right partial: indices 8..9 → 5 + 3 = 8

Total = 5 + 22 + 8 = 35

Only a few operations instead of scanning the whole range.

---

## 3. Why √n is optimal

Let block size = B.

Cost:

```
partial scan = O(B)
full blocks = O(n / B)
total = O(B + n/B)
```

Minimized when B = √n.

---

## 4. Range query pseudocode

```mbt nocheck
///|
fn range_sum(l : Int, r : Int) -> Int {
  let mut sum = 0
  while l <= r && l % block_size != 0 {
    sum += arr[l]
    l += 1
  }
  while l + block_size - 1 <= r {
    sum += block_sum[l / block_size]
    l += block_size
  }
  while l <= r {
    sum += arr[l]
    l += 1
  }
  sum
}
```

---

## 5. Point update

To update a single index:

```
arr[i] = new_val
block_sum[block_id] += (new_val - old_val)
```

Only the block summary changes, so O(1).

---

## 6. Other patterns

### Range minimum query

Store `block_min` instead of `block_sum`.

Query scans:

- partial elements at edges,
- block minima in the middle.

Point update may require recomputing the whole block → O(√n).

### Range add + point query

Store `block_add` (lazy tag):

```
range_add(l, r, v):
  update partial elements
  add v to full blocks

point_query(i):
  arr[i] + block_add[block_id]
```

---

## 7. Example usage (conceptual)

This package is tutorial‑only; it does not export a concrete API.

```mbt nocheck
///|
let sd = SqrtDecomp::new([3,1,4,1,5,9,2,6,5,3,5,8])
sd.range_sum(2, 9)   // 35
sd.update(5, 0)
sd.range_sum(2, 9)   // 26
```

---

## 8. Complexity

```
Build:  O(n)
Query:  O(√n)
Update: O(1) to O(√n) depending on aggregate
Space:  O(n)
```

---

## 9. Beginner checklist

1. Choose block size ≈ √n.
2. Use half‑open blocks internally (simpler math).
3. For min/max, updates may need block rebuild.
4. For sum, updates are constant time.

---

## 10. Summary

Sqrt decomposition is a simple trade‑off:

- slower than segment tree,
- much easier to implement,
- great for medium‑sized inputs and quick solutions.
