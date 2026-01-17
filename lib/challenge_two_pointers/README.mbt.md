# Challenge: Two Pointers / Sliding Window

The two-pointers (sliding window) technique maintains a window `[left, right]`
that satisfies a condition while `right` moves forward. It turns many
`O(n^2)` scans into `O(n)`.

This package solves a classic problem:

- Count the number of subarrays with sum `<= k`
- The array is **non-negative** (critical for correctness)

This package provides:

- `count_subarrays_leq(arr, k)`

---

## Core idea

Because all values are non-negative, the window sum only increases when we move
`right` forward, and only decreases when we move `left` forward. That means
`left` moves monotonically and never goes backward.

Algorithm:

1. Extend the window by moving `right` one step.
2. If the sum is too large, move `left` forward until the sum is valid.
3. When valid, **all subarrays ending at `right` and starting from `left` to
   `right` are valid**, so we add `right - left + 1`.

---

## Visual intuition

Array:

```
index:  0  1  2  3
value:  1  2  1  1
k = 3
```

At `right = 2`, the window could be `[0..2]` with sum `4`, which is too large.
We move `left` to 1, making the sum `3`. Now valid subarrays ending at index 2
are:

```
[2], [2,1]   (i.e., arr[2..2] and arr[1..2])
```

There are `right - left + 1 = 2` of them.

---

## API summary

- Time: `O(n)`
- Space: `O(1)` extra space

---

## Example 1: Basic counting

```mbt check
///|
test "two pointers basic" {
  let arr : Array[Int] = [1, 2, 1, 1]
  let count = @challenge_two_pointers.count_subarrays_leq(arr[:], 3)
  inspect(count, content="7")
}
```

Valid subarrays (sum <= 3):

```
[1], [1,2], [2], [2,1], [1], [1,1], [1]
```

---

## Example 2: Uniform values

```mbt check
///|
test "two pointers uniform" {
  let arr : Array[Int] = [2, 2, 2]
  let count = @challenge_two_pointers.count_subarrays_leq(arr[:], 3)
  inspect(count, content="3")
}
```

Only the single-element subarrays are valid.

---

## Example 3: k too small

```mbt check
///|
test "two pointers small k" {
  let arr : Array[Int] = [1, 1, 1]
  let count = @challenge_two_pointers.count_subarrays_leq(arr[:], 0)
  inspect(count, content="0")
}
```

---

## When to use this technique

Use two pointers when:

- the window condition becomes easier to satisfy by moving one pointer
- the array values are non-negative (for sum-based windows)
- you need linear-time counting of subarrays

If the array has negative values, you need different methods (e.g., prefix sums
+ binary search or data structures).

---

## Reference implementation

```mbt
///| pub fn count_subarrays_leq(arr : ArrayView[Int], k : Int) -> Int
```
