# Challenge: Persistent Fenwick Tree (BIT)

A **Fenwick tree** (Binary Indexed Tree) supports fast prefix sums with point
updates. This version is **persistent**, so every update returns a new tree
while older versions remain valid.

This package provides:

- `make(n)` to create a tree of length `n`
- `add(fw, idx, delta)` to update a single index (persistent)
- `prefix_sum(fw, idx)` to query sum of `[0..idx]`
- `range_sum(fw, l, r)` to query sum of `[l..r]`
- `length(fw)` to get the size

---

## Fenwick tree recap (1-based)

Fenwick trees store partial sums in a 1-based array `bit[1..n]`.
The lowbit function:

```
lowbit(i) = i & -i
```

Update (add delta at index `i`):

```
while i <= n:
  bit[i] += delta
  i += lowbit(i)
```

Prefix sum (sum of 1..i):

```
res = 0
while i > 0:
  res += bit[i]
  i -= lowbit(i)
```

This gives `O(log n)` time for both operations.

---

## Persistence: how it is implemented here

We cannot mutate the Fenwick array in place. Instead, we store the Fenwick
array inside a **persistent path-copying segment tree**.

So each update changes only the Fenwick array positions that are touched by the
loop, and each of those positions is updated via a persistent array set.

Old versions remain intact and share unchanged nodes.

---

## Example walk-through

Suppose we want to track the array:

```
arr = [1, 2, 3, 4]
```

We will build a Fenwick tree with `n = 4`.
The internal array is size `n + 1 = 5`, because index 0 is unused.

### Add values

```
add idx 0 by +1
add idx 1 by +2
add idx 2 by +3
add idx 3 by +4
```

Now:

```
prefix_sum(0) = 1
prefix_sum(1) = 3
prefix_sum(2) = 6
prefix_sum(3) = 10
```

Range sum example:

```
range_sum(1, 2) = prefix_sum(2) - prefix_sum(0) = 6 - 1 = 5
```

---

## Visual intuition (lowbit jumps)

For `n = 8`, the update path for index 3 (0-based) uses `i = 4` in 1-based
indexing:

```
i = 4 -> 8 -> 16 (stop)
```

The prefix sum path from `i = 6` is:

```
6 -> 4 -> 0 (stop)
```

These paths cover exactly the ranges needed for correct sums.

---

## Reference implementation

```mbt
///| pub fn make(n : Int) -> Fenwick

///| pub fn add(fw : Fenwick, idx : Int, delta : Int) -> Fenwick

///| pub fn prefix_sum(fw : Fenwick, idx : Int) -> Int

///| pub fn range_sum(fw : Fenwick, l : Int, r : Int) -> Int

///| pub fn length(fw : Fenwick) -> Int
```

---

## Tests and examples

### Basic updates and queries

```mbt check
///|
test "persistent fenwick basic" {
  let fw0 = @challenge_persistent_fenwick.make(4)
  let fw1 = @challenge_persistent_fenwick.add(fw0, 0, 1)
  let fw2 = @challenge_persistent_fenwick.add(fw1, 1, 2)
  let fw3 = @challenge_persistent_fenwick.add(fw2, 2, 3)
  let fw4 = @challenge_persistent_fenwick.add(fw3, 3, 4)
  inspect(@challenge_persistent_fenwick.prefix_sum(fw4, 0), content="1")
  inspect(@challenge_persistent_fenwick.prefix_sum(fw4, 3), content="10")
  inspect(@challenge_persistent_fenwick.range_sum(fw4, 1, 2), content="5")
}
```

### Persistence across versions

```mbt check
///|
test "persistent fenwick versions" {
  let fw0 = @challenge_persistent_fenwick.make(3)
  let fw1 = @challenge_persistent_fenwick.add(fw0, 0, 5)
  let fw2 = @challenge_persistent_fenwick.add(fw1, 2, 7)
  inspect(@challenge_persistent_fenwick.prefix_sum(fw0, 2), content="0")
  inspect(@challenge_persistent_fenwick.prefix_sum(fw1, 2), content="5")
  inspect(@challenge_persistent_fenwick.prefix_sum(fw2, 2), content="12")
}
```

### Out-of-range update is ignored

```mbt check
///|
test "persistent fenwick bounds" {
  let fw0 = @challenge_persistent_fenwick.make(2)
  let fw1 = @challenge_persistent_fenwick.add(fw0, 5, 10)
  inspect(@challenge_persistent_fenwick.prefix_sum(fw1, 1), content="0")
}
```

---

## Complexity

Let `n = length`:

- `add`: `O(log n)` updates to Fenwick array, each update is `O(log n)` in the
  persistent array, so total `O((log n)^2)`
- `prefix_sum`: `O(log n)` Fenwick steps, each `array_get` is `O(log n)`, so
  total `O((log n)^2)`
- `range_sum`: two prefix sums

Persistence costs extra log factors because the Fenwick array itself is
persistent.

---

## Takeaways

- Fenwick trees use lowbit jumps to do prefix sums and updates in `O(log n)`.
- Persistence is achieved by storing the Fenwick array in a path-copying tree.
- Old versions stay valid and share structure with new versions.
