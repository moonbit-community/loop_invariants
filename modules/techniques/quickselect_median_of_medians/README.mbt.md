# Quickselect with Median-of-Medians

## Overview

Find the `k`-th smallest element of an array in **guaranteed worst-case
O(n)** time. Naive Quickselect with a random pivot is O(n) expected but
O(n²) worst case; the median-of-medians pivot construction
(Blum-Floyd-Pratt-Rivest-Tarjan, 1973) gives a deterministic linear
bound by constructing a pivot guaranteed to sit between the 30th and
70th percentile of the input.

- **Time**: O(n) worst case (no probability)
- **Space**: O(n) total (geometric series of recursive arrays)
- **Signatures**:
  - `select_kth(arr, k) -> Int?`
  - `median(arr) -> Int?`

This algorithm is famous for being more theoretically beautiful than
practically fast — the 5-element grouping gives a small constant
factor improvement over naive quickselect only on adversarial inputs.
But the proof is one of the loveliest in algorithm design.

---

## The recursion

```
select(arr, k):
  if |arr| <= 5:
    return sort(arr)[k]                  -- base case
  groups   = chunk arr into groups of 5
  medians  = [median of each group]
  pivot    = select(medians, |medians| / 2)
  L, M, R  = partition arr around pivot (three-way)
  if k < |L|:                  return select(L, k)
  if k < |L| + |M|:            return pivot
  else:                        return select(R, k - |L| - |M|)
```

The base case sorts 5 elements (O(1)). The recursive step does one
recursive call to find the pivot (size ≈ n/5), partitions in O(n), and
recurses into the side containing rank k.

---

## The 30–70 guarantee

Let `p` be the median of medians; let `m = |medians| = ⌈n / 5⌉`.

- `p` is the median of `m` values, so at least `m / 2 ≈ n / 10` medians
  are ≥ `p`.
- Each such median came from a group of 5 in which at least 3 of the 5
  elements are ≥ the group's median.
- So **at least `3 · n / 10` elements of `arr` are ≥ `p`**.
- Symmetrically at least `3 · n / 10` elements are ≤ `p`.

Therefore `p` sits between rank `0.3 n` and rank `0.7 n`. After the
three-way partition, the side containing rank `k` has size at most
`0.7 n`.

## The recurrence

```
T(n)  ≤  T(n / 5)         -- recursion to find the median of medians
     +   T(7 n / 10)       -- recursion into the larger of L / R
     +   O(n)              -- partitioning work
```

Because `1/5 + 7/10 = 9/10 < 1`, induction gives `T(n) ≤ C · n` for
some constant `C`. **Linear worst case.**

---

## Reference implementation

```
pub fn select_kth(arr : ArrayView[Int], k : Int) -> Int?
pub fn median(arr : ArrayView[Int]) -> Int?
```

---

## Tests and examples

### Rank 0 is the minimum, rank n-1 the maximum

```mbt check
///|
test "select extremes" {
  let arr = [9, 7, 5, 3, 1][:]
  debug_inspect(
    @quickselect_median_of_medians.select_kth(arr, 0),
    content="Some(1)",
  )
  debug_inspect(
    @quickselect_median_of_medians.select_kth(arr, 4),
    content="Some(9)",
  )
}
```

### Median for an odd-length array

```mbt check
///|
test "select median odd" {
  let arr = [3, 1, 4, 1, 5, 9, 2][:]
  debug_inspect(@quickselect_median_of_medians.median(arr), content="Some(3)")
}
```

### Out-of-range k returns None

```mbt check
///|
test "select bounds" {
  let arr = [42][:]
  debug_inspect(
    @quickselect_median_of_medians.select_kth(arr, 5),
    content="None",
  )
  debug_inspect(
    @quickselect_median_of_medians.select_kth(arr, -1),
    content="None",
  )
}
```

### Agreement with sort

```mbt check
///|
test "select agrees with sort" {
  let arr = [12, 3, 7, 19, 26, 2, 9, 15, 6, 1][:]
  let sorted = arr.to_owned()
  sorted.sort()
  debug_inspect(
    @quickselect_median_of_medians.select_kth(arr, 5),
    content="Some(9)",
  )
  debug_inspect(sorted[5], content="9")
}
```

---

## Complexity

| Operation       | Time         | Space        |
|-----------------|--------------|--------------|
| `select_kth`    | O(n)         | O(n) total   |
| `median`        | O(n)         | O(n) total   |

Space is O(n) because at each recursion level the temporary arrays
shrink geometrically. The dominant factor is the base level.

---

## When to reach for it

- **Adversarial inputs that defeat random-pivot Quickselect**. For
  example, sorting an already-sorted array degenerates random pivot
  to O(n²); median-of-medians stays O(n).
- **Hard real-time deadlines**. The deterministic bound is essential
  when you must commit to a time budget that does not depend on
  randomness or input distribution.
- **As the pivot rule for a guaranteed-O(n log n) sort** (Introsort
  uses a similar idea as a fallback when randomised quicksort hits
  worst-case depth).

In practice, on benign workloads, random-pivot Quickselect is faster
because its constant factor is much smaller. Median-of-medians is the
algorithm of last resort: when correctness in the worst case matters
more than average-case speed.

---

## Common pitfalls

- **Group size 5 is special**. Smaller groups (3, 4) don't give the
  30–70 split needed for the recurrence to close. Group size 7 also
  works but is harder to motivate.
- **Three-way partition is important**. With a two-way partition,
  many equal elements on the boundary would land all in one side,
  defeating the size guarantee.
- **This is not in-place**. The package returns the k-th value, not
  a permuted array. An in-place version requires careful pointer
  manipulation that obscures the proof; the educational version
  here uses three temporary arrays per level.
- **Generic comparable type**: this package operates on `Int`. To
  generalise, replace `<` / `==` / `>` with a `Compare`-trait
  comparator and the constants in the partition step with trait
  applications.

---

## Related concepts

```
Quickselect           random-pivot variant; O(n) expected, O(n^2) worst
Introselect           hybrid: random Quickselect with MoM fallback
P-square              streaming approximate quantile
Heap selection        O(n + k log n); good for small k
Randomised selection  Floyd-Rivest's sampling pivot; ~O(n) with good constants
```
