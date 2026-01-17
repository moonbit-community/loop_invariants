# Challenge: Meet-in-the-Middle Subset Sum

The classic subset sum problem asks you to pick **some elements** of an array so
that their sum is as large as possible but **does not exceed a target**.

This package computes:

```
max subset sum <= target
```

It uses **meet-in-the-middle**, which is the standard way to handle `n` around
30-40 when `2^n` is too big for brute force.

---

## Problem restatement (plain words)

Given numbers `nums[0..n)`, choose any subset (possibly empty). Let its sum be
`S`. We want the largest `S` such that:

```
S <= target
```

We only return the value `S` (not which elements were chosen).

**Assumption used by the implementation:** `target >= 0`, so the empty subset
(sum = 0) is always a valid candidate.

---

## Why brute force is too big

If you check every subset, you do `2^n` work.

- `n = 40` -> `2^40` about **1 trillion** subsets

Meet-in-the-middle cuts it down to two halves:

```
2^(n/2) + 2^(n/2)
```

For `n = 40`, that's about **2 million** subsets, which is feasible.

---

## Key idea (meet-in-the-middle)

Split the array into two halves:

```
nums = [L0, L1, L2, | R0, R1, R2]
         left half    right half
```

1) Enumerate **all subset sums** of the left half (size `2^(n/2)`).
2) Enumerate **all subset sums** of the right half.
3) Sort the right sums.
4) For each left sum `L`, find the largest right sum `R` such that
   `L + R <= target`.

This uses binary search (`upper_bound`) on the sorted right sums.

---

## Visual intuition

Think of two sets of piles:

```
left sums  ---> (try each)
                 |
                 | binary search in sorted right sums
                 v
right sums ---> [sorted list]
```

Each left sum decides how much "budget" remains for the right half.

---

## Worked example (step by step)

```
nums   = [3, 34, 4, 12, 5, 2]
target = 9
```

Split:

```
left  = [3, 34, 4]
right = [12, 5, 2]
```

All left sums (8 of them):

```
mask -> sum
000  -> 0
001  -> 3
010  -> 34
011  -> 37
100  -> 4
101  -> 7
110  -> 38
111  -> 41
```

All right sums (8 of them), sorted:

```
[0, 2, 5, 7, 12, 14, 17, 19]
```

Now try each left sum `L`, find best right sum `R` with `R <= target - L`:

```
L = 0  -> remaining 9  -> best R = 7  -> total 7
L = 3  -> remaining 6  -> best R = 5  -> total 8
L = 4  -> remaining 5  -> best R = 5  -> total 9   (best so far)
L = 7  -> remaining 2  -> best R = 2  -> total 9   (tie)
L = 34 -> remaining -25 -> no valid R
...
```

Final answer = **9**.

---

## Upper bound (binary search)

We use `upper_bound(sorted, x)`:

- returns the first index with value **> x**
- so `idx - 1` is the last value **<= x**

This is exactly what we need for `remaining = target - L`.

---

## Reference implementation

```mbt
///| pub fn best_subset_sum_leq(nums : ArrayView[Int], target : Int) -> Int { ... }
```

The code uses two helpers:

- `subset_sums` to enumerate sums using bitmasks
- `upper_bound` to binary search the right sums

---

## Tests and examples

### Example from the walkthrough

```mbt check
///|
test "meet in middle example 9" {
  let nums : Array[Int] = [3, 34, 4, 12, 5, 2]
  let best = @challenge_meet_in_middle.best_subset_sum_leq(nums[:], 9)
  inspect(best, content="9")
}
```

### Same input, bigger target

```mbt check
///|
test "meet in middle example 10" {
  let nums : Array[Int] = [3, 34, 4, 12, 5, 2]
  let best = @challenge_meet_in_middle.best_subset_sum_leq(nums[:], 10)
  inspect(best, content="10")
}
```

### Small set with exact hit

```mbt check
///|
test "meet in middle exact hit" {
  let nums : Array[Int] = [1, 2, 3, 4]
  let best = @challenge_meet_in_middle.best_subset_sum_leq(nums[:], 6)
  inspect(best, content="6")
}
```

### Target smaller than any element (empty subset wins)

```mbt check
///|
test "meet in middle empty subset" {
  let nums : Array[Int] = [5, 8, 13]
  let best = @challenge_meet_in_middle.best_subset_sum_leq(nums[:], 4)
  inspect(best, content="0")
}
```

### Larger mix

```mbt check
///|
test "meet in middle larger" {
  let nums : Array[Int] = [8, 6, 7, 5, 3, 10, 9]
  let best = @challenge_meet_in_middle.best_subset_sum_leq(nums[:], 20)
  inspect(best, content="20")
}
```

---

## Complexity

Let `n = nums.length()` and `m = n/2`:

- Subset sums: `O(2^m + 2^(n-m))`
- Sorting right sums: `O(2^(n-m) log 2^(n-m))`
- Searching for each left sum: `O(2^m log 2^(n-m))`

Overall: `O(2^(n/2) log 2^(n/2))` time and `O(2^(n/2))` memory.

---

## Takeaways

- Split the problem in half to replace `2^n` with `2^(n/2)`.
- Precompute all sums of each half.
- Sort one side and binary search for the best partner.
- Perfect for subset sum with `n` around 30-40.
