# Challenge: Prefix Sum Array

A **prefix sum array** lets you answer range sum queries in O(1) after O(n)
preprocessing.

This package provides:

- `build_prefix_sum(arr)`
- `range_sum(prefix, l, r)` for inclusive ranges `[l, r]`

---

## Core idea

Define a prefix sum array `prefix` of length `n + 1`:

```
prefix[0] = 0
prefix[i+1] = prefix[i] + arr[i]
```

Then the sum of any inclusive range `[l, r]` is:

```
prefix[r + 1] - prefix[l]
```

This works because `prefix[r + 1]` includes everything up to `r`, and
`prefix[l]` removes everything before `l`.

---

## Visual intuition

Array:

```
index:  0   1   2   3
value:  3  -1   4   2
```

Prefix array (length 5):

```
prefix: [0, 3, 2, 6, 8]
          ^  ^  ^  ^
          0  1  2  3
```

Range sum `[1, 2]`:

```
prefix[2 + 1] - prefix[1] = prefix[3] - prefix[1] = 6 - 3 = 3
```

Which matches `-1 + 4 = 3`.

---

## API summary

- `build_prefix_sum`: `O(n)`
- `range_sum`: `O(1)`

---

## Example 1: Basic range sum

```mbt check
///|
test "prefix sum basic" {
  let arr : Array[Int] = [2, -1, 3, 0]
  let prefix = @challenge_prefix_sum.build_prefix_sum(arr[:])
  inspect(prefix, content="[0, 2, 1, 4, 4]")
  inspect(@challenge_prefix_sum.range_sum(prefix[:], 1, 2), content="2")
}
```

---

## Example 2: Full range

```mbt check
///|
test "prefix sum full range" {
  let arr : Array[Int] = [5, 5, 5]
  let prefix = @challenge_prefix_sum.build_prefix_sum(arr[:])
  inspect(@challenge_prefix_sum.range_sum(prefix[:], 0, 0), content="5")
  inspect(@challenge_prefix_sum.range_sum(prefix[:], 0, 2), content="15")
}
```

---

## Example 3: Negative values

```mbt check
///|
test "prefix sum negatives" {
  let arr : Array[Int] = [4, -6, 1, -2, 7]
  let prefix = @challenge_prefix_sum.build_prefix_sum(arr[:])
  inspect(prefix, content="[0, 4, -2, -1, -3, 4]")
  inspect(@challenge_prefix_sum.range_sum(prefix[:], 1, 3), content="-7")
}
```

---

## Example 4: Single element

```mbt check
///|
test "prefix sum single" {
  let arr : Array[Int] = [9]
  let prefix = @challenge_prefix_sum.build_prefix_sum(arr[:])
  inspect(prefix, content="[0, 9]")
  inspect(@challenge_prefix_sum.range_sum(prefix[:], 0, 0), content="9")
}
```

---

## Complexity

- Preprocessing: `O(n)` time, `O(n)` memory
- Query: `O(1)` time

---

## When to use this structure

Use prefix sums when you need:

- many range sum queries
- static arrays (no updates)
- simple, fast aggregation

If you need updates, consider a Fenwick tree or segment tree instead.

---

## Reference implementation

```mbt
///| pub fn build_prefix_sum(arr : ArrayView[Int]) -> Array[Int]

///| pub fn range_sum(prefix : ArrayView[Int], l : Int, r : Int) -> Int
```
