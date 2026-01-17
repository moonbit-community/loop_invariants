# Challenge: Sqrt Decomposition (Range Sum)

Sqrt decomposition is a technique for fast **range sum queries** with **point
updates** on a static array.

This package provides:

- `build_sqrt_decomp(arr)`
- `range_sum(sd, l, r)` for `[l, r)`
- `update(sd, idx, value)`

---

## Core idea

Split the array into blocks of size about `sqrt(n)` and store the sum of each
block. Then:

- a range query scans at most two partial blocks and uses block sums for full
  blocks in the middle
- a point update updates one element and its block sum

---

## Visual intuition

Array:

```
index:  0  1  2  3  4  5  6  7  8
value:  1  2  3  4  5  6  7  8  9
```

Suppose `block_size = 3`. The blocks are:

```
B0: [0,1,2] sum = 1+2+3
B1: [3,4,5] sum = 4+5+6
B2: [6,7,8] sum = 7+8+9
```

Query `[2, 8)`:

- partial left: index 2
- full blocks: B1
- partial right: indices 6,7

Total = `arr[2] + sum(B1) + arr[6] + arr[7]`

---

## API summary

- Build: `O(n)`
- Query: `O(sqrt(n))`
- Update: `O(1)`

---

## Example 1: Range sum

```mbt check
///|
test "sqrt decomposition example" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6]
  let sd = @challenge_sqrt_decomposition_sum.build_sqrt_decomp(arr[:])
  inspect(@challenge_sqrt_decomposition_sum.range_sum(sd, 2, 6), content="18")
}
```

`[2, 6)` is `3 + 4 + 5 + 6 = 18`.

---

## Example 2: Point update

```mbt check
///|
test "sqrt decomposition update" {
  let arr : Array[Int] = [1, 2, 3, 4]
  let sd = @challenge_sqrt_decomposition_sum.build_sqrt_decomp(arr[:])
  @challenge_sqrt_decomposition_sum.update(sd, 1, 10)
  inspect(@challenge_sqrt_decomposition_sum.range_sum(sd, 0, 2), content="11")
}
```

After updating index 1 to 10, the range `[0,2)` becomes `1 + 10 = 11`.

---

## Example 3: Full range

```mbt check
///|
test "sqrt decomposition full range" {
  let arr : Array[Int] = [2, 2, 2, 2, 2]
  let sd = @challenge_sqrt_decomposition_sum.build_sqrt_decomp(arr[:])
  inspect(@challenge_sqrt_decomposition_sum.range_sum(sd, 0, 5), content="10")
}
```

---

## When to use this structure

Use sqrt decomposition when:

- you need both queries and point updates
- you want a simpler structure than a segment tree
- `O(sqrt(n))` per query is acceptable

If you need `O(log n)` queries, use a Fenwick tree or segment tree instead.

---

## Reference implementation

```mbt
///| pub fn build_sqrt_decomp(arr : ArrayView[Int]) -> SqrtDecomp

///| pub fn range_sum(sd : SqrtDecomp, l : Int, r : Int) -> Int

///| pub fn update(sd : SqrtDecomp, idx : Int, value : Int) -> Unit
```
