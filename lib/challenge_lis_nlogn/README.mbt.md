# Challenge: LIS Length (O(n log n))

The **Longest Increasing Subsequence (LIS)** length asks:

> Given a sequence of numbers, what is the maximum length of a strictly
> increasing subsequence?

A subsequence keeps order but can skip elements.

Example:

- Sequence: `[3, 1, 2, 1, 8, 5, 6]`
- One LIS: `[1, 2, 5, 6]` (length 4)

This package computes the **length only**, using a fast `O(n log n)` method.

---

## The idea in plain words

We build an array called `tails`.

- `tails[k]` = the **smallest possible tail value** of any increasing
  subsequence of length `k + 1` seen so far.

Why smallest? Smaller tails are better because they can be extended more easily
by future numbers.

When we read a number `x`:

1) Find the first position in `tails` where the value is **>= x**.
2) Replace that value with `x`.
3) If no such position exists, append `x`.

The length of `tails` is the LIS length.

This is the same idea as **patience sorting** (piles), but stored as an array.

---

## A slow picture vs. a fast picture

Imagine we make piles (top card is the tail):

- If `x` is larger than all pile tops, start a new pile.
- Otherwise, put `x` on the leftmost pile with top >= `x`.

The number of piles equals LIS length. The `tails` array stores those pile tops.

---

## Worked example (step by step)

Sequence: `[3, 1, 2, 1, 8, 5, 6]`

We show `tails` after each number:

```
start: tails = []

x = 3: append        -> [3]
x = 1: replace pos 0 -> [1]
x = 2: append        -> [1, 2]
x = 1: replace pos 0 -> [1, 2]
x = 8: append        -> [1, 2, 8]
x = 5: replace pos 2 -> [1, 2, 5]
x = 6: append        -> [1, 2, 5, 6]
```

Final length = 4.

**Important:** `tails` is not the actual subsequence. For example, the value
`8` was replaced, so `[1, 2, 5, 6]` is not literally the numbers in `tails` at
all times. The array only stores best possible tails for each length.

---

## Another example (strictly decreasing)

Sequence: `[9, 7, 5, 3]`

```
start: tails = []

x = 9 -> [9]
x = 7 -> [7]
x = 5 -> [5]
x = 3 -> [3]
```

LIS length = 1. There is no increasing subsequence longer than one element.

---

## Why binary search works

The `tails` array is always **sorted**:

- `tails[0] < tails[1] < tails[2] < ...`

So we can binary search for the first value `>= x` (lower bound).
That position is exactly the length where `x` can become a better tail.

Pseudocode:

```mbt nocheck
for x in nums {
  pos = lower_bound(tails, x) // first index with tails[pos] >= x
  if pos == tails.length() {
    tails.push(x)
  } else {
    tails[pos] = x
  }
}
```

---

## Strict vs. non-decreasing

This implementation uses `>=` in the search, which makes the LIS **strictly**
increasing. Duplicates do not increase length.

Example:

```
nums = [2, 2, 2]
LIS length (strict) = 1
```

If you want **non-decreasing** subsequences, you should search for the first
value `> x` instead. That tiny change lets equal values extend the length.

---

## Reference implementation

```mbt nocheck
///| pub fn lis_length(nums : ArrayView[Int]) -> Int { ... }
```

The full code lives in `challenge_lis_nlogn.mbt`.

---

## Tests and examples

### Basic example

```mbt check
///|
test "lis example" {
  let nums : Array[Int] = [3, 1, 2, 1, 8, 5, 6]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="4")
}
```

### Classic LIS example

```mbt check
///|
test "lis classic" {
  let nums : Array[Int] = [10, 9, 2, 5, 3, 7, 101, 18]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="4")
}
```

### Already increasing

```mbt check
///|
test "lis increasing" {
  let nums : Array[Int] = [1, 2, 3, 4, 5]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="5")
}
```

### Strictly decreasing

```mbt check
///|
test "lis decreasing" {
  let nums : Array[Int] = [9, 7, 5, 3]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="1")
}
```

### Many duplicates

```mbt check
///|
test "lis duplicates" {
  let nums : Array[Int] = [2, 2, 2, 2]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="1")
}
```

### Mixed signs

```mbt check
///|
test "lis negatives" {
  let nums : Array[Int] = [-3, -1, -2, 0, 2, -1, 3]
  let len = @challenge_lis_nlogn.lis_length(nums[:])
  inspect(len, content="5")
}
```

---

## Complexity

- Time: `O(n log n)` (binary search for each element)
- Space: `O(n)` for the `tails` array

---

## Takeaways

- `tails` stores best possible ending values, not the actual subsequence.
- Lower bound (`>= x`) gives strictly increasing LIS.
- The number of piles (or `tails.length()`) is the answer.
