# Challenge: Persistent Order Statistics Tree

This structure supports **k-th order queries** (select by rank) on a multiset
of integers. It is **persistent**: every insert returns a new version while old
versions remain valid.

It is implemented as a persistent segment tree counting occurrences over a
fixed integer domain `[lo, hi)`.

This package provides:

- `make(lo, hi)` to create an empty multiset
- `add(os, value)` to insert a value (persistent)
- `kth(os, k)` to get the k-th smallest value (0-based)
- `size(os)` to count elements

---

## Core idea: counts in a segment tree

We maintain a segment tree where each leaf represents one integer value, and
each node stores the **count of elements** in its range.

Example for domain `[0, 8)`:

```
range [0,8)
  /       \
[0,4)    [4,8)
  / \      / \
[0,2)[2,4)[4,6)[6,8)
```

If the multiset contains `{1, 1, 3, 6}`, the counts accumulate upward.

---

## k-th order query

To find the k-th smallest value:

1) Look at the count in the left child.
2) If `k < left_count`, go left.
3) Otherwise, go right with `k = k - left_count`.
4) When the range length is 1, return that value.

This is `O(log (hi - lo))`.

---

## Persistence

When inserting a value, we only copy nodes along the path to the leaf. All
other nodes are shared.

```
Old version:               New version:

     A                        A'
    / \                      / \
   B   C     insert x       B'  C
  / \                      / \
 D   E                    D   E
```

---

## Important constraints

- The structure only stores values within `[lo, hi)`.
- Values outside the domain are ignored.
- This is a **multiset**: inserting the same value multiple times increases
  its count.

---

## Reference implementation

```mbt
///| pub fn make(lo : Int, hi : Int) -> OrderStat

///| pub fn add(os : OrderStat, value : Int) -> OrderStat

///| pub fn kth(os : OrderStat, k : Int) -> Int?

///| pub fn size(os : OrderStat) -> Int
```

---

## Tests and examples

### Basic usage

```mbt check
///|
test "order statistic basic" {
  let os0 = @challenge_persistent_order_statistic.make(0, 10)
  let os1 = @challenge_persistent_order_statistic.add(os0, 5)
  let os2 = @challenge_persistent_order_statistic.add(os1, 2)
  let os3 = @challenge_persistent_order_statistic.add(os2, 7)
  inspect(@challenge_persistent_order_statistic.kth(os3, 0), content="Some(2)")
  inspect(@challenge_persistent_order_statistic.kth(os3, 1), content="Some(5)")
  inspect(@challenge_persistent_order_statistic.kth(os3, 2), content="Some(7)")
}
```

### Duplicates (multiset behavior)

```mbt check
///|
test "order statistic duplicates" {
  let os0 = @challenge_persistent_order_statistic.make(0, 10)
  let os1 = @challenge_persistent_order_statistic.add(os0, 4)
  let os2 = @challenge_persistent_order_statistic.add(os1, 4)
  let os3 = @challenge_persistent_order_statistic.add(os2, 1)
  inspect(@challenge_persistent_order_statistic.kth(os3, 0), content="Some(1)")
  inspect(@challenge_persistent_order_statistic.kth(os3, 1), content="Some(4)")
  inspect(@challenge_persistent_order_statistic.kth(os3, 2), content="Some(4)")
}
```

### Out-of-range values are ignored

```mbt check
///|
test "order statistic bounds" {
  let os0 = @challenge_persistent_order_statistic.make(0, 5)
  let os1 = @challenge_persistent_order_statistic.add(os0, 2)
  let os2 = @challenge_persistent_order_statistic.add(os1, 9)
  inspect(@challenge_persistent_order_statistic.size(os2), content="1")
  inspect(@challenge_persistent_order_statistic.kth(os2, 0), content="Some(2)")
}
```

---

## Complexity

Let `D = hi - lo` be the domain size.

- Insert: `O(log D)` time and memory
- kth query: `O(log D)` time

---

## Takeaways

- A persistent segment tree turns order-statistic queries into path walks.
- Duplicates are supported via counts.
- The domain is fixed and must be chosen ahead of time.
