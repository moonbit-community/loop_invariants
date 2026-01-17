# Challenge: Ternary Search (Unimodal Array)

Ternary search finds the **minimum** in a unimodal sequence: the values
**decrease** up to a single valley, then **increase**.

This package provides:

- `find_min_unimodal(arr)` returning the index of the minimum value

---

## Core idea

For a unimodal array, if we pick two midpoints `m1` and `m2`:

- If `arr[m1] <= arr[m2]`, the minimum lies in `[lo, m2]`.
- Otherwise, the minimum lies in `[m1, hi]`.

We repeatedly shrink the search interval by one third until only a small window
remains. Then we scan that window directly.

---

## Visual intuition

Example array (decreasing then increasing):

```
index:  0  1  2  3  4  5  6
value:  9  7  5  3  4  6  8
```

The minimum is at index `3` (value `3`).

Each iteration compares two midpoints and discards the side that cannot contain
the minimum.

---

## Pseudocode sketch

```mbt nocheck
lo = 0
hi = n - 1
while hi - lo > 3:
  m1 = lo + (hi - lo) / 3
  m2 = hi - (hi - lo) / 3
  if arr[m1] <= arr[m2]:
    hi = m2 - 1
  else:
    lo = m1 + 1

// scan [lo..hi] to find exact minimum
```

---

## Example 1: Classic valley

```mbt check
///|
test "ternary search unimodal" {
  let arr : Array[Int] = [9, 7, 5, 3, 4, 6, 8]
  let idx = @challenge_ternary_search.find_min_unimodal(arr[:])
  inspect(idx, content="3")
}
```

---

## Example 2: Strictly decreasing

Even if the array is always decreasing, it still fits the model (the valley is
at the end).

```mbt check
///|
test "ternary search decreasing" {
  let arr : Array[Int] = [5, 4, 3, 2, 1]
  let idx = @challenge_ternary_search.find_min_unimodal(arr[:])
  inspect(idx, content="4")
}
```

---

## Example 3: Strictly increasing

Here the valley is at the beginning.

```mbt check
///|
test "ternary search increasing" {
  let arr : Array[Int] = [1, 2, 3, 4, 5]
  let idx = @challenge_ternary_search.find_min_unimodal(arr[:])
  inspect(idx, content="0")
}
```

---

## Complexity

- Each iteration shrinks the interval by a constant factor.
- The final scan checks at most 4 elements.

So the complexity is:

- `O(log n)` time
- `O(1)` extra space

---

## When to use this algorithm

Use ternary search when:

- the function/array is unimodal (one valley)
- you only need the minimum index/value

If the array is not unimodal, ternary search is not correct.

---

## Reference implementation

```mbt
///| pub fn find_min_unimodal(arr : ArrayView[Int]) -> Int
```
