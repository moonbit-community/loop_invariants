# Algorithmic Techniques

This module contains cross-cutting competitive-programming techniques, including
two pointers, sliding windows, Mo's algorithm, binary search on answer, ternary
search, meet-in-the-middle, monotonic structures, and interval scheduling.

Packages are organized as one technique per directory. Each package contains a
`README.mbt.md` tutorial with examples that are checked by `moon test`.

Run from the workspace root:

```bash
moon check
moon test
moon info
moon fmt
```

## Release notes

### 0.18.0

- **Breaking — `online_median`:** the public `OnlineMedian::hi` heap now stores
  each element of the larger half as its bitwise complement `x.lnot()`
  (= `-x - 1`) instead of its negation `-x`. Negation overflowed for
  `Int::MIN_VALUE` and corrupted every median query. Code that reads `hi`
  directly must decode with `.lnot()` instead of negation (after adding `1`
  and `3`, `hi.peek()` is now `Some(-4)` rather than `Some(-3)`). The
  `lower_median`, `upper_median` and `median` methods are unaffected.
- Overflow fixes (no API change): `challenge_binary_search_answer`
  (`can_ship`, `min_capacity`), `sliding_window`
  (`longest_subarray_with_sum_le`, `min_subarray_with_sum_ge`),
  `challenge_two_pointers`, `challenge_meet_in_middle`.
