# Sqrt Decomposition

This package implements sqrt decomposition for **range sum queries with point
updates** (`SqrtSum`). Two private variants, `SqrtMin` (range minimum) and
`SqrtLazy` (range add with lazy propagation), demonstrate how the same block
structure extends to other aggregate operations.

---

## 1. Core idea

An array of `n` elements is divided into contiguous blocks of size `B ≈ √n`.
Each block stores a precomputed aggregate (sum, min, etc.).

A range query on `[l, r]` decomposes into at most three parts:

1. A **left partial block** — elements from `l` to the end of its block.
2. **Complete blocks** in the middle — answered in O(1) each via stored aggregates.
3. A **right partial block** — elements from the start of its block to `r`.

Because there are at most `B` elements in each partial block and at most `n/B`
complete blocks, the total work is `O(B + n/B)`, minimised at `B = √n`.

---

## 2. Block decomposition layout

```
Array (n = 9, block_size B = 3):

index:   0   1   2   3   4   5   6   7   8
value:   1   2   3   4   5   6   7   8   9
         |_________|   |_________|   |_________|
           Block 0       Block 1       Block 2
           sum = 6       sum = 15      sum = 24
```

Block assignment: `block_id(i) = i / B`

```
i=0 → block 0    i=3 → block 1    i=6 → block 2
i=1 → block 0    i=4 → block 1    i=7 → block 2
i=2 → block 0    i=5 → block 1    i=8 → block 2
```

---

## 3. Range query walkthrough

Query `[1, 7]` on the example array above (B = 3):

```
index:   0  [1   2 | 3   4   5 | 6   7]  8
              ^^^^^^^^^^^^^^^^^^^^^^^^^
              query range [1, 7]

Step 1 – left partial (block 0, tail only):
  i=1 → arr[1] = 2
  i=2 → arr[2] = 3
  left_sum = 5

Step 2 – complete blocks (block 1 only):
  block_sum[1] = 15
  block_sum = 15

Step 3 – right partial (block 2, head only):
  i=6 → arr[6] = 7
  i=7 → arr[7] = 8
  right_sum = 15

Total = 5 + 15 + 15 = 35
```

ASCII diagram of the three phases:

```
    Block 0          Block 1          Block 2
  [ 1 | 2 | 3 ]  [ 4 | 5 | 6 ]  [ 7 | 8 | 9 ]
        ^^^^^    ^^^^^^^^^^^^^    ^^^^^^^^^
        Phase 1     Phase 2         Phase 3
      (partial)    (whole block)  (partial)
```

---

## 4. Query algorithm (pseudocode)

```
query(l, r):
  block_l = l / B
  block_r = r / B

  if block_l == block_r:
    # same block: scan directly
    return sum of arr[l..r]

  # Phase 1: left partial block
  left_sum  = sum of arr[l .. (block_l+1)*B - 1]

  # Phase 2: complete middle blocks
  block_sum = sum of blocks[b] for b in block_l+1 .. block_r-1

  # Phase 3: right partial block
  right_sum = sum of arr[block_r*B .. r]

  return left_sum + block_sum + right_sum
```

---

## 5. Point update

Updating a single element changes exactly one block aggregate:

```
update(i, new_val):
  old_val        = arr[i]
  arr[i]         = new_val
  block          = i / B
  blocks[block] += new_val - old_val
```

Diagram — updating index 4 (inside block 1):

```
Before:
  Block 1: [ 4 | 5 | 6 ]   blocks[1] = 15

After update(4, 20):
  Block 1: [ 4 | 20 | 6 ]  blocks[1] = 30   (+15)
                 ^
                 only this element and its block sum change
```

---

## 6. Lazy range add (SqrtLazy)

For range-add operations `arr[l..r] += val`, partial blocks are updated
element-by-element (after flushing any pending lazy value), while complete
blocks store the addend in a `lazy_add` array instead of touching every
element. This keeps both range-add and range-sum at O(√n).

```
range_add(l, r, val):
  if same block:
    update each element directly, adjust block sum

  else:
    # left partial: flush lazy, update elements individually
    push(block_l)
    update arr[l .. block_boundary] and blocks[block_l]

    # complete blocks: record lazy, adjust block sum
    for b in block_l+1 .. block_r-1:
      lazy_add[b] += val
      blocks[b]   += val * block_length(b)

    # right partial: flush lazy, update elements individually
    push(block_r)
    update arr[block_boundary .. r] and blocks[block_r]
```

Lazy query reads `arr[i] + lazy_add[block(i)]` for partial elements, and
uses the already-adjusted `blocks[b]` for complete blocks.

---

## 7. Complexity

```
Operation       Time      Notes
-----------     ------    -----------------------------------------
Build           O(n)      Single pass to compute block aggregates
Point update    O(1)      Adjust one element and its block aggregate
Range query     O(√n)     At most 2*√n partial + √n full-block steps
Range add       O(√n)     Partial blocks: O(√n); full blocks: O(√n)
Space           O(n)      arr + blocks arrays (|blocks| = ⌈n/√n⌉)
```

Block size `B = ⌊√n⌋` minimises the sum `O(B) + O(n/B)` to `O(√n)`.

---

## 8. Example usage (public API)

```mbt check
///|
test "sqrt decomposition example" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let sd = @sqrt_decomposition.SqrtSum(arr)
  debug_inspect(sd.query(1, 3), content="9")
  sd.update(2, 10L)
  debug_inspect(sd.query(1, 3), content="16")
}
```

---

## 9. When to use sqrt decomposition

- Simpler to implement than a segment tree.
- Preferable when updates are complex or offline (Mo's algorithm).
- Good for medium-sized arrays (n up to ~10^5) where O(√n) ≈ 300 per operation
  is acceptable.
- Segment trees or BITs are faster (O(log n)) but harder to adapt to arbitrary
  aggregates; sqrt decomposition wins on flexibility.

---

## 10. Beginner checklist

1. Query and update indices are 0-based and inclusive at both ends: `[l, r]`.
2. Block size is set to `⌊√n⌋`, never 0 (clamped to 1 for tiny arrays).
3. On a point update, only the block containing the updated index is touched.
4. On a range add, partial blocks are flushed before element-level writes;
   complete blocks use a lazy addend to avoid O(n) work.
5. An out-of-range query returns 0 (sum) or `Int64::max_value` (min).
