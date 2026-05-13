# Verified Kadane's Algorithm

## Overview

Compute the maximum sum over all contiguous, non-empty subarrays of an
integer array: given `arr` of length `n`, return

```
  max  { sum(arr[l..=r])  :  0 <= l <= r < n }
```

This is the textbook **maximum-subarray problem**, and Kadane's
algorithm solves it in a single forward pass. The verified version in
this package carries the precondition `nonempty(arr)` and postcondition
`kadane_post(arr, result)`, with the core mathematical content
expressed as `proof_invariant` clauses on the main loop.

- **Time**: `O(n)`
- **Space**: `O(1)` (two scalars)
- **Signature**: `max_subarray_sum(arr : ArrayView[Int]) -> Int`

## Theory: local versus global

The natural definition is a double-nested maximum,

```
  max_l  max_r>=l  sum(arr[l..=r])
```

which is `O(n^2)` distinct subarrays and `O(n^3)` work if the sums are
computed naively. Kadane's insight is to decompose this into **two
streaming quantities**:

```
  best_ending_here(i)  =  max  { sum(arr[l..=i])  :  0 <= l <= i }
  best_so_far(i)       =  max  { sum(arr[l..=r])  :  0 <= l <= r <= i }
```

Both can be maintained in O(1) per step.

For `best_ending_here`, observe that every subarray ending at `i` is
either the singleton `arr[i..=i]` or an extension of a subarray ending
at `i - 1` by one element. The sums of extensions are exactly
`best_ending_here(i - 1) + arr[i]`, so

```
  best_ending_here(i)  =  max( arr[i] , best_ending_here(i - 1) + arr[i] )
```

In code, this single comparison answers a hidden quantifier over all
left endpoints — the "local" picture.

For `best_so_far`, every subarray of `arr[0..=i]` either lies inside
`arr[0..=i-1]` (already handled by `best_so_far(i - 1)`) or ends at `i`
(captured by `best_ending_here(i)`). So

```
  best_so_far(i)  =  max( best_so_far(i - 1) , best_ending_here(i) )
```

That's the entire algorithm: one extra `max` per element, no
quantifier scans.

## Worked example: `[-2, 1, -3, 4, -1, 2, 1, -5, 4]`

Step through index by index. Initialise at `i = 0` with both scalars
equal to `arr[0] = -2`. Subsequent rows show
`max(arr[i], best_ending_here + arr[i])` and then
`max(best_so_far, new_best_ending_here)`.

| i | arr[i] | best_ending_here | best_so_far | comment                                       |
|---|--------|------------------|-------------|-----------------------------------------------|
| 0 | -2     | -2               | -2          | initial                                       |
| 1 |  1     | max(1, -2+1) = 1 | max(-2, 1)= 1 | starting a new run beats extending          |
| 2 | -3     | max(-3, 1-3) = -2| max(1, -2)= 1 |                                             |
| 3 |  4     | max(4, -2+4) = 4 | max(1, 4) = 4 | restart at 4                                |
| 4 | -1     | max(-1, 4-1) = 3 | max(4, 3) = 4 |                                             |
| 5 |  2     | max(2, 3+2) = 5  | max(4, 5) = 5 |                                             |
| 6 |  1     | max(1, 5+1) = 6  | max(5, 6) = 6 | local high                                  |
| 7 | -5     | max(-5, 6-5) = 1 | max(6, 1) = 6 |                                             |
| 8 |  4     | max(4, 1+4) = 5  | max(6, 5) = 6 | the dip at i = 7 isn't worth crossing       |

The answer is `6`, achieved by the subarray `arr[3..=6] = [4, -1, 2, 1]`.

## Loop invariants (the verified core)

The implementation runs

```moonbit nocheck
for i = 1, best_ending_here = arr[0], best_so_far = arr[0]; i < arr.length(); {
  let candidate = arr[i]
  let extended = best_ending_here + candidate
  let new_ending = if candidate > extended { candidate } else { extended }
  let new_so_far = if new_ending > best_so_far { new_ending } else { best_so_far }
  continue i + 1, new_ending, new_so_far
} nobreak {
  best_so_far
}
```

with the following invariants attached:

- `1 <= i` and `i <= arr.length()` — the index never escapes the
  processed prefix.
- `best_ending_here >= arr[i - 1]` — the local best dominates the
  singleton `arr[i-1..=i-1]`.
- `best_so_far >= best_ending_here` — the global best dominates the
  local best.
- An existential witness: there exists `k` in `[0, i)` with
  `arr[k] <= best_so_far`.

The full mathematical content — "`best_so_far` equals the maximum over
every `(l, r)`" — is laid out in the `proof_reasoning` block. The
structural invariants check the obviously necessary parts (`best_so_far`
is at least some element seen so far, both scalars are well-ordered),
and the reasoning carries the rest.

**Termination**: `arr.length() - i` strictly decreases every iteration,
and the guard `i < arr.length()` bounds it below by zero.

## Tests and examples

### Singletons

```mbt check
///|
test "kadane_singleton_positive" {
  debug_inspect(@verified_kadane.max_subarray_sum([1][:]), content="1")
}
```

### Negative singleton (sign survives)

```mbt check
///|
test "kadane_singleton_negative" {
  // The algorithm is not biased toward zero; with a non-empty
  // precondition, the best single-element subarray wins.
  debug_inspect(@verified_kadane.max_subarray_sum([-1][:]), content="-1")
}
```

### Classic example

```mbt check
///|
test "kadane_classic" {
  // [4, -1, 2, 1] sums to 6.
  let arr : Array[Int] = [-2, 1, -3, 4, -1, 2, 1, -5, 4]
  debug_inspect(@verified_kadane.max_subarray_sum(arr[:]), content="6")
}
```

### All-positive: whole array wins

```mbt check
///|
test "kadane_all_positive" {
  // No reason to skip any element; the answer is the total sum.
  let arr : Array[Int] = [5, 4, -1, 7, 8]
  debug_inspect(@verified_kadane.max_subarray_sum(arr[:]), content="23")
}
```

### All-negative arrays

```mbt check
///|
test "kadane_all_negative" {
  // The maximum-subarray must be non-empty, so the answer is the
  // largest single element, here `-1`.
  let arr : Array[Int] = [-3, -2, -5, -1, -4]
  debug_inspect(@verified_kadane.max_subarray_sum(arr[:]), content="-1")
}
```

## Why this is in `verified/`

The function is a short loop, but the **specification** is a hidden
double quantifier over `l` and `r`. The verified version makes that
specification explicit:

- `proof_require: nonempty(arr)` rules out the empty input where the
  maximum is undefined.
- `proof_ensure: result => kadane_post(arr, result)` ties the returned
  scalar to the array.
- The `proof_invariant` clauses record the two streaming definitions of
  `best_ending_here` and `best_so_far`, and the `proof_reasoning` block
  is a paragraph-level proof of maintenance, initialisation, and
  termination.

This is the canonical example of "the loop body is one line, but the
correctness argument is a quantifier-rich induction" — exactly the kind
of code worth carrying invariants for.

## Common pitfalls

- **Empty input**. This version disallows it (`proof_require:
  nonempty(arr)`). Common alternatives are to return a sentinel like
  `Int::min_value()`, or to wrap the result in `Int?` and return `None`.
  Either is fine, but the precondition keeps the contract simple.
- **All-negative arrays**. The algorithm still works and returns the
  maximum *single* element (because a "best ending here" of `arr[i]`
  is always a candidate). A common bug is to initialise both scalars to
  `0` and then return `best_so_far`, which silently returns `0` on
  all-negative inputs — wrong, because the empty subarray was implicitly
  permitted. We initialise from `arr[0]`, which is the standard fix.
- **Forgetting `best_so_far`**. Returning `best_ending_here` at the end
  is a classic Kadane bug; it answers "best subarray ending at the last
  index", not "best subarray anywhere".
- **Integer overflow**. Sums of `Int` arrays can overflow if the input
  is large. The verified contract here is about correctness modulo
  `Int` arithmetic; in production you may want `Int64` or
  saturating-add.

## Related concepts

```
Maximum subarray sum (this)     contiguous, non-empty
Maximum circular subarray       wraps around the ends of the array
Maximum product subarray        product instead of sum; signs matter
2D Kadane                       maximum-sum submatrix; outer pair of rows + Kadane on columns
Maximum sum with at most k cuts segment DP
Best time to buy / sell stock   "Kadane on differences" reframing
```

## Reference implementation

```
pub fn max_subarray_sum(arr : ArrayView[Int]) -> Int
```

with `proof_require: nonempty(arr)` and `proof_ensure: result =>
kadane_post(arr, result)`.
