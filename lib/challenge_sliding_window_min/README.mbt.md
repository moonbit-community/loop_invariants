# Challenge: Sliding Window Minimum

Given an array and a window size `k`, compute the minimum value in every
contiguous window of length `k`.

This package provides:

- `sliding_window_min(arr, k)`

---

## Core idea: monotonic deque

We keep a deque of **indices** such that:

- indices are in increasing order (left to right)
- values are in **non-decreasing** order (front is smallest)

That guarantees the front always holds the minimum of the current window.

When we move the window forward by one step:

1. Remove indices that are **out of the window**.
2. Remove indices from the back while their values are **>= new value**.
3. Push the new index.

This gives `O(n)` total time because each index enters and leaves the deque once.

---

## Visual intuition

Example array:

```
index:  0  1  2  3  4  5
value:  4  2 12  3  5  1
k = 3
```

Window `[0..2]`: values `[4, 2, 12]`
- deque holds indices `[1, 2]` (values `[2, 12]`)
- min is `2`

Window `[1..3]`: values `[2, 12, 3]`
- drop index 0 (out of range)
- drop 12 because 3 is smaller
- deque holds `[1, 3]` (values `[2, 3]`)
- min is `2`

Window `[2..4]`: values `[12, 3, 5]`
- drop index 1 (out of range)
- deque holds `[3, 4]` (values `[3, 5]`)
- min is `3`

Window `[3..5]`: values `[3, 5, 1]`
- drop 5 and 3 because 1 is smaller
- deque holds `[5]` (value `[1]`)
- min is `1`

Result: `[2, 2, 3, 1]`

---

## API summary

- Time: `O(n)`
- Space: `O(k)`

---

## Example 1: Basic usage

```mbt check
///|
test "sliding window min basic" {
  let arr : Array[Int] = [4, 2, 12, 3, 5, 1]
  let mins = @challenge_sliding_window_min.sliding_window_min(arr[:], 3)
  inspect(mins, content="[2, 2, 3, 1]")
}
```

---

## Example 2: Classic test case

```mbt check
///|
test "sliding window min classic" {
  let arr : Array[Int] = [1, 3, -1, -3, 5, 3, 6, 7]
  let mins = @challenge_sliding_window_min.sliding_window_min(arr[:], 3)
  inspect(mins, content="[-1, -3, -3, -3, 3, 3]")
}
```

---

## Example 3: Window size 1

```mbt check
///|
test "sliding window min k1" {
  let arr : Array[Int] = [5, 4, 6]
  let mins = @challenge_sliding_window_min.sliding_window_min(arr[:], 1)
  inspect(mins, content="[5, 4, 6]")
}
```

---

## When to use this algorithm

Use a monotonic deque when you need:

- minimum (or maximum) in every fixed-size window
- linear time over the whole array

If you only need one window, a simple scan is enough.

---

## Reference implementation

```mbt nocheck
///| pub fn sliding_window_min(arr : ArrayView[Int], k : Int) -> Array[Int]
```
