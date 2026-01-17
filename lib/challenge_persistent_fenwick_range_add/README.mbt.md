# Challenge: Persistent Fenwick (Range Add / Range Sum)

This structure supports **range add** and **range sum** on a static array, while
being **persistent**: every update returns a new version and old versions remain
valid.

It uses two persistent Fenwick trees (BITs) under the hood.

This package provides:

- `make(n)` to create a structure of length `n`
- `range_add(rf, l, r, delta)` to add `delta` to all indices in `[l, r]`
- `range_sum(rf, l, r)` to query sum on `[l, r]`
- `prefix_sum_range(rf, idx)` to query prefix sum `[0..idx]`
- `apply_updates(rf, updates)` to apply many range adds persistently
- `length(rf)` to read the size

---

## The classic trick: two BITs

A Fenwick tree normally supports:

- point add
- prefix sum

To support **range add** and **range sum**, we use two BITs (`B1`, `B2`) with:

```
prefix_sum(x) = sum_{i=1..x} a[i] = B1.sum(x) * x - B2.sum(x)
```

To add `delta` on range `[l, r]` (1-based indexing):

```
B1.add(l, delta)
B1.add(r+1, -delta)
B2.add(l, delta*(l-1))
B2.add(r+1, -delta*r)
```

This makes range sum queries work with two prefix sums.

---

## Persistence (how it is done here)

Each BIT is stored in a persistent array (path-copying segment tree). Every
BIT update returns a new Fenwick, and we combine the two updated trees into a
new `RangeFenwick`.

Old versions share unchanged nodes, so the memory overhead per update is
`O((log n)^2)`.

---

## Indexing details

The public API uses **0-based** indices (`[l, r]` inclusive). Internally we
convert to 1-based by adding 1:

```
idx0 -> idx1 = idx0 + 1
```

This matches Fenwick tree conventions.

---

## Example walk-through

Start with length 5:

```
arr = [0, 0, 0, 0, 0]
```

Apply range add:

```
add +3 to [1, 3]
```

Now:

```
arr = [0, 3, 3, 3, 0]
range_sum(1, 3) = 9
range_sum(0, 4) = 9
```

Add another update:

```
add +2 to [2, 4]
```

Now:

```
arr = [0, 3, 5, 5, 2]
range_sum(2, 4) = 12
```

---

## Reference implementation

```mbt
///| pub fn make(n : Int) -> RangeFenwick

///| pub fn range_add(rf : RangeFenwick, l : Int, r : Int, delta : Int) -> RangeFenwick

///| pub fn range_sum(rf : RangeFenwick, l : Int, r : Int) -> Int

///| pub fn prefix_sum_range(rf : RangeFenwick, idx : Int) -> Int

///| pub fn apply_updates(rf : RangeFenwick, updates : ArrayView[(Int, Int, Int)]) -> RangeFenwick

///| pub fn length(rf : RangeFenwick) -> Int
```

---

## Tests and examples

### Basic range add and sum

```mbt check
///|
test "range add basic" {
  let rf0 = @challenge_persistent_fenwick_range_add.make(5)
  let rf1 = @challenge_persistent_fenwick_range_add.range_add(rf0, 1, 3, 3)
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf1, 1, 3),
    content="9",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf1, 0, 4),
    content="9",
  )
}
```

### Two updates

```mbt check
///|
test "range add two updates" {
  let rf0 = @challenge_persistent_fenwick_range_add.make(5)
  let rf1 = @challenge_persistent_fenwick_range_add.range_add(rf0, 1, 3, 3)
  let rf2 = @challenge_persistent_fenwick_range_add.range_add(rf1, 2, 4, 2)
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf2, 2, 4),
    content="12",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf2, 0, 1),
    content="3",
  )
}
```

### Persistence across versions

```mbt check
///|
test "range add persistence" {
  let rf0 = @challenge_persistent_fenwick_range_add.make(4)
  let rf1 = @challenge_persistent_fenwick_range_add.range_add(rf0, 0, 1, 5)
  let rf2 = @challenge_persistent_fenwick_range_add.range_add(rf1, 2, 3, 7)
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf0, 0, 3),
    content="0",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf1, 0, 3),
    content="10",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf2, 0, 3),
    content="24",
  )
}
```

### Apply updates from an array

```mbt check
///|
test "range add apply updates" {
  let rf0 = @challenge_persistent_fenwick_range_add.make(5)
  let updates : Array[(Int, Int, Int)] = [(0, 2, 1), (1, 4, 2)]
  let rf = @challenge_persistent_fenwick_range_add.apply_updates(
    rf0,
    updates[:],
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf, 0, 0),
    content="1",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf, 1, 2),
    content="6",
  )
  inspect(
    @challenge_persistent_fenwick_range_add.range_sum(rf, 3, 4),
    content="4",
  )
}
```

---

## Complexity

Let `n = length`:

- Each point update in a persistent BIT costs `O(log n)` to locate and `O(log n)`
  to copy nodes, so `O((log n)^2)`
- Range add does 4 point updates: `O((log n)^2)`
- Range sum does two prefix sums: `O((log n)^2)`

Persistence adds extra log factors because the BIT array itself is persistent.

---

## Takeaways

- Two BITs turn range add into prefix sums.
- The persistent array makes every update produce a new version.
- Old versions remain valid and share unchanged structure.
