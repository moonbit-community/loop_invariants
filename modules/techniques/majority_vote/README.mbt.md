# Boyer-Moore Majority Vote

## Overview

The **Boyer-Moore majority-vote** algorithm (1981) finds the element
that appears strictly more than `n/2` times in a sequence using only
`O(1)` extra space and a single linear pass. A second `O(n)` pass
verifies the candidate is actually the majority.

| Operation | Time | Space |
|---|---|---|
| `majority(arr)` | `O(n)` | `O(1)` |
| `find_candidate(arr)` | `O(n)` (no verification) | `O(1)` |

The cleverness: cancellations between distinct values can wipe out at
most `n − count(majority)` non-majority elements *and* the same number
of majority elements; if the majority strictly exceeds `n/2`, at least
one copy must survive.

---

## Algorithm

```
cand, cnt = arr[0], 0
for x in arr:
    if cnt == 0:    cand, cnt = x, 1
    elif x == cand: cnt += 1
    else:           cnt -= 1
# `cand` is the only possible majority element.
```

A subsequent pass counts `cand` to confirm it appears `> n/2` times.

---

## The invariant

> At every step, if we 'pair off' the elements processed so far into
> cancellations between distinct values plus `cnt` extra copies of
> `cand`, the multiset of processed inputs is exactly reconstructed.

Hence a strict majority element cannot be fully cancelled by all others
combined — it must be what `cand` holds at the end.

---

## API

```
pub fn[T : Eq] majority(arr : Array[T]) -> T?
pub fn[T : Eq] find_candidate(arr : Array[T]) -> T
```

- `majority` returns `Some(x)` only when `x` appears strictly more than
  `n/2` times. Otherwise `None`.
- `find_candidate` returns the Boyer-Moore candidate **without
  verifying**; useful when the caller already knows a majority exists
  and wants to skip the second pass.

---

## Tests and examples

```mbt check
///|
test "majority basic" {
  // 2 appears 3 of 5 times -> majority.
  debug_inspect(@majority_vote.majority([2, 1, 2, 3, 2]), content="Some(2)")
}
```

```mbt check
///|
test "majority absent" {
  // No element exceeds n/2 -> None.
  debug_inspect(@majority_vote.majority([1, 2, 3]), content="None")
}
```

```mbt check
///|
test "majority exactly half is not majority" {
  // 4 of 8 is not strictly more than n/2.
  debug_inspect(
    @majority_vote.majority([1, 1, 1, 1, 2, 2, 2, 2]),
    content="None",
  )
}
```

---

## Use cases

- **Streaming median / mode approximations** when a strict majority is
  guaranteed.
- **Distributed consensus** where each node sends a vote and we want
  the dominant value with minimal state.
- **Foundation for Misra-Gries / `k`-majority** (find every element
  exceeding `n / (k+1)`).

---

## Pitfalls

- **Strict vs. weak majority.** "Majority" here means **more than half**.
  If you want plurality (the most frequent), use a hash-count or
  Misra-Gries with `k = 1`.
- **Garbage from `find_candidate` without verification.** If no strict
  majority exists, the candidate is some surviving element — not
  necessarily the second-most-frequent.
- **Equality only.** The algorithm needs `Eq` but no total order;
  hashing is **not** required.

---

## Related concepts

```
Misra-Gries heavy hitters    find every element appearing > n/(k+1) times
Count-Min sketch             approximate frequency in O(log) space
Reservoir sampling           pick a uniformly-random element online
Mode / plurality             different problem; cannot be solved in O(1) space
```
